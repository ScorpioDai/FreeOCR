on run argv
    if (count of argv) is not 1 then error "usage: configure_dmg.applescript <volume-name>"
    set volumeName to item 1 of argv
    set backgroundFile to (POSIX file ("/Volumes/" & volumeName & "/.background/installer-background.png")) as alias

    tell application "Finder"
        tell disk volumeName
            open
            set containerWindow to container window
            set current view of containerWindow to icon view
            set toolbar visible of containerWindow to false
            set statusbar visible of containerWindow to false
            set pathbar visible of containerWindow to false
            set bounds of containerWindow to {100, 100, 800, 560}

            set viewOptions to icon view options of containerWindow
            set arrangement of viewOptions to not arranged
            set icon size of viewOptions to 144
            set text size of viewOptions to 13
            set label position of viewOptions to bottom
            set background picture of viewOptions to backgroundFile

            set position of item "FreeOCR.app" of containerWindow to {165, 245}
            set position of item "Applications" of containerWindow to {535, 245}

            update without registering applications
            delay 3
            close containerWindow
        end tell
    end tell
end run
