Option Explicit

Dim wsh, wAppDir, wTempDir, f, fs, InTime, wbomDetails, contents, wDebug
Dim RadarLocation, wImageURL0, wImageURL1, wImageURL2, wImageURL3, wImageURL4, wImageURL5
Const ApplicationFolder = "Rainmeter-kanine"
Const bomURL = "http://bom.gov.au"

Set wsh = WScript.CreateObject( "WScript.Shell" )
wAppDir = (wsh.ExpandEnvironmentStrings("%APPDATA%")) & "\"& ApplicationFolder
wTempDir = (wsh.ExpandEnvironmentStrings("%TEMP%")) & "\"& ApplicationFolder
Set wsh = Nothing

InTime = Now()
wDebug = False
   
Set fs = CreateObject ("Scripting.FileSystemObject")

If fs.FileExists(wAppDir & "\bomWeather-2020-Configuration.txt") Then
  Set f = fs.OpenTextFile(wAppDir & "\bomWeather-2020-Configuration.txt")
  wbomDetails = f.readall
  f.close
  RadarLocation = parse_item (wbomDetails, "bomRadar =", "<<<")
Else
  Dim objShell
  Set objShell = Wscript.CreateObject("WScript.Shell")
  LogThis scriptDir & "bomWeatherSetup.vbs"
  objShell.Run "cmd /c cscript """ & scriptDir & "bomWeatherSetup.vbs"""
  Set objShell = Nothing
  WScript.Quit
End If

GetRadar

Set f = fs.CreateTextFile ("bomRadar-calculations.txt", True)

f.writeline FormatCalc("RadarLocation",  RadarLocation)
f.writeline FormatCalc("RadarImage0", bomURL & wImageURL0)
f.writeline FormatCalc("RadarImage1", bomURL & wImageURL1)
f.writeline FormatCalc("RadarImage2", bomURL & wImageURL2)
f.writeline FormatCalc("RadarImage3", bomURL & wImageURL3)
f.writeline FormatCalc("RadarImage4", bomURL & wImageURL4)
f.writeline FormatCalc("RadarImage5", bomURL & wImageURL5)
f.writeline FormatCalc("LastUpdate", InTime)

f.close

Set f = Nothing
Set fs = Nothing


Sub GetRadar

    Dim xml, wURL
    
    wURL = "http://www.bom.gov.au/products/" & RadarLocation & ".loop.shtml"
    
    Set xml = CreateObject("Microsoft.XMLHTTP")
    xml.Open "POST", wURL, False
    xml.Send
    
    contents = xml.responseText
    
    If wDebug Then
      Set fs = CreateObject ("Scripting.FileSystemObject")
      Set f = fs.CreateTextFile("Radar.html", True)
      f.write wURL & vbCRLF & contents
      f.close
    End If

    wImageURL0 = parse_item (contents,"theImageNames[0] = """ ,"""")
    wImageURL1 = parse_item (contents,"theImageNames[1] = """ ,"""")
    wImageURL2 = parse_item (contents,"theImageNames[2] = """ ,"""")
    wImageURL3 = parse_item (contents,"theImageNames[3] = """ ,"""")
    wImageURL4 = parse_item (contents,"theImageNames[4] = """ ,"""")
    If wImageURL4 = "Invalid Data" Then wImageURL4 = wImageURL3
    wImageURL5 = parse_item (contents,"theImageNames[5] = """ ,"""")
    If wImageURL5 = "Invalid Data" Then wImageURL5 = wImageURL4

    contents = xml.responseText
    
    Set xml = Nothing

End Sub

Private Function FormatCalc (paramString, wMeasure)

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

