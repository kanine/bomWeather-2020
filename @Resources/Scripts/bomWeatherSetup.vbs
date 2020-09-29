Public scriptDir, debugActive, fso, debugFile
Const ForReading = 1, ForWriting = 2, ForAppending = 8, applicationFolder = "Rainmeter-kanine"

scriptDir = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName) & "\"
Set fso = CreateObject("Scripting.FileSystemObject")

VBInclude "standardFunctions.vbs"
applicationDir = GetENV("APPDATA") & "\" & applicationFolder

LogThis "Starting bomWeather Configuration"

Dim wInput, fs, f, shell, wAppDir, wbomDetails
Dim ForecastCity, ObservationType, observation_url, observation_station, forecast_url, SunriseLocation, State, TimeZone, RadarLocation

LogThis "Application Directory: " & applicationDir

If NOT fso.FolderExists(applicationDir) Then
 fso.CreateFolder(applicationDir)
End If

ForecastCity = ""
ObservationType = "Detail"
observation_url = ""
observation_station  = ""
forecast_url = ""
SunriseLocation = ""
State = ""
TimeZone = ""

If fso.FileExists(applicationDir & "\bomWeather-2020-Configuration.txt") Then
  Set f = fso.OpenTextFile(applicationDir & "\bomWeather-2020-Configuration.txt")
  wbomDetails = f.readall
  f.close
  
  bomTown = parse_item (wbomDetails, "bomTown =", "<<<")
  bomTownID = parse_item (wbomDetails, "bomTown_id =", "<<<")
  
End If

selectionConfirmed = False
firstTime = True
messageText = "Please enter your town and postcode" & vbCRLF & " eg (Melbourne 3000, Emerald 3782 etc)"

Do While Not selectionConfirmed

  bomTown = InputBox(messageText, "kanine bomWeather Setup", bomTown)

  If bomTown = "" Then wScript.Quit

  idLookup = fetchHTML("https://api.weather.bom.gov.au/v1/locations?search=" & URLEncode(bomTown))

  If debugActive Then
    Set jsonFile = fso.CreateTextFile (scriptDir & "Data\locations-" & formattedDateDay(Now()) & ".json", True)
    jsonFile.Write idLookup
    jsonFile.Close
    Set jsonFile = Nothing
  End If

  If jsonCount("geohash",idLookup) > 0 Then
    geohashArray = jsonValuestoArray("geohash",idLookup)
    idArray = jsonValuestoArray("id",idLookup)
    nameArray = jsonValuestoArray("name",idLookup)
    postcodeArray = jsonValuestoArray("postcode",idLookup)
    stateArray = jsonValuestoArray("state",idLookup)

    messageText = "Possible locations found" & vbCRLF & vbCRLF
    For i = 0 to uBound(geohashArray)
      messageText = messageText & i+1 & ": " & nameArray(i) & " " & stateArray(i) & " " & postcodeArray(i) & vbCRLF
      if i > 15 Then 
        messageText = messageText & "More entries... Refine search if necessary" & vbCRLF
        Exit For
      End If
    Next
    messageText = messageText & vbCRLF & "Please confirm selection or refine search"
  End If

  bomSelect = InputBox(messageText, "kanine bomWeather Setup")

  selectionConfirmed = true

Loop

Set f = fso.CreateTextFile(applicationDir & "\bomWeather-2020-Configuration.txt", True)
f.writeline "bomTown = " & bomTown  & " <<<"
f.close

Sub VBInclude(incfile)

' Allows another VBScript file to be incorporated into this one
 
Set incf = fso.OpenTextFile(scriptdir & incfile, 1)
includeScript = incf.ReadAll
incf.Close
Set incf = Nothing

ExecuteGlobal includeScript

End Sub

Private Function parseJSONValue (pName, ByRef contents)

  Dim position, item

  position = InStr (1, contents, """" & pName & """:", vbTextCompare)
  
  If position > 0 Then
    LogThis "Name found at: " & position
    contents = mid (contents, position + len(pName)+3)
    if InStr (1, contents, "}", vbTextCompare) < InStr (1, contents, ",", vbTextCompare) Then
      position = InStr (1, contents, "}", vbTextCompare)
    Else
      position = InStr (1, contents, ",", vbTextCompare)
    End If
		If position > 0 Then
      item = mid (contents, 1, position - 1)
    Else
      if InStr (1, contents, "}", vbTextCompare) > 0 AND InStr (1, contents, ",", vbTextCompare) = 0 Then 
        position = InStr (1, contents, "}", vbTextCompare)
        item = mid (contents, 1, position - 1)
        LogThis "Last item in JSON"
      Else 
        Item = ""
      End if
    End If
  Else
    item = ""
  End If

  parseJSONValue = cleanJSON(Item)

End Function

Function jsonValuestoArray (pName, pJSON) 

  arraySize = jsonCount(pName, pJSON)
  contentJSON = pJSON

  LogThis "Convert JSON Name " & pName & " to Array"

  Dim jsonArray
  redim jsonArray(arraySize-1)

  For i = 0 to arraySize - 1
    jsonArray(i) = parseJSONValue(pName, contentJSON)
    LogThis i & ": " & jsonArray(i)
  Next

  jsonValuestoArray = jsonArray

End Function

Function URLEncode( StringVal )
  Dim i, CharCode, Char, Space
  Dim StringLen

  StringLen = Len(StringVal)
  ReDim result(StringLen)

  Space = "+"
  'Space = "%20"

  For i = 1 To StringLen
    Char = Mid(StringVal, i, 1)
    CharCode = AscW(Char)
    If 97 <= CharCode And CharCode <= 122 _
    Or 64 <= CharCode And CharCode <= 90 _
    Or 48 <= CharCode And CharCode <= 57 _
    Or 45 = CharCode _
    Or 46 = CharCode _
    Or 95 = CharCode _
    Or 126 = CharCode Then
      result(i) = Char
    ElseIf 32 = CharCode Then
      result(i) = Space
    Else
      result(i) = "&#" & CharCode & ";"
    End If
  Next
  URLEncode = Join(result, "")
End Function

Function cleanJSON(pValue)

  if mid(pValue,1,1) = """" Then pValue = Mid(pValue,2)
  if right(pValue,1) = """" Then pValue = Mid(pValue,1,Len(pValue) - 1)

  cleanJSON = trim(pValue)

End Function