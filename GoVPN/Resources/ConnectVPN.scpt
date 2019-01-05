tell application "System Preferences"
    reveal pane "Network"
    activate

    tell application "System Events"
        tell process "System Preferences"
            tell window 1
                repeat with r in rows of table 1 of scroll area 1
                    if (value of attribute "AXValue" of static text 1 of r as string) is equal to "$osx_vpn_name" then
                        select r
                    end if
                end repeat

                tell group 1
                    click button "Authentication Settings…"
                end tell

                tell sheet 1
                    set focused of text field 2 to true
                    set value of text field 2 to "$vpn_otp"
                    click button "Ok"
                end tell

                click button "Apply"
                delay 1

                tell group 1
                    click button "Connect"
                end tell
            end tell
        end tell
    end tell

    quit
end tell
