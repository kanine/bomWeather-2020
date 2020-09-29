if fso.FileExists(scriptDir & "debug.on") Then
  debugActive = True
  if fso.FileExists(scriptDir & "Logs\bomSetup " & formattedDateDay(Now()) & ".log") Then
    Set debugFile = fso.OpenTextFile(scriptDir & "Logs\bomSetup " & formattedDateDay(Now()) & ".log", ForAppending, TristateFalse)
  Else
    Set debugFile = fso.CreateTextFile (scriptDir & "Logs\bomSetup " & formattedDateDay(Now()) & ".log", False)
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

  fetchObj.Open "GET", fetchURL, False
  fetchObj.Send

  If  Err.Number <> 0 Then
    RaiseException "fetchHTML failed: " & fetchURL, Err.Number, Err.Description
  Else 
    fetchHTML = fetchObj.responseText 
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

Function formattedDateSS(dDate)
  formattedDateSS = Year(dDate) & right("0" & Month(dDate),2) & right("0" & Day(dDate),2) & "-" & right("0" & Hour(dDate),2) & right("0" & Minute(dDate),2) & right("0" & second(dDate),2)
End Function

Function formattedDateDay(dDate)
  formattedDateDay = Year(dDate) & right("0" & Month(dDate),2) & right("0" & Day(dDate),2)
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

  LogThis "Counting: " & searchName
  LogThis "In: " & pJSON

  Do While InStr(startPos,pJSON,searchName,1) > 0
    ' LogThis "Start Postion: " & startPos & " Found at: " & InStr(startPos,pJSON,searchName,1)
    startPos = InStr(startPos,pJSON,searchName,1) + 1
    occurs = occurs + 1
  Loop

  LogThis "Found: " & occurs & " occurences"

  jsonCount = occurs

End Function

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