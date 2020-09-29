Public scriptDir, debugActive, fso, debugFile
Const ForReading = 1, ForWriting = 2, ForAppending = 8, applicationFolder = "Rainmeter-kanine"

scriptDir = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName) & "\"
Set fso = CreateObject("Scripting.FileSystemObject")

VBInclude "standardFunctions.vbs"
applicationDir = GetENV("APPDATA") & "\" & applicationFolder & "\"

LogThis "Starting bomWeather Updater"

UpdateTimeStamp = formattedDateSS(Now())

If fso.FileExists(applicationDir & "bomWeather-2020-Configuration.txt") Then
  Set f = fso.OpenTextFile(applicationDir & "bomWeather-2020-Configuration.txt")
  configData = f.readall
  f.close
  bomTown = parse_item (configData, "bomTown =", "<<<")
  bomName = parse_item (configData, "bomName =", "<<<")
  bomID = parse_item (configData, "bomID =", "<<<")
  bomgeohash = parse_item (configData, "bomgeohash =", "<<<")
Else
  MsgBox("Please run bomWeatherSetup.vbs to set up your configuration")
  WScript.Quit
End If

LogThis "Processing: " & bomTown & " (" & bomID &")"

bomParent = Left(bomgeohash,6)

bomLocation = fetchHTML("https://api.weather.bom.gov.au/v1/locations/" & bomgeohash)
bomParentLocation = fetchHTML("https://api.weather.bom.gov.au/v1/locations/" & bomParent)
bomDaily = fetchHTML("https://api.weather.bom.gov.au/v1/locations/" & bomgeohash & "/forecasts/daily")
bomHourly = fetchHTML("https://api.weather.bom.gov.au/v1/locations/" & bomParent & "/forecasts/hourly")
bom3Hourly = fetchHTML("https://api.weather.bom.gov.au/v1/locations/" & bomParent & "/forecasts/3-hourly")
bomObservations = fetchHTML("https://api.weather.bom.gov.au/v1/locations/" & bomgeohash & "/observations")
bomRain = fetchHTML("https://api.weather.bom.gov.au/v1/locations/" & bomParent & "/forecast/rain")
bomWarnings = fetchHTML("https://api.weather.bom.gov.au/v1/locations/" & bomgeohash & "/warnings")

If debugActive Then
  Set jsonFile = fso.CreateTextFile (scriptDir & "Data\location-" & formattedDateDay(Now()) & ".json", True)
  jsonFile.Write bomLocation
  jsonFile.Close
  Set jsonFile = fso.CreateTextFile (scriptDir & "Data\parentlocation-" & formattedDateDay(Now()) & ".json", True)
  jsonFile.Write bomParentLocation
  jsonFile.Close
  Set jsonFile = fso.CreateTextFile (scriptDir & "Data\daily-" & formattedDateDay(Now()) & ".json", True)
  jsonFile.Write bomDaily
  jsonFile.Close
  Set jsonFile = fso.CreateTextFile (scriptDir & "Data\hourly-" & formattedDateDay(Now()) & ".json", True)
  jsonFile.Write bomHourly
  jsonFile.Close
  Set jsonFile = fso.CreateTextFile (scriptDir & "Data\3hourly-" & formattedDateDay(Now()) & ".json", True)
  jsonFile.Write bom3Hourly
  jsonFile.Close
  Set jsonFile = fso.CreateTextFile (scriptDir & "Data\observations-" & formattedDateDay(Now()) & ".json", True)
  jsonFile.Write bomObservations
  jsonFile.Close
  Set jsonFile = fso.CreateTextFile (scriptDir & "Data\rain-" & formattedDateDay(Now()) & ".json", True)
  jsonFile.Write bomRain
  jsonFile.Close
  Set jsonFile = fso.CreateTextFile (scriptDir & "Data\warnings-" & formattedDateDay(Now()) & ".json", True)
  jsonFile.Write bomWarnings
  jsonFile.Close
  Set jsonFile = Nothing
End If

Sub VBInclude(incfile)

' Allows another VBScript file to be incorporated into this one
 
Set incf = fso.OpenTextFile(scriptdir & incfile, 1)
includeScript = incf.ReadAll
incf.Close
Set incf = Nothing

ExecuteGlobal includeScript

End Sub