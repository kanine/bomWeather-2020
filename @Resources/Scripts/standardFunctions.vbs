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
