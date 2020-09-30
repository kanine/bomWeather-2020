Public scriptDir, debugActive, fso, debugFile, regularExp, measureDefs, measureIndex
Const ForReading = 1, ForWriting = 2, ForAppending = 8, applicationFolder = "Rainmeter-kanine"
degreeSymbol = Chr(176)
measureIndex = 1

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

forecastArray = jsonValuestoArray("extended_text",bomDaily)
highsArray = jsonValuestoArray("temp_max",bomDaily)
lowsArray = jsonValuestoArray("temp_min",bomDaily)
chanceArray = jsonValuestoArray("chance",bomDaily)
dateArray = jsonValuestoArray("date",bomDaily)
currentTempArray = jsonValuestoArray("temp",bomObservations)
apparentTempArray = jsonValuestoArray("temp_feels_like",bomObservations)
stationArray = jsonValuestoArray("name",bomObservations)
issueArray = jsonValuestoArray("issue_time",bomObservations)

' Create Formatted Variables for use by the Skin

'Set f = fso.CreateTextFile (scriptDir &"Data\bomWeather-new.txt", True)

Dim objStream
Set objStream = CreateObject("ADODB.Stream")
objStream.CharSet = "utf-8"
objStream.Open


objStream.WriteText FormatCalc("StationAt", stationArray(0) & " at " & formatted24hr(ConvertUTCToLocal(issueArray(i))))
objStream.WriteText FormatCalc("CurrentTemp", currentTempArray(0) & degreeSymbol)
objStream.WriteText FormatCalc("AppTemp", apparentTempArray(0) & degreeSymbol)

For i = 0 to uBound(forecastArray)

  objStream.WriteText FormatCalc("Day" & i & "Forecast", forecastArray(i))
  objStream.WriteText FormatCalc("Day" & i & "HighLow", highsArray(i) & degreeSymbol & "/" & lowsArray(i))
  objStream.WriteText FormatCalc("Day" & i & "ChanceofRain", chanceArray(i))
  objStream.WriteText FormatCalc("Day" & i & "Date", ConvertUTCToLocal(dateArray(i)))
  objStream.WriteText FormatCalc("Day" & i & "DayName", WeekdayName(Weekday(ConvertUTCToLocal(dateArray(i)))))
  objStream.WriteText FormatCalc("Day" & i & "ShortCapName", uCase(Left(WeekdayName(Weekday(ConvertUTCToLocal(dateArray(i)))),3)))

Next

if debugActive Then
  objStream.WriteText vbCRLF & "# Rainmeter Measure Definitions" & vbCRLF & vbCRLF
  objStream.WriteText "RegExp=""(?siU)" & regularExp & """" & vbCRLF & vbCRLF
  objStream.WriteText measureDefs
End If

objStream.SaveToFile scriptDir & "Data\bomWeather-new.txt", 2

'f.Close

Set f = Nothing

Private Function FormatCalc (paramString, wMeasure)

  regularExp = regularExp & "<" & paramString & ">(.*)" & "</" & paramString & ">.*"
  
  measureDefs = measureDefs & "[Measure" & paramString & "]" & vbCRLF
  measureDefs = measureDefs & "Measure=WebParser" & vbCRLF
  measureDefs = measureDefs & "URL=[MeasurebomWeather]" & vbCRLF
  measureDefs = measureDefs & "StringIndex=" & measureIndex & vbCRLF
  measureDefs = measureDefs & vbCRLF
  measureIndex = measureIndex + 1

  FormatCalc = "<" & paramString & ">" & wMeasure & "</" & paramString & ">" & vbCRLF

End Function

Sub VBInclude(incfile)

' Allows another VBScript file to be incorporated into this one
 
Set incf = fso.OpenTextFile(scriptdir & incfile, 1)
includeScript = incf.ReadAll
incf.Close
Set incf = Nothing

ExecuteGlobal includeScript

End Sub

