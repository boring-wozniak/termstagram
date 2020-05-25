#!/usr/bin/osascript

# Just because it's recommended to do :)
# https://developer.apple.com/library/archive/documentation/AppleScript/Conceptual/AppleScriptLangGuide/reference/ASLR_control_statements.html#//apple_ref/doc/uid/TP40000983-CH6g-SW5
use scripting additions

script Util

  # Use capitalization to mark constants
  property ExtensionSeparator : "."

  on split(value as text, separator as text)
    # Save the initial settings
    set delimiters to text item delimiters
    set text item delimiters to separator

    # The main logic ;)
    set parts to text items of value

    set text item delimiters to delimiters

    return parts
  end split

  on join(parts as list, separator as text)
    # Save the initial settings
    set delimiters to text item delimiters
    set text item delimiters to separator

    # The main logic ;)
    set value to parts as text

    set text item delimiters to delimiters

    return value
  end join

  on removeExtension(fileName as text)
    # TODO: Rewrite with 'lastIndexOf'
    set allParts to split(fileName, ExtensionSeparator)
    set allButLastParts to items 1 through -2 of allParts

    return join(allButLastParts, ExtensionSeparator)
  end removeExtension

  # Reads as 'append value to values'
  on append(value, values as list)
    set end of values to value
  end append

end script

# TODO: Try and rewrite the handlers using labeled parameters
# https://developer.apple.com/library/archive/documentation/AppleScript/Conceptual/AppleScriptLangGuide/reference/ASLR_handlers.html

# Use capitalization to mark constants
property ThemeExtension : "zsh-theme"

# Ends with slash
# Basically a shortcut
property HomeFolder : POSIX path of (path to home folder)
property DefaultThemesFolder : HomeFolder & ".oh-my-zsh/themes/"

# Returns records {name:"...", absolutePath:"..."}
on findThemes(themesFolder as text)
  tell application "System Events"
    set themesFiles to Â
      files in folder themesFolder Â
      whose name extension is equal to ThemeExtension

    set themes to {}
    repeat with themeFile in themesFiles
      set themeName to Util's removeExtension(name of themeFile)
      set themePath to POSIX path of themeFile

      # Doesn't work if name 'path' is used ø\_(?)_/ø
      Util's append({name:themeName, absolutePath:themePath}, themes)
    end repeat

    return themes
  end tell
end findThemes

# Not a property so won't be unnecessarily loaded
on DefaultThemes()
  return findThemes(DefaultThemesFolder)
end DefaultThemes

on captureWindow(windowId as integer, outputPath)
  set command to {"screencapture", "-w", "-l", windowId}
  Util's append(quoted form of POSIX path of outputPath, command)

  do shell script Util's join(command, " ")
end captureWindow

on findWindow(aTab)
  tell application "Terminal"
    repeat with currentWindow in windows
      repeat with currentTab in currentWindow's tabs
        if aTab is equal to currentTab's contents then
          return currentWindow
        end if
      end repeat
    end repeat
  end tell
  return missing value
end findWindow

on newTerminalWindow(aPath)
  if aPath is equal to missing value then
    set command to ""
  else
    # 'clear' removes the command itself from the window
    set command to "source " & quoted form of aPath & " && clear"
  end if

  tell application "Terminal"
    set aTab to do script command
    return my findWindow(aTab)
  end tell
end newTerminalWindow

property delayBetweenCommands : 0.5
property commands : {"cd $ZSH", "ll"}

# 'man osascript'
on run arguments
  set outputPath to 1st item in arguments
  tell application "Terminal"
    repeat with theme in my DefaultThemes()
      set currentWindow to my newTerminalWindow(absolutePath of theme)
      delay delayBetweenCommands

      # 'my' and parens are required here
      set screenshotPath to my POSIX file (outputPath & name of theme & ".png")

      repeat with command in commands
        do script command in currentWindow
        delay delayBetweenCommands
      end repeat

      my captureWindow(id of currentWindow, screenshotPath)

      close currentWindow
    end repeat
  end tell
end run
