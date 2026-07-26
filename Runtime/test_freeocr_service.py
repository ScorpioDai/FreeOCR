import subprocess
import tempfile
import unittest
from pathlib import Path

from PIL import Image

from freeocr_service import JobStore, _ocr_blocks, image_pages


class JobStoreTests(unittest.TestCase):
    def test_tracks_real_progress_and_result(self):
        jobs = JobStore()
        created = jobs.create()

        jobs.start(created["id"])
        jobs.update(created["id"], 1, 4, "content_completed", 1, 2)
        running = jobs.snapshot(created["id"])

        self.assertEqual(running["status"], "running")
        self.assertEqual(running["current"], 1)
        self.assertEqual(running["total"], 4)
        self.assertEqual(running["page"], 1)
        self.assertIsNotNone(running["estimated_remaining_seconds"])

        jobs.complete(created["id"], {"markdown": "Done"})
        completed = jobs.snapshot(created["id"])
        self.assertEqual(completed["status"], "completed")
        self.assertEqual(completed["result"]["markdown"], "Done")
        self.assertEqual(completed["estimated_remaining_seconds"], 0.0)


class OCRParserTests(unittest.TestCase):
    def test_builds_normalized_blocks_with_confidence(self):
        class Prediction:
            json = {
                "res": {
                    "rec_texts": ["中文 English"],
                    "rec_scores": [0.97],
                    "rec_polys": [[[10, 20], [90, 20], [90, 40], [10, 40]]],
                }
            }

        blocks = _ocr_blocks(Prediction(), page_index=1, width=100, height=200)

        self.assertEqual(len(blocks), 1)
        self.assertEqual(blocks[0].id, "p2-b1")
        self.assertEqual(blocks[0].text, "中文 English")
        self.assertEqual(blocks[0].polygon[0].x, 0.1)
        self.assertEqual(blocks[0].polygon[0].y, 0.1)
        self.assertAlmostEqual(blocks[0].confidence, 0.97)


class HEICInputTests(unittest.TestCase):
    def test_converts_heic_to_png_page_with_macos_imageio(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            png_source = root / "source.png"
            heic_source = root / "source.heic"
            Image.new("RGB", (48, 32), (30, 120, 210)).save(png_source)
            subprocess.run(
                ["/usr/bin/sips", "-s", "format", "heic", str(png_source), "--out", str(heic_source)],
                check=True,
                capture_output=True,
            )

            pages = image_pages(heic_source, root / "pages", max_pages=1)

            self.assertEqual(len(pages), 1)
            self.assertEqual(pages[0].suffix, ".png")
            with Image.open(pages[0]) as converted:
                self.assertEqual(converted.size, (48, 32))


class PDFInputTests(unittest.TestCase):
    def test_renders_pdf_pages_and_respects_page_limit(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            pdf_source = root / "source.pdf"
            images = [
                Image.new("RGB", (48, 32), (30, 120, 210)),
                Image.new("RGB", (48, 32), (210, 120, 30)),
            ]
            images[0].save(pdf_source, save_all=True, append_images=images[1:])

            pages = image_pages(pdf_source, root / "pages", max_pages=1)

            self.assertEqual(len(pages), 1)
            with Image.open(pages[0]) as rendered:
                self.assertEqual(rendered.size, (96, 64))


if __name__ == "__main__":
    unittest.main()
