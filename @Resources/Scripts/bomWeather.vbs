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
isNightArray = jsonValuestoArray("is_night",bomDaily)
laterLabelArray = jsonValuestoArray("later_label",bomDaily)
tempLaterArray = jsonValuestoArray("temp_later",bomDaily)

currentTempArray = jsonValuestoArray("temp",bomObservations)
apparentTempArray = jsonValuestoArray("temp_feels_like",bomObservations)
stationArray = jsonValuestoArray("name",bomObservations)
issueArray = jsonValuestoArray("issue_time",bomObservations)
humidityArray = jsonValuestoArray("humidity",bomObservations)
rainfallArray = jsonValuestoArray("rain_since_9am",bomObservations)
windDirArray = jsonValuestoArray("direction",bomObservations)
windSpeedArray = jsonValuestoArray("speed_kilometre",bomObservations)
windKnotsArray = jsonValuestoArray("speed_knot",bomObservations)
feelsLikeArray = jsonValuestoArray("temp_feels_like",bomObservations)

' Create Formatted Variables for use by the Skin

'Set f = fso.CreateTextFile (scriptDir &"Data\bomWeather-new.txt", True)

Dim objStream
Set objStream = CreateObject("ADODB.Stream")
objStream.CharSet = "utf-8"
objStream.Open

objStream.WriteText FormatCalc("StationAt", stationArray(0) & " at " & formatted24hr(ConvertUTCToLocal(issueArray(i))))
objStream.WriteText FormatCalc("CurrentTemp", currentTempArray(0) & degreeSymbol)
objStream.WriteText FormatCalc("AppTemp", apparentTempArray(0) & degreeSymbol)
objStream.WriteText FormatCalc("ObservedMaxTempTime", "NA")
objStream.WriteText FormatCalc("CurrentRelHumidity", humidityArray(0))
objStream.WriteText FormatCalc("CurrentRainfall", rainfallArray(0))
objStream.WriteText FormatCalc("CurrentWindDirSpeed", windDirArray(0) & " " & windSpeedArray(0) & "km/h")
objStream.WriteText FormatCalc("CurrentForecastShortText", "Forecast for " & WeekdayName(Weekday(ConvertUTCToLocal(dateArray(0)))) & " Max: " & highsArray(i) & degreeSymbol ) 
objStream.WriteText FormatCalc("FeelsLike", feelsLikeArray(0) & degreeSymbol )
objStream.WriteText FormatCalc("LaterTemp", laterLabelArray(0) & ": " & tempLaterArray(0) & degreeSymbol )


For i = 0 to 6
'For i = 0 to uBound(forecastArray)

  objStream.WriteText FormatCalc("Day" & i & "Forecast", forecastArray(i))
  objStream.WriteText FormatCalc("Day" & i & "ForecastImage", ForecastTexttoNumber(forecastArray(i),i,isNightArray(0)))
  objStream.WriteText FormatCalc("Day" & i & "HighLow", highsArray(i) & degreeSymbol & "/" & lowsArray(i))
  objStream.WriteText FormatCalc("Day" & i & "ChanceofRain", chanceArray(i))
  objStream.WriteText FormatCalc("Day" & i & "Date", ConvertUTCToLocal(dateArray(i)))
  objStream.WriteText FormatCalc("Day" & i & "DayName", WeekdayName(Weekday(ConvertUTCToLocal(dateArray(i)))))
  objStream.WriteText FormatCalc("Day" & i & "ShortCapName", uCase(Left(WeekdayName(Weekday(ConvertUTCToLocal(dateArray(i)))),3)))

Next

objStream.WriteText FormatCalc("LastUpdated", Now())

if debugActive Then
  objStream.WriteText vbCRLF & "# Rainmeter Measure Definitions" & vbCRLF & vbCRLF
  objStream.WriteText "RegExp=""(?siU)" & regularExp & """" & vbCRLF & vbCRLF
  objStream.WriteText measureDefs
End If

objStream.SaveToFile scriptDir & "Data\bomWeather-2020-measures.txt", 2

Set objStream = Nothing

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

Private Function ForecastTexttoNumber (ForecastText, DayNumber, isNight)

  Dim Thunder, Rain, Showers, Fine, PartlyCloudy, MostlyCloudy, Fog, FewShowers, Hail, Snow, TempResult
  Dim fs, MoonPhase

  LogThis "Parsing (" & DayNumber & "): " & ForecastText

  Thunder = False
  Rain = False
  Showers = False
  Fine = False
  PartlyCloudy = False
  Fog = False
  MostlyCloudy = False
  FewShowers = False
  Hail = False
  Snow = False

  ForecastText = lcase(ForecastText)

  If InStr(ForecastText,"thunderstorm") > 0 Then Thunder = True
  If InStr(ForecastText,"thunder") > 0 Then Thunder = True
  If InStr(ForecastText,"rain") > 0 Then Rain = True
  If InStr(ForecastText,"some rain") > 0 Then Fine = True
  If InStr(ForecastText,"rain at times") > 0 Then Fine = True
  If InStr(ForecastText,"shower") > 0 Then Showers = True
  If InStr(ForecastText,"drizzle") > 0 Then Showers = True
  If InStr(ForecastText,"clear") > 0 Then Fine = True
  If InStr(ForecastText,"sunny") > 0 Then Fine = True
  If InStr(ForecastText,"sunshine") > 0 Then Fine = True
  If InStr(ForecastText," sun") > 0 Then Fine = True
  If InStr(ForecastText,"fine") > 0 Then Fine = True
  If InStr(ForecastText,"mostly clear") > 0 Then PartlyCloudy = True
  If InStr(ForecastText,"cloud developing") > 0 Then PartlyCloudy = True
  If InStr(ForecastText,"mostly sunny") > 0 Then PartlyCloudy = True
  If InStr(ForecastText,"cool change") > 0 Then PartlyCloudy = True
  If InStr(ForecastText,"change later") > 0 Then PartlyCloudy = True
  If InStr(ForecastText,"morning cloud") > 0 Then PartlyCloudy = True
  If InStr(ForecastText,"change developing") > 0 Then PartlyCloudy = True
  If InStr(ForecastText,"mainly fine") > 0 Then PartlyCloudy = True
  If InStr(ForecastText,"late change") > 0 Then PartlyCloudy = True
  If InStr(ForecastText,"becoming fine") > 0 Then PartlyCloudy = True
  If InStr(ForecastText,"cloudy") > 0 Then PartlyCloudy = True
  If InStr(ForecastText,"cloud increasing") > 0 Then PartlyCloudy = True
  If InStr(ForecastText,"cloud clearing") > 0 Then PartlyCloudy = True
  If InStr(ForecastText,"dry ") > 0 Then Fine = True
  If InStr(ForecastText,"dry.") > 0 Then Fine = True
  If InStr(ForecastText,"dry,") > 0 Then Fine = True
  If InStr(ForecastText," dry") > 0 Then Fine = True
  If InStr(ForecastText,"partly cloudy") Then PartlyCloudy = True
  If InStr(ForecastText,"unsettled") Then PartlyCloudy = True
  If InStr(ForecastText,"patchy clouds") Then PartlyCloudy = True
  If InStr(ForecastText,"mostly cloudy") Then MostlyCloudy = True
  If InStr(ForecastText,"few showers") Then FewShowers = True
  If InStr(ForecastText,"shower or two") Then FewShowers = True
  If InStr(ForecastText,"showers redeveloping") Then FewShowers = True
  If InStr(ForecastText,"showers developing") Then FewShowers = True
  If InStr(ForecastText,"fog") Then Fog = True
  If InStr(ForecastText,"hail") Then Hail = True
  If InStr(ForecastText,"snow") Then Snow = True
  
  TempResult = "na"

  If Fine Then TempResult = 32
  If Fine and Not Rain and NOT Showers Then TempResult = 32
  If Not Fine and Rain Then TempResult = 12
  If Not Fine and Not Rain and Showers Then TempResult = 39
  If Fine and Not Rain and Not Showers and PartlyCloudy Then TempResult = 30
  If Fine and Not Rain and Not Showers and MostlyCloudy Then TempResult = 28
  If Fine and Rain Then TempResult = 39
  If Fine and Not Rain and Showers Then TempResult = 39
  If Not Fine and Not Rain and FewShowers Then TempResult = 39
  If Not Fine and Not Rain and Not Showers and Fog Then TempResult = 20
  If Fine and Not Rain and Not Showers and Fog Then TempResult = 34
  If Not Fine and Not Rain and Not Showers and Snow and Hail Then Tempresult = 5
  If Not Fine and Not Rain and Not Showers and Not Snow and Not Hail and MostlyCloudy Then Tempresult = 26
  If Not Fine and Not Rain and Not Showers and Not Snow and Hail Then Tempresult = 6
  If Not Fine and Not Rain and Not Showers and Snow and Not Hail Then Tempresult = 15
  If Not Fine and Not Rain and Not Showers and PartlyCloudy Then TempResult = 30
  If Thunder Then TempResult = 0
  If Thunder and Fine Then TempResult = 37

  LogThis "Interim Result: " & TempResult & ".png"
  
  If isNight and DayNumber = 0 and TempResult <> "na" Then
    If TempResult = 32 Then TempResult = 31
    If TempResult = 12 Then TempResult = 45
    If TempResult = 11 Then TempResult = 45
    If TempResult = 39 Then TempResult = 45
    If TempResult = 28 Then TempResult = 27
    If TempResult = 30 Then TempResult = 29
    If TempResult = 0 Then TempResult = 47  	
    If TempResult = 37 Then TempResult = 47
    If TempResult = 5 Then TempResult = 46
    If TempResult = 6 Then TempResult = 46
    If TempResult = 15 Then TempResult = 46
    If TempResult = 26 Then TempResult = 27
    If TempResult = 34 Then TempResult = 33
    
    'MoonPhase = Get_Cache_Value("Moon Phase", forecast_file)
  
    'Set fs = CreateObject ("Scripting.FileSystemObject")
   
    'If fs.FileExists ("..\images\" & skin & "\" & TempResult & MoonPhase & ".png") Then 
    '  TempResult = TempResult & MoonPhase
    'End If

  End If

  LogThis "Final Result: " & TempResult & ".png"
    
  ForecastTexttoNumber = TempResult & ".png"

End Function


