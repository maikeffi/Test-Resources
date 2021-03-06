Option Explicit

'<comment>
'	<name>
'		AlertTerminate
'	</name>
'	<summary>
'		Alerts the user of a critical error
'	</summary>
'	<param name="intStatus" type="Integer">
'		Status of the step
'	</param>
'	<param name="sTitle" type="Text">
'		Step Name
'	</param>
'	<param name="sDetails" type="Text">
'		Step Details
'	</param>
'	<param name="vbButton" type="Integer Constant">
'		vbButton Constant
'	</param>
'	<author>
'		Kannan Maikeffi'	</author>
'	<seealso>
'		Public Sub Report
'	</seealso>
'</comment>
Public Sub AlertTerminate(ByVal intStatus, ByVal sTitle, ByVal sDetails, ByVal vbButton)
	Report intStatus, sTitle, sDetails, "", ""
	Execute "MsgBox sDetails, vbButton, sTitle"
	'ExitTest
End Sub


'<comment>
'	<name>
'		Sub Report
'	</name>
'	<summary>
'		Reports an execution step to the results log
'	</summary>
'	<param name="intStatus" type="Integer">
'		Status of the step
'	</param>
'	<param name="sStep" type="Text">
'		Step Name
'	</param>
'	<param name="sDetails" type="Text">
'		Step Details
'	</param>
'	<param name="sExpected" type="Text">
'		Expected Result
'	</param>
'	<param name="sActual" type="Text">
'		Actual Result
'	</param>
'	<author>
'		Kannan Maikeffi'	</author>
'</comment> 
Public Sub Report(ByVal intStatus, ByVal sStep, ByVal sDetails, ByVal sExpected, ByVal sActual)
	'Reporter.Filter = rfEnableAll

	If Not sExpected = "" And Not sActual = "" Then
		If intStatus = "" Then
			If sExpected = sActual Then intStatus = micPass
			If sExpected <> sActual Then intStatus = micFail
		End If
		
		sDetails = "&lt;" & _
					"<table border='1' style='font-family: Arial; font-size: 1em; text-align=center; border: 2px solid #111111;'>" & _
						"<tr style='font-weight:bold;'>" & _
							"<td>Details</td>" & _
							"<td>Expected</td>" & _
							"<td>Actual</td>" & _
						"</tr>" & _
						"<tr>" & _
							"<td>" & sDetails & "</td>" & _
							"<td>" & sExpected & "</td>" & _
							"<td>" & sActual & "</td>" & _
					"</tr>" & _
					"</table>" & _
				"&gt;"
	End If
	
	Reporter.ReportEvent intStatus, sStep, sDetails

	'Reporter.Filter = rfDisableAll
End Sub
