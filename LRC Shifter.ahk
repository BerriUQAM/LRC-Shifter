SetWorkingDir %A_ScriptDir%

if (A_Args[1] && !A_Args[2])
	ExitApp


windowTitle := "LRC Shifter v1.0.0"

if (!A_Args[1])
{
	Loop {
		FileSelectFile, lrcFilePath, 3,, Please select your LRC file, LRC files (*.lrc)

		if (!lrcFilePath)
			ExitApp
		
		SplitPath, lrcFilePath,, lrcFileDir, lrcFileExt, lrcFileNameNoExt
		
		if (lrcFileExt != "lrc")
			MsgBox, 48, % windowTitle, The selected file is not an LRC file.
		
	} Until lrcFilePath != ""
}
else
{
	lrcFilePath := A_Args[1]
	
	if !FileExist(lrcFilePath)
		ExitApp
	
	SplitPath, lrcFilePath,, lrcFileDir, lrcFileExt, lrcFileNameNoExt
	
	if (lrcFileExt != "lrc")
		ExitApp
}


if (!A_Args[1])
{
	Loop {
		InputBox, shiftValue, % windowTitle, Enter the shift value in ms preceded by + ou -.`nFor example:`n+1600 if you want your lyrics to appear 1600 ms sooner`n-750 if you want them to appear 750 ms later

		if ErrorLevel = 1
			ExitApp
		if !shiftValue
			MsgBox, 48, % windowTitle, No shift value has been entered.
		else if shiftValue is not integer
		{
			shiftValue := ""
			MsgBox, 48, % windowTitle, Invalid shift value. You must enter a number that starts with + ou -.
		}
		
	} Until shiftValue != ""
}
else
{
	shiftValue := A_Args[2]
	
	if shiftValue is not integer
		ExitApp
}



lrcFile := FileOpen(lrcFilePath, "r")

if !IsObject(lrcFile)
{
	if (!A_Args[1])
		MsgBox, 16, % windowTitle, Cannot open "%lrcFilePath%".
	
    ExitApp
}



shiftedLyrics := ""

Loop, Read, % lrcFilePath
{
	if SubStr(A_LoopReadLine, 2, 6) = "offset"
		continue
	
	if !RegExMatch(A_LoopReadLine, "^\[[0-9]{1,3}:[0-9]{1,2}.[0-9]{1,3}\]", timestamp)
	{
		shiftedLyrics .= A_LoopReadLine "`r`n"
		continue
	}
	
	timestampInMs := 0
	Loop, Parse, timestamp, :.[]
	{
		if A_LoopField is not integer
			continue
		
		switch A_Index
		{
			case 2:
				timestampInMs += A_LoopField * 60000
			case 3:
				timestampInMs += A_LoopField * 1000
			case 4:
				timestampInMs += A_LoopField * 10**(3-StrLen(A_LoopField))
		}
	}
	
	timestampInMs := (timestampInMs + shiftValue < 0) ? 0 : timestampInMs + shiftValue
	
	shiftedLyrics .= "[" Format("{:02}", timestampInMs // 60000) ":" Format("{:02}", Mod(timestampInMs, 60000) // 1000) "." Format("{:03}", Mod(timestampInMs, 1000)) "]" SubStr(A_LoopReadLine, StrLen(timestamp)+1) "`r`n"
}

newFilePath := lrcFileDir "\" lrcFileNameNoExt " (shifted)." lrcFileExt

FileDelete, % newFilePath
FileAppend, % shiftedLyrics, % newFilePath

if ErrorLevel
{
	if (!A_Args[1])
		MsgBox, 16, % windowTitle, Cannot create the new file at:"%newFilePath%"
	
	ExitApp
}

if (!A_Args[1])
	MsgBox,, % windowTitle, Done! Your new file has been saved in:`n%newFilePath%

ExitApp
