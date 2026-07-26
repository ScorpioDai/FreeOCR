#!/usr/bin/env python3
"""Local PP-OCRv6 service for the FreeOCR macOS app."""

from __future__ import annotations

import argparse
import asyncio
import json
import logging
import os
import shutil
import signal
import subprocess
import threading
import time
import uuid
from concurrent.futures import ThreadPoolExecutor
from contextlib import asynccontextmanager
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Annotated, Callable, Literal

import pypdfium2 as pdfium
import uvicorn
from fastapi import Depends, FastAPI, File, Form, Header, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, PlainTextResponse
from PIL import Image


LOGGER = logging.getLogger("freeocr")
ResponseFormat = Literal["json", "markdown", "text"]
ProgressCallback = Callable[[int, int, str, int, int], None]


@dataclass(slots=True)
class Point:
    x: float
    y: float


@dataclass(slots=True)
class Block:
    id: str
    page: int
    order: int
    text: str
    kind: str
    polygon: list[Point]
    confidence: float | None = None


@dataclass(slots=True)
class PageResult:
    index: int
    width: int
    height: int
    markdown: str
    text: str
    preview_path: str
    blocks: list[Block]


class ModelManager:
    """Own the bundled PP-OCRv6 detection and recognition pipeline."""

    MODEL_NAME = "PaddlePaddle/PP-OCRv6_medium_det + PP-OCRv6_medium_rec"

    def __init__(self, detection_model_dir: Path, recognition_model_dir: Path) -> None:
        self.detection_model_dir = detection_model_dir
        self.recognition_model_dir = recognition_model_dir
        self.ocr = None
        self.state = "starting"
        self.error: str | None = None
        self.loaded_at: float | None = None
        self._inference_lock = threading.Lock()

    def health(self) -> dict:
        return {
            "status": self.state,
            "model_loaded": self.state == "ready",
            "model": self.MODEL_NAME,
            "backend": "ONNX Runtime (CPU)",
            "error": self.error,
        }

    def load(self) -> None:
        self.state = "loading"
        self.error = None
        started = time.perf_counter()
        try:
            from paddleocr import PaddleOCR

            self.ocr = PaddleOCR(
                text_detection_model_name="PP-OCRv6_medium_det",
                text_detection_model_dir=str(self.detection_model_dir),
                text_recognition_model_name="PP-OCRv6_medium_rec",
                text_recognition_model_dir=str(self.recognition_model_dir),
                engine="onnxruntime",
                device="cpu",
                use_doc_orientation_classify=False,
                use_doc_unwarping=False,
                use_textline_orientation=False,
                text_recognition_batch_size=8,
                return_word_box=False,
            )
            self.loaded_at = time.time()
            self.state = "ready"
            LOGGER.info("%s ready in %.2f seconds", self.MODEL_NAME, time.perf_counter() - started)
        except Exception as exc:  # noqa: BLE001 - surfaced through /health
            self.error = str(exc)
            self.ocr = None
            self.state = "failed"
            LOGGER.exception("Model load failed")

    def infer(self, image_path: Path) -> list:
        if self.state != "ready" or self.ocr is None:
            raise RuntimeError(self.error or "Model is not ready")
        with self._inference_lock:
            return list(self.ocr.predict(str(image_path)))


class JobStore:
    def __init__(self) -> None:
        self._jobs: dict[str, dict] = {}
        self._lock = threading.Lock()

    def create(self) -> dict:
        job_id = str(uuid.uuid4())
        with self._lock:
            self._jobs[job_id] = {
                "id": job_id,
                "status": "queued",
                "current": 0,
                "total": 0,
                "page": 0,
                "page_count": 0,
                "stage": "queued",
                "elapsed_seconds": 0.0,
                "estimated_remaining_seconds": None,
                "result": None,
                "error": None,
                "started_at": None,
                "projected_total_seconds": None,
            }
            return self._public_snapshot(self._jobs[job_id])

    def start(self, job_id: str) -> None:
        with self._lock:
            job = self._jobs[job_id]
            job.update(status="running", stage="preparing", started_at=time.monotonic())

    def update(
        self,
        job_id: str,
        current: int,
        total: int,
        stage: str,
        page: int,
        page_count: int,
    ) -> None:
        with self._lock:
            job = self._jobs[job_id]
            elapsed = self._elapsed(job)
            remaining = None
            projected_total = job.get("projected_total_seconds")
            if current > job["current"] and current > 0:
                projected_total = (elapsed / current) * total
            if projected_total is not None and total > current:
                remaining = max(0.0, projected_total - elapsed)
            job.update(
                current=current,
                total=total,
                page=page,
                page_count=page_count,
                stage=stage,
                elapsed_seconds=elapsed,
                estimated_remaining_seconds=remaining,
                projected_total_seconds=projected_total,
            )

    def complete(self, job_id: str, result: dict) -> None:
        with self._lock:
            job = self._jobs[job_id]
            job.update(
                status="completed",
                current=job["total"],
                stage="completed",
                elapsed_seconds=self._elapsed(job),
                estimated_remaining_seconds=0.0,
                result=result,
            )

    def fail(self, job_id: str, error: str) -> None:
        with self._lock:
            job = self._jobs[job_id]
            job.update(
                status="failed",
                stage="failed",
                elapsed_seconds=self._elapsed(job),
                estimated_remaining_seconds=None,
                error=error,
            )

    def snapshot(self, job_id: str) -> dict | None:
        with self._lock:
            job = self._jobs.get(job_id)
            if job is None:
                return None
            if job["status"] in {"queued", "running"}:
                elapsed = self._elapsed(job)
                job["elapsed_seconds"] = elapsed
                if job["current"] > 0 and job["total"] > job["current"]:
                    projected_total = job.get("projected_total_seconds")
                    if projected_total is not None:
                        job["estimated_remaining_seconds"] = max(0.0, projected_total - elapsed)
            return self._public_snapshot(job)

    def has_active_jobs(self) -> bool:
        with self._lock:
            return any(job["status"] in {"queued", "running"} for job in self._jobs.values())

    @staticmethod
    def _elapsed(job: dict) -> float:
        started_at = job.get("started_at")
        return max(0.0, time.monotonic() - started_at) if started_at is not None else 0.0

    @staticmethod
    def _public_snapshot(job: dict) -> dict:
        internal_keys = {"started_at", "projected_total_seconds"}
        return {key: value for key, value in job.items() if key not in internal_keys}


def image_pages(source: Path, destination: Path, max_pages: int) -> list[Path]:
    destination.mkdir(parents=True, exist_ok=True)
    pages: list[Path] = []

    if source.suffix.lower() == ".pdf":
        document = pdfium.PdfDocument(str(source))
        try:
            for index in range(min(len(document), max_pages)):
                page = document[index]
                try:
                    bitmap = page.render(scale=2.0)
                    try:
                        output = destination / f"page-{index + 1}.png"
                        bitmap.to_pil().convert("RGB").save(output, format="PNG")
                        pages.append(output)
                    finally:
                        bitmap.close()
                finally:
                    page.close()
        finally:
            document.close()
    elif source.suffix.lower() in {".heic", ".heif"}:
        output = destination / "page-1.png"
        conversion = subprocess.run(
            ["/usr/bin/sips", "-s", "format", "png", str(source), "--out", str(output)],
            capture_output=True,
            text=True,
            check=False,
        )
        if conversion.returncode != 0 or not output.is_file():
            detail = conversion.stderr.strip() or conversion.stdout.strip() or "ImageIO conversion failed"
            raise ValueError(f"Could not decode HEIC/HEIF image: {detail}")
        pages.append(output)
    else:
        output = destination / "page-1.png"
        with Image.open(source) as image:
            image.convert("RGB").save(output, format="PNG")
        pages.append(output)

    if not pages:
        raise ValueError("The document has no renderable pages")
    return pages


def markdown_for_pages(pages: list[PageResult]) -> str:
    if len(pages) == 1:
        return pages[0].markdown
    sections = [f"<!-- Page {page.index + 1} -->\n\n{page.markdown}" for page in pages]
    return "\n\n---\n\n".join(sections)


def prune_cache(cache_dir: Path, max_age_days: int = 7) -> None:
    cutoff = time.time() - max_age_days * 24 * 60 * 60
    for child in cache_dir.iterdir():
        try:
            if child.is_dir() and child.stat().st_mtime < cutoff:
                shutil.rmtree(child)
        except OSError:
            LOGGER.warning("Could not prune cache entry: %s", child.name)


def _ocr_blocks(prediction: object, page_index: int, width: int, height: int) -> list[Block]:
    payload = getattr(prediction, "json", {})
    if callable(payload):
        payload = payload()
    if not isinstance(payload, dict):
        return []
    result = payload.get("res", payload)
    texts = result.get("rec_texts") or []
    scores = result.get("rec_scores") or []
    polygons = result.get("rec_polys") or result.get("dt_polys") or []
    boxes = result.get("rec_boxes") or []
    blocks: list[Block] = []

    for index, raw_text in enumerate(texts):
        text = str(raw_text).strip()
        if not text:
            continue
        raw_polygon = polygons[index] if index < len(polygons) else None
        if hasattr(raw_polygon, "tolist"):
            raw_polygon = raw_polygon.tolist()
        if raw_polygon is None and index < len(boxes):
            box = boxes[index]
            if hasattr(box, "tolist"):
                box = box.tolist()
            if len(box) >= 4:
                raw_polygon = [
                    [box[0], box[1]],
                    [box[2], box[1]],
                    [box[2], box[3]],
                    [box[0], box[3]],
                ]
        if not raw_polygon or len(raw_polygon) < 4:
            continue

        polygon = [
            Point(
                x=max(0.0, min(1.0, float(point[0]) / max(1, width))),
                y=max(0.0, min(1.0, float(point[1]) / max(1, height))),
            )
            for point in raw_polygon[:4]
        ]
        score = float(scores[index]) if index < len(scores) else None
        order = len(blocks)
        blocks.append(
            Block(
                id=f"p{page_index + 1}-b{order + 1}",
                page=page_index,
                order=order,
                text=text,
                kind="text",
                polygon=polygon,
                confidence=score,
            )
        )
    return blocks


def process_document(
    runtime: ModelManager,
    source: Path,
    work_dir: Path,
    max_pages: int,
    progress_callback: ProgressCallback | None = None,
) -> dict:
    page_paths = image_pages(source, work_dir, max_pages)
    page_count = len(page_paths)
    results: list[PageResult] = []

    if progress_callback is not None:
        progress_callback(0, page_count, "prepared", 0, page_count)

    for page_index, page_path in enumerate(page_paths):
        if progress_callback is not None:
            progress_callback(page_index, page_count, "recognizing_text", page_index + 1, page_count)
        with Image.open(page_path) as image:
            width, height = image.size
        predictions = runtime.infer(page_path)
        blocks = _ocr_blocks(predictions[0], page_index, width, height) if predictions else []
        text = "\n".join(block.text for block in blocks)
        markdown = "\n\n".join(block.text for block in blocks)
        results.append(
            PageResult(
                index=page_index,
                width=width,
                height=height,
                markdown=markdown,
                text=text,
                preview_path=str(page_path),
                blocks=blocks,
            )
        )
        if progress_callback is not None:
            progress_callback(page_index + 1, page_count, "text_completed", page_index + 1, page_count)

    return {
        "id": str(uuid.uuid4()),
        "model": ModelManager.MODEL_NAME,
        "task": "text_recognition",
        "language_mode": "unified_multilingual",
        "markdown": markdown_for_pages(results),
        "text": "\n\n".join(page.text for page in results),
        "pages": [asdict(page) for page in results],
    }


def run_ocr_job(
    jobs: JobStore,
    job_id: str,
    runtime: ModelManager,
    source: Path,
    request_dir: Path,
    max_pages: int,
) -> None:
    jobs.start(job_id)
    try:
        result = process_document(
            runtime,
            source,
            request_dir,
            max_pages,
            lambda current, total, stage, page, page_count: jobs.update(
                job_id, current, total, stage, page, page_count
            ),
        )
        jobs.complete(job_id, result)
    except Exception as exc:  # noqa: BLE001 - stored for the polling client
        LOGGER.exception("OCR job failed")
        jobs.fail(job_id, str(exc))


async def watch_parent_process(parent_pid: int) -> None:
    while True:
        await asyncio.sleep(0.5)
        if os.getppid() != parent_pid:
            LOGGER.info("FreeOCR parent process exited; stopping local API service")
            os.kill(os.getpid(), signal.SIGTERM)
            return


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="FreeOCR local PP-OCRv6 service")
    parser.add_argument("--detection-model-dir", required=True, type=Path)
    parser.add_argument("--recognition-model-dir", required=True, type=Path)
    parser.add_argument("--cache-dir", required=True, type=Path)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", default=8766, type=int)
    parser.add_argument("--api-key", default="")
    parser.add_argument("--parent-pid", default=0, type=int)
    return parser.parse_args()


def create_app(args: argparse.Namespace) -> FastAPI:
    runtime = ModelManager(args.detection_model_dir, args.recognition_model_dir)
    jobs = JobStore()
    inference_executor = ThreadPoolExecutor(max_workers=1, thread_name_prefix="freeocr-inference")
    inference_futures: set[asyncio.Future] = set()
    args.cache_dir.mkdir(parents=True, exist_ok=True)
    prune_cache(args.cache_dir)

    @asynccontextmanager
    async def lifespan(_: FastAPI):
        loop = asyncio.get_running_loop()
        load_task = loop.run_in_executor(inference_executor, runtime.load)
        watchdog_task = (
            asyncio.create_task(watch_parent_process(args.parent_pid))
            if args.parent_pid > 0
            else None
        )
        try:
            yield
        finally:
            if watchdog_task is not None:
                watchdog_task.cancel()
            if not load_task.done():
                load_task.cancel()
            inference_executor.shutdown(wait=False, cancel_futures=True)

    app = FastAPI(
        title="FreeOCR Local API",
        version="1.1.5",
        description="Offline PP-OCRv6 OCR for Apple Silicon.",
        lifespan=lifespan,
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    def authorize(authorization: Annotated[str | None, Header()] = None) -> None:
        if not args.api_key:
            return
        expected = f"Bearer {args.api_key}"
        if authorization != expected:
            raise HTTPException(status_code=401, detail="Missing or invalid bearer token")

    @app.get("/health")
    async def health() -> dict:
        return runtime.health()

    @app.get("/v1/models", dependencies=[Depends(authorize)])
    async def models() -> dict:
        return {
            "object": "list",
            "data": [
                {
                    "id": ModelManager.MODEL_NAME,
                    "object": "model",
                    "owned_by": "PaddlePaddle",
                    "backend": "ONNX Runtime (CPU)",
                    "language_mode": "unified_multilingual",
                },
            ],
            "active_model": ModelManager.MODEL_NAME if runtime.state == "ready" else None,
        }

    @app.get("/v1/languages", dependencies=[Depends(authorize)])
    async def languages() -> dict:
        return {
            "mode": "unified_multilingual",
            "selection_required": False,
            "multilingual": True,
            "supported_language_count": 50,
            "note": (
                "PP-OCRv6 uses one unified recognition model for Simplified Chinese, Traditional Chinese, "
                "English, Japanese and 46 Latin-script languages; no language selection is required."
            ),
        }

    @app.post("/v1/ocr", dependencies=[Depends(authorize)])
    async def ocr(
        file: Annotated[UploadFile, File(description="Image or PDF")],
        response_format: Annotated[ResponseFormat, Form()] = "json",
        max_pages: Annotated[int, Form(ge=1, le=500)] = 100,
    ):
        if runtime.state == "failed":
            raise HTTPException(status_code=503, detail=runtime.error or "Model failed to load")
        if runtime.state != "ready":
            raise HTTPException(status_code=503, detail="Model is still loading")
        request_dir = args.cache_dir / str(uuid.uuid4())
        request_dir.mkdir(parents=True)
        safe_name = Path(file.filename or "document").name
        source = request_dir / safe_name
        try:
            with source.open("wb") as target:
                shutil.copyfileobj(file.file, target)
            result = await asyncio.get_running_loop().run_in_executor(
                inference_executor,
                process_document,
                runtime,
                source,
                request_dir,
                max_pages,
            )
        except (ValueError, OSError) as exc:
            raise HTTPException(status_code=400, detail=str(exc)) from exc
        except Exception as exc:  # noqa: BLE001 - converted to an API error
            LOGGER.exception("OCR request failed")
            raise HTTPException(status_code=500, detail=str(exc)) from exc
        finally:
            await file.close()

        if response_format == "markdown":
            return PlainTextResponse(result["markdown"], media_type="text/markdown; charset=utf-8")
        if response_format == "text":
            return PlainTextResponse(result["text"], media_type="text/plain; charset=utf-8")
        return JSONResponse(result)

    @app.post("/v1/ocr/jobs", dependencies=[Depends(authorize)], status_code=202)
    async def create_ocr_job(
        file: Annotated[UploadFile, File(description="Image or PDF")],
        max_pages: Annotated[int, Form(ge=1, le=500)] = 100,
    ) -> JSONResponse:
        if runtime.state == "failed":
            raise HTTPException(status_code=503, detail=runtime.error or "Model failed to load")
        if runtime.state != "ready":
            raise HTTPException(status_code=503, detail="Model is still loading")
        request_dir = args.cache_dir / str(uuid.uuid4())
        request_dir.mkdir(parents=True)
        safe_name = Path(file.filename or "document").name
        source = request_dir / safe_name
        try:
            with source.open("wb") as target:
                shutil.copyfileobj(file.file, target)
        except OSError as exc:
            raise HTTPException(status_code=400, detail=str(exc)) from exc
        finally:
            await file.close()

        job = jobs.create()
        future = asyncio.get_running_loop().run_in_executor(
            inference_executor,
            run_ocr_job,
            jobs,
            job["id"],
            runtime,
            source,
            request_dir,
            max_pages,
        )
        inference_futures.add(future)
        future.add_done_callback(inference_futures.discard)
        return JSONResponse(job, status_code=202)

    @app.get("/v1/ocr/jobs/{job_id}", dependencies=[Depends(authorize)])
    async def get_ocr_job(job_id: str) -> JSONResponse:
        job = jobs.snapshot(job_id)
        if job is None:
            raise HTTPException(status_code=404, detail="OCR job not found")
        return JSONResponse(job)

    return app


def main() -> None:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
    args = parse_args()
    for label, model_dir in (
        ("detection", args.detection_model_dir),
        ("recognition", args.recognition_model_dir),
    ):
        if not (model_dir / "inference.onnx").is_file():
            raise SystemExit(f"Invalid {label} model directory: {model_dir}")
    app = create_app(args)
    uvicorn.run(app, host=args.host, port=args.port, log_level="info")


if __name__ == "__main__":
    main()
