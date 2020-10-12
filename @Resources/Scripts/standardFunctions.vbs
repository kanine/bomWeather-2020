if fso.FileExists(scriptDir & "debug.on") Then
  debugActive = True
  if fso.FileExists(scriptDir & "Logs\bomWeather.log") Then
    Set debugFile = fso.OpenTextFile(scriptDir & "Logs\bomWeather.log", ForAppending, TristateFalse)
  Else
    Set debugFile = fso.CreateTextFile (scriptDir & "Logs\bomWeather.log", False)
  End If
Else
  debugActive = False
End If

Sub LogThis(sText)
  If debugActive Then
    debugFile.WriteLine formattedDateSS(now()) & " " & sText
  End If
End Sub

function fetchHTML(fetchURL)

  Set fetchObj = WScript.CreateObject("MSXML2.ServerXMLHTTP") 

  LogThis "Fetching: " & fetchURL

  fetchObj.Open "GET", fetchURL, False
  fetchObj.Send

  If  Err.Number <> 0 Then
    RaiseException "fetchHTML failed: " & fetchURL, Err.Number, Err.Description
  Else
    response = fetchObj.responseText 
    ' LogThis "Fetch Response: " & response
    fetchHTML = response
  End If
   
End Function

Sub RaiseException (pErrorSection, pErrorCode, pErrorMessage)

    Dim errfs, errf, errContent
    
    Set errfs = CreateObject ("Scripting.FileSystemObject")
    Set errf = errfs.CreateTextFile(log_file & "-errors.txt", True)
    
    errContent = Now() & vbCRLF & vbCRLF & _
                 pErrorSection & vbCRLF & _
                 "Error Code: " & pErrorCode & vbCRLF & _
                 "--------------------------------------" & vbCRLF & _
                 pErrorMessage
    errf.write errContent
    errf.close
    
    If FileTracking Then
      Set errf = errfs.CreateTextFile (log_file & "-errors-" & UpdateTimeStamp & ".txt", True)
      errf.write errContent
      errf.close
    End If

    Set errf = Nothing
    
    If errfs.FileExists(log_file & "-Updating.txt") Then errfs.DeleteFile(log_file & "-Updating.txt") 

    Set errfs = Nothing
    
    WScript.Quit

End Sub

Function formattedDateSS(pDate)
  formattedDateSS = Year(pDate) & MyLpad(Month(pDate),"0",2) & MyLpad(Day(pDate),"0",2) & "-" & MyLpad(Hour(pDate),"0",2) & MyLpad(Minute(pDate),"0",2) & MyLpad(Second(pDate),"0",2)
End Function

Function formattedDateDay(pDate)
  formattedDateDay = Year(pDate) & MyLpad(Month(pDate),"0",2) & MyLpad(Day(pDate),"0",2)
End Function

Function formatted24hr(pDate)
  formatted24hr = MyLpad(Hour(pDate),"0",2) & ":" & MyLpad(Minute(pDate),"0",2)
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
      Item = ""
    End If
  Else
    item = ""
  End If

  parse_item = Trim(Item)

End Function

Function GetENV (pVariable)

  Set incobjShell = CreateObject("WScript.Shell")
  wJunk = incobjshell.ExpandEnvironmentStrings("%" & pVariable & "%")
  Set incobjShell = Nothing
  
  GetENV = wJunk

End Function

Function jsonCount (pName, pJSON) 

  startPos = 1
  occurs = 0
  searchName = """" & pName & """:"

  ' LogThis "Counting: " & searchName
  ' LogThis "In: " & pJSON

  Do While InStr(startPos,pJSON,searchName,1) > 0
    ' LogThis "Start Postion: " & startPos & " Found at: " & InStr(startPos,pJSON,searchName,1)
    startPos = InStr(startPos,pJSON,searchName,1) + 1
    occurs = occurs + 1
  Loop

  LogThis "Found: " & occurs & " occurences of " & pName

  jsonCount = occurs

End Function

Function jsonValuestoArray (pName, pJSON) 

  arraySize = jsonCount(pName, pJSON)
  contentJSON = pJSON

  LogThis "Convert JSON Name " & pName & " to Array"

  Dim jsonArray
  redim jsonArray(arraySize-1)

  For i = 0 to arraySize - 1
    jsonArray(i) = parseJSONValue(pName, contentJSON)
    ' LogThis i & ": " & jsonArray(i)
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

Function MyLPad (MyValue, MyPadChar, MyPaddedLength) 
  MyLpad = String(MyPaddedLength - Len(MyValue), MyPadChar) & MyValue 
End Function

Private Function parseJSONValue (pName, ByRef contents)

  Dim position, item

  position = InStr (1, contents, """" & pName & """:", vbTextCompare)
  
  If position > 0 Then
    ' LogThis "Name found at: " & position
    contents = trim(mid (contents, position + len(pName)+3))
    returnValue = ""
    quoted = false
    nameEnd = false
    scanPosition = 1
    Do While scanPosition <= len(contents) AND Not nameEnd
      ' LogThis "Scan Position: " & scanPosition & " " & Left(Mid(contents,scanPosition),10)
      if scanPosition = 1 and Left(contents,1) = """" Then 
        ' LogThis "Quoted value detected"
        quoted = True
        scanPosition = scanPosition + 1
      End If
      if Mid(contents,scanPosition,1) = "\" Then 
        ' LogThis "Escape value detected"
        returnValue = returnValue & Mid(contents,scanPosition+1,1)
        scanPosition = scanPosition + 1
      End If
      ' LogThis "Test Char: " & Mid(contents,scanPosition,1)
      if quoted and Mid(contents,scanPosition,1) = """" Then nameEnd = true
      if not quoted and Mid(contents,scanPosition,1) = "," Then nameEnd = true
      if not quoted and Mid(contents,scanPosition,1) = "}" Then nameEnd = true
      if not nameEnd Then
        returnValue = returnValue & Mid(contents,scanPosition,1)
        scanPosition = scanPosition + 1
      End If
      ' LogThis "Value: " & returnValue
      ' WScript.Quit
    Loop
  Else
    item = "Invalid Data"
  End If

  parseJSONValue = trim(returnValue)

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
