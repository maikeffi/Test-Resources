Option Explicit


'Class clsImplementor : Hierarchy Builder and Step Implementor
Class clsImplementor
	Private dicHWND				'Collection for all Windows/Browser Properties

	Public oME 					'Region Reference
    Public iRow					'Test case row
	Public sParentDescription	'Window/Browser Description or Name given in the Excel Spreadsheet
    Public sParent				'Parent Level Class
	Public sChild				'Child Level Class
	Public sEvent				'Event to be performed
    Public sValue				'Value to be entered in the target field

    '<comment>
	'	<name>
	'		Default Function Run
	'	</name>
	'	<summary>
	'		Holds the execution result of a single test case
	'		in the Excel spreadsheet. 
	'	</summary>
	'	<return type="Boolean">
	'		Possible values are True or False. <br/>
	'		True: All test case steps were performed correctly, 
	'		and without errors. <br/>
	'		False: One or more errors occured during execution. 
	'		This can be due to an application error, or a user error.
	'	</return>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'	<seealso>
	'		GetTestCaseResult
	'	</seealso>
	'</comment>
	Public Default Function Run()	'As Boolean
 		Run = GetTestCaseResult()
	End Function

	'<comment>
	'	<name>
	'		Function GetTestCaseResult
	'	</name>
	'	<summary>
	'		Returns the execution result to the Public Method: Run
	'	</summary>
	'	<return type="Boolean">
	'		True: All rows of the test case executed successfully.
	'	</return>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'	<seealso> 
	'		IsDataValid
	'		ExecuteLevels
	'		UnloadSettings
	'	</seealso>
	'</comment>
	Private Function GetTestCaseResult()	'As Boolean
 		GetTestCaseResult = False
		
		If IsDataValid Then
			GetTestCaseResult = ExecuteLevels
		End If

		UnloadSettings
	End Function

	'<comment>
	'	<name>
	'		Function IsDataValid
	'	</name>
	'	<summary>
	'		Returns a boolean output of the validity of the test case
	'		data present in the Excel spreadsheet.
	'	</summary>
	'	<return type="Boolean">
	'		Possible values are True or False. <br/>
	'		True: All test case steps were built correctly, and the 
	'		IsEventValid/IsValueValid methods did not find any user
	'		errors in building the events/values in the Excel spreadsheet. <br/>
	'		False: One or more errors were found. 
	'	</return>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'	<seealso>
	'		IsEventValid
	'		IsValueValid
	'		BuildLevel
	'	</seealso>
	'</comment>
	Private Function IsDataValid() 'As Boolean
		Dim x, iRow

		IsDataValid = False

		oLevels = CreateObject("Scripting.Dictionary")

		'Run all rows of the Excel Book, until an error is encountered
		For x = 1 to iLevels
			'Set Region Row
			Me.iRow = x
			'Verify if the Supplied Events/Values are valid
			If Not (IsEventValid And IsValueValid) Then
				Exit Function
			Else
				'Build the Object Hierarchy
				BuildLevel
			End If
		Next

		IsDataValid = True
	End Function
	
	'<comment>
	'	<name>
	'		Function ExecuteLevels
	'	</name>
	'	<summary>
	'		Executes each statement built in BuildLevel().
	'	</summary>
	'	<return type="Boolean">
	'		Possible values are True or False. <br/>
	'		True: If all test case rows are executed successfully. <br/>
	'		False: If one or more test case rows return an error.
	'	</return>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'	<seealso>
	'		CreateTopLevelDescription
	'		CheckProperty
	'		IsItemExists
	'		InitIE
	'		InitWin
	'	</seealso>
	'</comment>
	Private Function ExecuteLevels()	'As Boolean
		Dim iRow, sChild, sDescription, sEvent, sParent, bExists

		ExecuteLevels = False

		'dicHWND stores Windows Handles of all Parent Level Objects
		'Key: sParentDescription
		'Item: Windows Handle of the Parent tied to sParentDescription
		Set dicHWND = CreateObject("Scripting.Dictionary")

		On Error Resume Next

			'oLevels.Count = number of rows in the test case
			For iRow = 1 to oLevels.Count

				'Child Object Class
				sChild = Data.Item(iRow & "|Child")
				'Description of Child/Parent Class
				sDescription = Data.Item(iRow & "|Description")
				'Event to be performed on Child/Parent Class
				sEvent = Data.Item(iRow & "|Event")
				'Parent Object Class
				sParent = Data.Item(iRow & "|Parent")

				'If a new Browser/Window is not being launched then build Parent 
				'level description
				If Not sEvent = "Launch" Then 
					oLevels.Item(iRow) = CreateTopLevelDescription(iRow)
				End If

				'Switch for different events:
				Select Case sEvent
					Case "Activate"
						If sChild = "" Then
							Me.sParentDescription = sDescription
						Else
							Report micWarning, sChild & " Activate", sChild & _
								" does not support the Activate method.", "", ""
						End If
					'Custom CheckPoint
					Case "CheckProperty"
						CheckProperty iRow
					'Check if an object exists
					Case "Exist"
						If Not IsItemExists(iRow) Then
							Exit Function
						End If
					'Invoke an application
					Case "Launch"
						Select Case sParent
							Case "Browser"
								InitIE iRow
							Case "Window"
								InitWin iRow
						End Select
					'Execute Row
					Case Else
						Execute oLevels.Item(iRow)
				End Select

				If Err.Number <> 0 Then
					Err.Clear
					Report micFail, "Step " & iRow, "Step failed.", "", ""
					Exit Function
				Else
					ExecuteLevels = True
					Report micPass, "Step " & iRow, "Step passed.", "", ""
				End If
					
			Next

		On Error Goto 0
	End Function

	'<comment>
	'	<name>
	'		Sub BuildLevel
	'	</name>
	'	<summary>
	'		Builds Object Hierarchy of the target row from Excel Book
	'		Each level is added in 'oLevels' as a string. 
	'	</summary>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'	<seealso>
	'	</seealso>
	'</comment>
	Private Sub BuildLevel()
		Dim iRow, sParent, sChild, sDescription, sEvent, sValue

		iRow = Me.iRow

		'Child Object Class
		sChild = Data.Item(iRow & "|Child")
		'Description of Child/Parent Class
		sDescription = Data.Item(iRow & "|Description")
		'Event to be performed on Child/Parent Class
		sEvent = Data.Item(iRow & "|Event")
		'Parent Object Class
		sParent = Data.Item(iRow & "|Parent")
		'Value the child/parent class will hold after row executes
		sValue = Data.Item(iRow & "|Value")	

		'[property1:=value1][property2:=value2]
		'If multiple descriptions are used:
		If Left(sDescription, 1) = "[" And sChild <> "" Then
			Dim oMatches, sMatch

			Set oMatches = GetRegExpMatch("\[[^]]*\]", sDescription)

			sDescription = ""

			'Create the new description for the target object
			For Each sMatch in oMatches
				sDescription = sDescription & """" & Mid(sMatch, 2, Len(sMatch) - 2) & ""","
			Next

			'"html tag:=", "index:=0",   becomes:
			'"html tag:=", "index:=0"
			sDescription = Left(sDescription, Len(sDescription)-1)
		ElseIf sChild <> "" Then
			sDescription = """" & sDescription & """"
		End If

		'If the level contains a child object:
		If sChild <> "" Then
			'The description will be used for Child, if the level contains a child
			sChild = "." & sChild & "(" & sDescription & ")"
			'Retrieve currently used Parent Description
			sParent = "" & sParent & "(""" & Me.sParentDescription & """)"    
			'If the parent is a Browser, then include the Page hierarchy in the level
			If Data.Item(iRow & "|Parent") = "Browser" Or Data.Item(iRow & "|Parent") = "Browser Page" Then
				sParent = "Browser(""" & Me.sParentDescription & """)" & ".Page(""micclass:=Page"")" 
			End If
		Else
			Me.sParentDescription = sDescription
			Select Case sEvent
				Case "Close"
					sParent = "" & sParent & "(""" & sDescription & """)"
				Case Else
					If sParent = "Browser Page" Or sParent = "Browser" Then
						sParent = "Browser(""" & sDescription & """)" & ".Page(""micclass:=Page"")"	
					Else
						sParent = "" & sParent & "(""" & sDescription & """)"
					End If
			End Select
		End If

		If sEvent <> "" Then sEvent = "." & sEvent
		If sEvent = "Exist" And sValue = "" Then sValue = 1
		If sValue <> "" Then sValue = " (""" & sValue & """)"

		'Holds the built hierarchy
		'oLevels.Add Integer, Object
		'Example: oLevels.Add 9, Browser("property:=value").Page("property:=Value").WebEdit("property:=Value").Event(sValue)
		'9 = Row Number
		'Browser("property:=value").Page("property:=Value").WebEdit("property:=Value").Event(sValue) = Object
		oLevels.Add iRow, sParent & sChild & sEvent & sValue
	End Sub
	
	'<comment>
	'	<name>
	'		Function CheckProperty
	'	</name>
	'	<summary>
	'		Verifies if the actual and expected properties of an
	'		object match. Expected properties are contained in the Excel
	'		Book, whereas, RunTime properties come from the application.
	'	</summary>
	'	<param name="iRow" type="Integer">
	'		Test case row
	'	</param>
	'	<return type="Boolean">
	'		True: If the expected and actual properties match
	'	</return>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'	<seealso>
	'	</seealso>
	'</comment>
	Private Function CheckProperty(iRow)	'As Boolean
		Dim sMatch, oMatches, ix, sProperty, sExpected, sString, bResult, sValue, iPosition

		bResult = False

		sValue = Data.Item(iRow & "|Value")
		'Hierarchical String created in BuildLevel for row #: iRow
		sString = oLevels.Item(iRow)

		'[property][expected value]
		Set oMatches = GetRegExpMatch("\[[^]]*\]", sValue)
		
		ix = 0

		'The first match contains the property
		'The second match contains the expected value of the property		
		For Each sMatch in oMatches
			ix = ix + 1
			Select Case ix
				Case 1
					sProperty = Mid(sMatch, 2, Len(sMatch)-2)
				Case 2
					sExpected = Mid(sMatch, 2, Len(sMatch)-2)
			End Select
		Next

		'Replace CheckProperty in the Hierarchy with GetROProperty
        iPosition = InStr(sString, "CheckProperty")
		sString = Left(sString, iPosition - 1)
		sString = sString & "GetROProperty(""" & sProperty & """)"

		'sValue will hold the Actual (RunTime) value of the property
		Execute "sValue = " & sString

        'Compare Actual and Expected
		If sValue = sExpected Then
			bResult = True
		End If
		
		'Report Pass/Fail
		If Not bResult Then
			Report micFail, "Step " & iRow & "- CheckProperty", "Properties Do Not Match", _
				sExpected, sValue
		Else
			Report micPass, "Step " & iRow & "- CheckProperty", "Properties Match", _
				sExpected, sValue
		End If

		CheckProperty = bResult
	End Function

	'<comment>
	'	<name>
	'		Function CreateTopLevelDescription
	'	</name>
	'	<summary>
	'		Creates a description for the Parent object
	'	</summary>
	'	<param name="iRow" type="Integer">
	'		Test case row
	'	</param>
	'	<return type="Text">
	'		The created description of the parent
	'	</return>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'	<seealso>
	'	</seealso>
	'</comment>
	Private Function CreateTopLevelDescription(iRow)	'As String
		Dim sString, oMatches, sMatch, sParentDescription, sDescription, sChild

		'Child Object Class
		sChild = Data.Item(iRow & "|Child")
		'Description of the Parent Object
        sParentDescription = Me.sParentDescription

		'If the row level doesn't contain a child object, then.. build Parent with
		'the supplied description (sParetnDescription)
		If Not sChild <> "" Then
			'Description in the iRow row of the Excel Book
			sDescription = Data.Item(iRow & "|Description")

			'Check dicHWND for the supplied description
			If Not dicHWND.Exists(sDescription) Then
				'If the supplied description is not found, then update the region variable
				'with the supplied description.
                Me.sParentDescription = sDescription

				Dim sEvent, sValue

				'Retrieve Event to be performed	
				sEvent = Data.Item(iRow & "|Event")
				'Retrieve the value supplied to identify the parent
				sValue = Data.Item(iRow & "|Value")

				'If the parent is being switched over to, then, use the provided value (sValue)
				'to identify the parent.
				If sEvent = "Activate" Then
					If sValue <> "" Then
						If Window(sValue).Exist(15) Then
							dicHWND.Add sDescription, "hwnd:=" & Window(sValue).GetROProperty("hwnd")
						ElseIf Browser(sValue).Exist(15) Then
							dicHWND.Add sDescription, "hwnd:=" & Browser(sValue).GetROProperty("hwnd")
						End If
					End If
				End If
			End If
		End If

		'sString Contains the description from BuildLevel
        sString = oLevels.Item(iRow)

		Set oMatches = GetRegExpMatch("\(""\w+""\)", sString)

		'We only use the first match, because the first description is always the Parent description
		For Each sMatch in oMatches
			Exit For
		Next

		'Replace the description in sString with the description from dicHWND.Item(Key)
		'Browser("Google") -> Browser("hwnd:=123145")
		CreateTopLevelDescription = Replace(sString, Left(sMatch, Len(sMatch)), "(""" & dicHWND.Item(sParentDescription) & """)")
	End Function

	'<comment>
	'	<name>
	'		Function IsEventValid
	'	</name>
	'	<summary>
	'		Verifies if the Event is a valid for a given Parent
	'	</summary>
	'	<return type="Boolean">
	'		True: Event is valid
	'	</return>
	'	<remarks>
	'		All levels must return true for the test case to begin execution.
	'	</remarks>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'</comment>
	Private Function IsEventValid()	'As Boolean
		Dim iRow, sChild, sEvent, sParent, sClass, sEvents

		IsEventValid = False

		'Get the current Execution Row from the region variable
		iRow = Me.iRow

		'Child Object Class
		sChild = Data.Item(iRow & "|Child")
		'Description of Child/Parent Class
		sEvent = Data.Item(iRow & "|Event")
		'Parent Object Class
		sParent = Data.Item(iRow & "|Parent")
		
		sEvents = "Exist, CheckProperty, "

		'sClass points to the target class on which the event is performed on
		If Not sChild = "" Then
			sClass = sChild
		Else
			sClass = sParent
		End If

		'Switch block verifies if the event is a correct event for the class
		Select Case sClass
			'Browser
			Case "Browser", "Browser Page"
				'Expected Events: Exist, CheckProperty, Activate, Close, Launch, Navigate, Sync
				IsEventValid = (InStr(1, sEvents & "Activate, Close, Launch, Navigate, Sync", sEvent) > 0)
			'Window
			Case "Window"
				'Expected Events: Exist, CheckProperty, Close, Activate, Launch
				IsEventValid = (InStr(1, sEvents & "Close, Activate, Launch", sEvent) > 0)
			'Dialog
			Case "Dialog"
				'Expected Events: Exist, CheckProperty, Close
				IsEventValid = (InStr(1, sEvents & "Close", sEvent) > 0)
			'Image, Link, WebButton, WinButton, WebElement: Click
			Case "Image", "Link", "WebButton", "WinButton", "WebElement"
				'Expected Events: Exist, CheckProperty, Click
				IsEventValid = (InStr(1, sEvents & "Click", sEvent) > 0)
			'WebEdit, WebCheckBox, WinEdit, WinCheckBox: Set
			Case "WebEdit", "WebCheckBox", "WinEdit", "WinCheckBox"
				'Expected Events: Exist, CheckProperty, Click, Set
				IsEventValid = (InStr(1, sEvents & "Click, Set", sEvent) > 0)
			'WebList, WebRadioGroup, WinComboBox, WinEditor: Select
			Case "WebList", "WebRadioGroup", "WinComboBox", "WinEditor"
				'Expected Events: Exist, CheckProperty, Select
				IsEventValid = (InStr(1, sEvents & "Select", sEvent) > 0)
			'WinObject
			Case "WinObject"
				'Expected Events: Exist, CheckProperty, Click, Set, Type
				IsEventValid = (InStr(1, sEvents & "Click, Set, Type", sEvent) > 0)
		End Select

		'Report
		If Not IsEventValid Then
			Report micFail, "IsEventValid", "Invalid Event found on Row: " & iRow & _
				". " & TestData.sCurrentTest & " will now exit.", "", ""
		End If
	End Function

	'<comment>
	'	<name>
	'		Function IsValueValid
	'	</name>
	'	<summary>
	'		Verifies if the Supplied value is correct for the
	'		target class. 
	'	</summary>
	'	<return type="Boolean">
	'		True: Value is within the norms of the target Class. <br/>
	'		Class = WebCheckBox, Value = ON     (True) <br/>
	'		Class = WebCheckBox, Value = Select (False)
	'	</return>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'	<seealso>
	'	</seealso>
	'</comment>
	Private Function IsValueValid()	'As Boolean
		Dim iRow, sChild, sEvent, sValue, sParent, sClass

		'Get the current row from the region variable
		iRow = Me.iRow

		'Child Object Class
		sChild = Data.Item(iRow & "|Child")
		'Event to be performed on Child/Parent Class
		sEvent = Data.Item(iRow & "|Event")
		'Parent Object Class
		sParent = Data.Item(iRow & "|Parent")
		'Value the child/parent class will hold after row executes
		sValue = Data.Item(iRow & "|Value")	

		'If the event is CheckProperty, then verify if the supplied value
		'is in the correct format.
		'CheckProperty Values should always be in the below format:
		'	[property][value]
		If sEvent = "CheckProperty" Then
			Dim oMatches1, oMatches2

			'[ should appear twice in sValue
			Set oMatches1 = GetRegExpMatch("\[", sValue)
			'] should appear twice in sValue
			Set oMatches2 = GetRegExpMatch("\]", sValue)

			If oMatches1.Count >= 2 And oMatches2.Count >= 2 Then
				IsValueValid = True
			End If
			
			Exit Function			
		End If

		If Not sChild = "" Then
			sClass = sChild
		Else
			sClass = sParent
		End If

		'Currently, the validation is done for only a few objects.
		'This may be expanded upon in the next release.
		Select Case sClass
			Case "WebCheckBox"
				IsValueValid = (InStr(1, "ON, OFF", sValue) > 0)
			Case "Image", "Link", "WebButton", "WinButton"
				If Trim(sValue) = "" Then IsValueValid = True
			Case Else
				IsValueValid = True
		End Select

		'Report
		If Not IsValueValid Then
			Report micFail, "IsValueValid", "Invalid Value found on Row: " & iRow & _
				": " & sValue & ". " & TestData.sCurrentTest & " will now exit.", "", ""
		End If
	End Function

	'<comment>
	'	<name>
	'		Function IsItemExists
	'	</name>
	'	<summary>
	'		Verifies if the target object exists in the application
	'	</summary>
	'	<param name="iRow" type="Integer">
	'		Test case row
	'	</param>
	'	<return type="Boolean">
	'		True: Object is found
	'	</return>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'</comment>
	Private Function IsItemExists(iRow)	'As Boolean
		Dim bExists, sClass

		IsItemExists = False

		'If a Child Object is not supplied then, target class is a parent
        sClass = Data.Item(iRow & "|Child")
		If sClass = "" Then
			sClass = Data.Item(iRow & "|Parent")
		End If

		'Execute the Level
		'bExists = True when the object exists
		Execute "bExists = " & oLevels.Item(iRow)

        'Report
		If Not bExists Then
			Report micFail, "Step " & iRow & "- IsExists", sClass & _
				" does not exist.", "", ""
		Else
			Report micPass, "Step " & iRow & "- IsExists", sClass & _
				" exists.", "", ""
			IsItemExists = True
		End If
	End Function

	'<comment>
	'	<name>
	'		Function InitIE
	'	</name>
	'	<summary>
	'		Initializes a Browser (AUT) for execution.
	'	</summary>
	'	<param name="iRow" type="Integer">
	'		Test case row
	'	</param>
	'	<remarks>
	'		Concepts in this method are also demonstrated in the article
	'		Working with Multiple Browser Applications on RelevantCodes.com:
	'		http://relevantcodes.com/qtp-working-with-multiple-browser-applications-revised/
	'	</remarks>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'	<seealso>
	'		AlertTerminate
	'	</seealso>
	'</comment>
	Private Sub InitIE(iRow)
		Dim oIE, sParentDescription, lngHwnd

		On Error Resume Next

			Set oIE = CreateObject("InternetExplorer.Application")
			lngHwnd = oIE.HWND
            
			'If Internet Explorer is not installed then, Error
			If Err.Number <> 0 Then
				AlertTerminate micFail, "InternetExplorer Is Not Installed", _
					"Please install Internet Explorer before proceeding with " & _
					"Relevant Codes [1] One.", vbCritical
			End If
			
		On Error Goto 0

        'Holds the name of the parent in "Description" Column of the spreadsheet
		sParentDescription = Data.Item(iRow & "|Description")

		'Report
        Report micInfo, "New Browser", "New browser opened: " & sParentDescription, "", ""

		On Error Resume Next
		
			With oIE
                .Visible = True
				.MenuBar = 0

                'If a value (URL) for the launch instance is specified, then navigate to the
				'specified location. Else, navigate to a blank page.
				If Data(iRow & "|Value") <> "" Then
					.Navigate2 Data(iRow & "|Value")
				Else
					.Navigate2 "about:blank"
				End If

				'Maximize the IE Window
				Window("hwnd:=" & .HWND).Maximize

				'If CStr(Split(Environment.Value("ProductVer"), ".")(0)) = "10" Then
				If Not Browser("hwnd:=" & .HWND).Exist(0) Then
					Dim oDesc, oBase, ix, lngHwndTest, lngHwndNative

					Set oDesc = Description.Create
					oDesc("micclass").Value = "Browser"
	
					Set oBase = Desktop.ChildObjects(oDesc)
	
                    For ix = 0 to oBase.Count - 1
						lngHwndTest = oBase(ix).GetROProperty("hwnd")
	
						Do
							Err.Clear
							lngHwndNative = Browser("hwnd:=" & lngHwndTest).Object.hwnd

							If lngHwndNative = .HWND Then
								lngHwnd = lngHwndTest
								Exit Do
							End If
						Loop Until Err.Number = 0
					Next
				End If

                'IE Window will not be resizable
				.Resizable = 0

				'Add the newly launched Browser to the region level scripting.dictionary
				If Not dicHWND.Exists(sParentDescription) Then dicHWND.Add sParentDescription, "hwnd:=" & lngHwnd

				'Set the Region level variable
				Me.sParentDescription = sParentDescription
			End With

			'Release instance
			'From now onwards, the description stored in dicHWND will be used
			Set oIE = Nothing

		On Error Goto 0
	End Sub

	'<comment>
	'	<name>
	'		Function InitWin
	'	</name>
	'	<summary>
	'		Initializes a Window (AUT) for execution
	'	</summary>
	'	<param name="iRow" type="Integer">
	'		Test case row
	'	</param>
	'	<remarks>
	'		Concepts in this method are also demonstrated in the article
	'		Working with Multiple Windows Applications on RelevantCodes.com:
	'		http://relevantcodes.com/qtp-working-with-multiple-windows-applications/
	'	</remarks>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'</comment>
	Private Sub InitWin(iRow)
		Dim sParentDescription, sValue, oDesc, oParent, mHwndDict, x, iTimeElapsed, lngHwnd

		'Description of the Window defined in the Excel book
		sParentDescription = Data.Item(iRow & "|Description")

		'Value the child/parent class will hold after row executes
		sValue = Data.Item(iRow & "|Value")

		On Error Resume Next

			'Description Object
			Set oDesc = Description.Create
			'Collection of Description Object
			Set oParent = Desktop.ChildObjects(oDesc)

			'Will hold the properties of all open windows
			Set mHwndDict = CreateObject("Scripting.Dictionary")
		
			For x = 0 to oParent.Count - 1
				mHwndDict.Add oParent(x).GetROProperty("hwnd"), x
			Next

			'Launch Application
			SystemUtil.Run sValue

			'Search for a new open window, which will be our target AUT
            Do
				Set oParent = Desktop.ChildObjects(oDesc)
				'Loop through all elements of the collection until an element that does not
				'exist is found.
				For x = 0 to oParent.Count - 1
					Select Case oParent(x).GetTOProperty("micclass")
						Case "Window", "Dialog"
							If Not mHwndDict.Exists(oParent(x).GetROProperty("hwnd")) Then
								lngHwnd = oParent(x).GetROProperty("hwnd")
								Exit Do
							End If
					End Select
				Next
				Wait(1)
				iTimeElapsed = iTimeElapsed + 1
			Loop Until iTimeElapsed = 30

			'Release instances of created objects
			Set oDesc = Nothing
			Set oParent = Nothing
			Set mHwndDict = Nothing

		On Error Goto 0

		'Add the newly launched Window to the region level scripting.dictionary
		If Not dicHWND.Exists(sParentDescription) Then dicHWND.Add sParentDescription, "hwnd:=" & lngHwnd

		'Set the Region level variable to the variable added to dicHWND
		Me.sParentDescription = sParentDescription
	End Sub

	'<comment>
	'	<name>
	'		Function GetRegExpMatch
	'	</name>
	'	<summary>
	'		Runs a RegExp match on a given string using a supplied pattern
	'	</summary>
	'	<param name="sPattern" type="Text">
	'		Pattern to execute on sString
	'	</param>
	'	<param name="sString" type="Text">
	'	</param>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'</comment>
	Private Function GetRegExpMatch(sPattern, sString)	'As Object
		Dim oRegExp
		
		Set oRegExp = New RegExp
		oRegExp.Global = True
		oRegExp.IgnoreCase = True
		oRegExp.Pattern = sPattern
		
		Set GetRegExpMatch = oRegExp.Execute(sString)
	End Function
	
	'<comment>
	'	<name>
	'		Sub UnloadApplications
	'	</name>
	'	<summary>
	'		Closes all open AUTs
	'	</summary>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'	<seealso>
	'	</seealso>
	'</comment>
	Private Sub UnloadApplications()
		Dim oKey, lngHwnd

		On Error Resume Next

			If IsObject(dicHWND) Then
				If Not dicHWND Is Nothing Then
					For Each oKey in dicHWND.Keys
						lngHwnd = Split(dicHwnd.Item(oKey), ":=")(1)
						If Window("hwnd:=" & lngHwnd).Exist(0) Then
							SystemUtil.CloseProcessByHwnd lngHwnd
						End If
					Next
				End If
			End If

		On Error Goto 0
	End Sub

	'<comment>
	'	<name>
	'		 Sub UnloadSettings
	'	</name>
	'	<summary>
	'		Unloads all settings created in the region
	'	</summary>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'	<seealso>
	'		UnloadApplications
	'		ReleaseContext
	'	</seealso>
	'</comment>
	Private Sub UnloadSettings()
		On Error Resume Next

			'Close all open applications
            UnloadApplications

			'Release the region level scripting.dictionary
			ReleaseContext

			'Release the parent level scripting.dictionary
			dicHWND.RemoveAll
			Set dicHWND = Nothing
			
		On Error Goto 0
	End Sub

	'<comment>
	'	<name>
	'		Sub ReleaseContext
	'	</name>
	'	<summary>
	'		Releases the region level scripting.dictionary
	'	</summary>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'	<seealso>
	'		Property Get oLevel
	'	</seealso>
	'</comment>
	Private Sub ReleaseContext()
		On Error Resume Next

			oLevels.RemoveAll
			oLevels = Nothing

		On Error Goto 0
	End Sub

	'<comment>
	'	<name>
	'		Get iLevels
	'	</name>
	'	<summary>
	'		Number of Levels to be created
	'	</summary>
	'	<return type="Integer">
	'		
	'	</return>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'	<seealso>
	'		
	'	</seealso>
	'</comment>
    Private Property Get iLevels() 'As Integer
		iLevels = Data.Count / 5
	End Property

	'<comment>
	'	<name>
	'		Let oLevels
	'	</name>
	'	<summary>
	'		Scripting.Dictionary Object that holds all the object hierarchies
	'		to be executed.
	'	</summary>
	'	<param name="Val" type="Object">
	'	</return>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'	<seealso>
	'	</seealso>
	'</comment>
	Private o_Levels
	Private Property Let oLevels(ByVal Val)
		Set o_Levels = Val
	End Property

	'<comment>
	'	<name>
	'		Get oLevels
	'	</name>
	'	<summary>
	'		Scripting.Dictionary Object that holds all the object hierarchies
	'		to be executed.
	'	</summary>
	'	<return type="Scripting.Dictionary">
	'	</return>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'	<seealso>
	'	</seealso>
	'</comment>
	Private Property Get oLevels() 'As Object
		Set oLevels = o_Levels
	End Property	
End Class
