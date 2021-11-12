Option Explicit

Dim wsh, wAppDir, wTempDir, f, fs, InTime, wbomDetails, contents, debugActive, needSetup, scriptDir, radarInfo()
Dim RadarLocation, i, regularExp, measureDefs, measureIndex, offsetIndex, imageCount
Const ApplicationFolder = "Rainmeter-kanine"
Const bomURL = "http://www.bom.gov.au"

measureIndex = 1
regularExp = ""

scriptDir = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName) & "\"

Set wsh = WScript.CreateObject( "WScript.Shell" )
wAppDir = (wsh.ExpandEnvironmentStrings("%APPDATA%")) & "\"& ApplicationFolder
wTempDir = (wsh.ExpandEnvironmentStrings("%TEMP%")) & "\"& ApplicationFolder
Set wsh = Nothing
   
Set fs = CreateObject ("Scripting.FileSystemObject")

if fs.FileExists(scriptDir & "debug.on") Then
  debugActive = True
Else
  debugActive = False
End If

InTime = Now()

needSetup = True
RadarLocation = ""

If fs.FileExists(wAppDir & "\bomWeather-2020-Configuration.txt") Then
  Set f = fs.OpenTextFile(wAppDir & "\bomWeather-2020-Configuration.txt")
  wbomDetails = f.readall
  f.close
  RadarLocation = parse_item (wbomDetails, "bomRadar =", "<<<")
  needSetup = False
End If

If needSetup OR RadarLocation = "Invalid Data" Then
  Dim objShell
  Set objShell = Wscript.CreateObject("WScript.Shell")
  objShell.Run "cmd /c cscript """ & scriptDir & "bomWeatherSetup.vbs"""
  Set objShell = Nothing
  WScript.Quit
End If

GetRadar

Set f = fs.CreateTextFile (scriptDir & "Data\bomRadar-calculations.txt", True)

f.writeline FormatCalc("RadarLocation",  RadarLocation)
f.writeline FormatCalc("RadarCount",  6)

offsetIndex = 0

if imageCount > 6 Then offsetIndex = imageCount - 6

For i = 0 to 5
   if i+offsetIndex <= imageCount - 1 Then 
    f.writeline FormatCalc("RadarImage" & i, bomURL & radarInfo(i+offsetIndex))
    if i = 0 Then 
      f.writeline FormatCalc("RadarTime" & i, ">> " & URLtoTime(radarInfo(i+offsetIndex)) & " >>")
    Else
      f.writeline FormatCalc("RadarTime" & i, URLtoTime(radarInfo(i+offsetIndex)))
    End If
  Else
    f.writeline FormatCalc("RadarImage" & i, bomURL & radarInfo(imageCount-1))
    f.writeline FormatCalc("RadarTime" & i, URLtoTime(radarInfo(imageCount-1)))
  End If
Next

f.writeline FormatCalc("LastUpdate", InTime)

if debugActive Then
  f.writeline vbCRLF & "# Rainmeter Measure Definitions" & vbCRLF
  f.writeline "RegExp=""(?siU)" & regularExp & """" & vbCRLF
  f.writeline measureDefs
End If

f.close

Set f = Nothing
Set fs = Nothing

Sub GetRadar

    Dim xml, wURL, lastRadar, imageURL
    
    wURL = "http://www.bom.gov.au/products/" & RadarLocation & ".loop.shtml"
    
    Set xml = CreateObject("Microsoft.XMLHTTP")
    xml.Open "POST", wURL, False
    xml.Send
    
    contents = xml.responseText
    
    If debugActive Then
      Set fs = CreateObject ("Scripting.FileSystemObject")
      Set f = fs.CreateTextFile("Radar.html", True)
      f.write wURL & vbCRLF & contents
      f.close
    End If

    imageCount = 0
    lastRadar = False

    Do While Not lastRadar

      imageURL = parse_item (contents,"theImageNames[" & imageCount & "] = """ ,"""")
      if imageURL = "Invalid Data" Then
        lastRadar = True
      Else
        ReDim Preserve radarInfo(imageCount+1)
        radarInfo(imageCount) = imageURL
        'msgbox(imageCount & " " & imageURL)
        imageCount = imageCount + 1
      End If
    
    Loop

End Sub

Private Function FormatCalc (paramString, wMeasure)

  regularExp = regularExp & "<" & paramString & ">(.*)" & "</" & paramString & ">.*"
  
  measureDefs = measureDefs & "[Measure" & paramString & "]" & vbCRLF
  measureDefs = measureDefs & "Measure=WebParser" & vbCRLF
  measureDefs = measureDefs & "URL=[MeasureRadarConfig]" & vbCRLF
  measureDefs = measureDefs & "StringIndex=" & measureIndex & vbCRLF
  measureDefs = measureDefs & vbCRLF
  measureIndex = measureIndex + 1

  FormatCalc = "<" & paramString & ">" & wMeasure & "</" & paramString & ">"

End Function

Private Function parse_item (ByRef contents, start_tag, end_tag)

	Dim position, item
	
	position = InStr (1, contents, start_tag, vbTextCompare)

	If position > 0 Then
		' Trim the html information.
		contents = mid (contents, position + len (start_tag))
		position = InStr (1, contents, end_tag, vbTextCompare)
		
		If position > 0 Then
			item = mid (contents, 1, position - 1)
		Else
			item = "Invalid Data"
		End If
	Else
		item = "Invalid Data"
	End If

	parse_item = Trim(Item)

End Function

Function URLtoTime(pURL)

  Dim UTCTime, dateText

  dateText = left(right(pURL,16),12)
  URLtoTime = ConvertUTCToLocal(Mid(dateText,1,4) & "-" & Mid(dateText,5,2)  & "-" & Mid(dateText,7,2) & "T" & Mid(dateText,9,2) & ":" & Mid(dateText,11,2)  & ":00Z")

End Function

Function ConvertUTCToLocal( varTime )
    
  Dim myObj, MyDate
  
  if Not isnull(varTime) Then
  
    MyDate = CDate(replace(Mid(varTime, 1, 19) , "T", " "))
    Set myObj = CreateObject( "WbemScripting.SWbemDateTime" )
    myObj.Year = Year( MyDate )
    myObj.Month = Month( MyDate )
    myObj.Day = Day( MyDate )
    myObj.Hours = Hour( MyDate )
    myObj.Minutes = Minute( myDate )
    myObj.Seconds = Second( myDate )
    ConvertUTCToLocal = myObj.GetVarDate( True )
    
  Else
  
    ConvertUTCToLocal = null
  
  End If
  
End Function