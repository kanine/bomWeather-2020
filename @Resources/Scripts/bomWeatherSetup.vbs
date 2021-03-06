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

Set f = fso.OpenTextFile(scriptDir & "\Data\RadarLocations.json")
radarLocations = f.readall
f.close

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

  if firstTime Then bomTown = InputBox(messageText, "kanine bomWeather Setup", bomTown)

  firstTime = False

  If bomTown = "" Then wScript.Quit

  idLookup = fetchHTML("https://api.weather.bom.gov.au/v1/locations?search=" & URLEncode(bomTown))

  If debugActive Then
    Set jsonFile = fso.CreateTextFile (scriptDir & "Data\locations-config.json", True)
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

  if bomSelect = "" Then wScript.Quit

  if isNumeric(bomSelect) Then
    If cInt(bomSelect) <= uBound(geohashArray) + 1 Then
      selectionConfirmed = true
      bomTown = nameArray(bomSelect-1) & " " & stateArray(bomSelect-1) & " " & postcodeArray(bomSelect-1)
    Else
      messageText = "Search again" & vbCRLF & " eg (Melbourne 3000, Emerald 3782 etc)"
      bomTown = bomSelect
    End If
  Else 
    messageText = "Search again" & vbCRLF & " eg (Melbourne 3000, Emerald 3782 etc)"
    bomTown = bomSelect
  End If

Loop

' Radar Selection

selectionConfirmed = False
firstTime = True
messageText = "Please choose your radar location" & vbCRLF

radarArray = jsonValuestoArray("name",radarLocations)
siteArray = jsonValuestoArray("site",radarLocations)

Dim radarSelectArray(), siteSelectArray()
x = 0

For i = 0 to uBound(radarArray)
  LogThis Trim(Right(radarArray(i),3)) & " = " & Trim(stateArray(bomSelect-1))
  If Trim(Right(radarArray(i),3)) = Trim(stateArray(bomSelect-1)) Then
    Redim Preserve radarSelectArray(x), siteSelectArray(x)
    radarSelectArray(x) = radarArray(i)
    siteSelectArray(x) = siteArray(i)
    x = x + 1
    messageText = messageText & x & ": " & radarArray(i) & " - " & siteArray(i) & vbCRLF
    LogThis messageText
  End If
Next

Do While Not selectionConfirmed

  bomRadar = InputBox(messageText, "kanine bomWeather Setup")

  if bomRadar = "" Then wScript.Quit

  if isNumeric(bomRadar) Then
    If cInt(bomRadar) <= uBound(radarSelectArray) + 1 Then
      selectionConfirmed = true
    End If
  End If

Loop

Set f = fso.CreateTextFile(applicationDir & "\bomWeather-2020-Configuration.txt", True)
f.writeline "bomTown = " & bomTown  & " <<<"
f.writeline "bomName = " & nameArray(bomSelect-1)  & " <<<"
f.writeline "bomID = " & idArray(bomSelect-1)  & " <<<"
f.writeline "bomgeohash = " & geohashArray(bomSelect-1)  & " <<<"
f.writeline "bomState = " & geohashArray(bomSelect-1) & " <<<"
f.writeline "bomRadar = " & siteSelectArray(bomRadar-1) & " <<<"
f.close

msgbox("Setting Confirmed: " & bomTown & " Radar: " & siteSelectArray(bomRadar-1))

Sub VBInclude(incfile)

' Allows another VBScript file to be incorporated into this one
 
Set incf = fso.OpenTextFile(scriptdir & incfile, 1)
includeScript = incf.ReadAll
incf.Close
Set incf = Nothing

ExecuteGlobal includeScript

End Sub