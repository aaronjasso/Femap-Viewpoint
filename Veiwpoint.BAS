Sub Main
    Dim App As femap.model
    Set App = feFemap()
    '==================================================
    'Program to display current viewpoint parameters, round or copy them to the
    'clipboard, and optionally go to user-provided display parameters
    '
 	'Copyright (c) 2019 Aaron Jasso
	'
	'Licensed under the Apache License, Version 2.0 (the "License");
	'you may not use this file except in compliance with the License.
	'You may obtain a copy of the License at
	'
	'    http://www.apache.org/licenses/LICENSE-2.0
	'
	'Unless required by applicable law or agreed to in writing, software
	'distributed under the License Is distributed On an "AS IS" BASIS,
	'WITHOUT WARRANTIES Or CONDITIONS OF Any KIND, either express Or implied.
	'See the License For the specific language governing permissions And
	'limitations under the License.
    '
	'----------------------------------------------------------------------------------------------------
    'Changes in v3 (5.9.2019):
    '-Added ability to include view window size in the view definition. There is no
    '	built-in way to get the view size (the method should be feWindowGetSize,
    '	but it doesn't exist), so this macro uses a workaround. It saves a bitmap of
    '	the view, then interrogates the bitmap header to get its width and height,
    '	and then deletes the bitmap. This takes some time (around 2 seconds on my
    '	Windows 10 machine), so is not enabled by default. A checkbox on the GUI
    '	initiates the process. See note in GetViewSize function for more detail.
    '-Added input option for rounding decimal places. User can now choose the
    '	precision of the view definition
    '-Rearranged GUI to accommodate these new features
    '-Added some section header comments and reorganized the user dialog code
    '
    'Changes in v2 (8.16.2018):
    '-Changed "Cancel" button To "Close" To better reflect behavior
    '-Added refresh button to re-populate numbers if model is moved in background
    '
    'Note: The rounding value is validated, but the view input data is not.
    'Note: The documentation wants view orientation to be defined using the
    '	ViewOrient object, not the View object. As of v3, I do not see a way to
    '	input the three rotation angles used by this macro into the ViewOrient
    '	object. For now, this macro will rely on the backwards-compatibility of the
    '	View object.
    '
    '==================================================
    Dim rotX, rotY, rotZ As Double
    Dim centerX, centerY, centerZ As Double
    Dim mag As Double
    Dim viewID As Long
    Dim rc As Variant
    Dim vi As femap.View
    Set vi = App.feView
    Dim places As Integer
    Dim lines() As String
    Dim i As Integer

    places = 5	'number of decimals to display in current view parameters

    '==================================================
    'Get current view
    '==================================================
    lblGetView:
    rc = App.feAppGetActiveView(viewID)
    rc = vi.Get(viewID)

	rotX = Round(vi.rotation(0),places)
	rotY = Round(vi.rotation(1),places)
	rotZ = Round(vi.rotation(2),places)

	centerX = Round(vi.center(0),places)
	centerY = Round(vi.center(1),places)
	centerZ = Round(vi.center(2),places)

	mag = Round(vi.Magnification,places)

    '==================================================
	'Create user dialog
    '==================================================
	lblGetInput:
	Begin Dialog UserDialog 600,287,"Goto Viewpoint",.DialogFunc ' %GRID:10,7,1,1
		TextBox 50,56,40,14,.W	'Placeholder for width value, hidden in DialogFunc
		TextBox 50,77,40,14,.H	'Placeholder for height value, hidden in DialogFunc
		GroupBox 10,7,210,217,"Go To View",.GroupBox3
		TextBox 30,28,170,154,.gotoView,1
		PushButton 30,189,170,28,"Go To Here",.PushButton4
		GroupBox 10,231,210,49,"Rounding",.GroupBox1
		TextBox 20,252,30,14,.rnd
		text 60,245,60,28,"decimal place(s)",.Text2
		PushButton 120,245,90,28,"Round Now",.PushButton3
		GroupBox 230,7,190,273,"Current View",.GroupBox2
		TextBox 240,28,160,154,.CurrentViewText,2
		CheckBox 240,189,170,14,"Include View Size",.viewSize
		PushButton 240,210,170,28,"Copy to Clipboard",.PushButton2
		PushButton 240,245,170,28,"Refresh",.PushButton5
		GroupBox 430,7,160,175,"Format",.GroupBox4
		text 440,28,140,147,"X Rotation" & vbNewLine & "Y Rotation" & vbNewLine & "Z Rotation" & vbNewLine & vbNewLine & "X Center" & vbNewLine & "Y Center" & vbNewLine & "Z Center" & vbNewLine & vbNewLine & "Magnification" & vbNewLine & vbNewLine & "[View Width (px)" & vbNewLine & "View Height (px)]",.Text1
		text 430,182,150,49,"Note:  All coordinates are in the default ""0..Basic Rectangular"" coordinate system.",.note
		PushButton 430,238,160,35,"Close",.PushButton1
	End Dialog
	Dim dlg As UserDialog
	dlg.CurrentViewText = rotX & vbNewLine & rotY & vbNewLine & rotZ & vbNewLine & vbNewLine _
		& centerX & vbNewLine & centerY & vbNewLine & centerZ & vbNewLine & vbNewLine _
		& mag & vbNewLine
	'If dlg.W <> "" _
	'	And dlg.H <> "" Then
	If dlg.viewSize = 1 Then
		dlg.CurrentViewText = dlg.CurrentViewText & vbNewLine & dlg.W & vbNewLine & dlg.H
	End If
	'Dialog dlg

	If dlg.rnd = "" Then
		dlg.rnd = Str(1)
	End If

	rc = Dialog(dlg)
	'MsgBox("Return code is: " & rc,vbOkOnly,"Info")

	If rc = 5 Then 'close button
		Exit Sub
	ElseIf rc = 3 Then 'copy current to clipboard
		'copy stuff to clipboard
		Clipboard dlg.CurrentViewText
		Exit Sub
	ElseIf rc = 2 Then 'Round:  re-retrieve view, round numbers, update view window, and return to dialog
		If Not(IsNumeric(dlg.rnd)) _
			Or dlg.rnd < 0 Then
			MsgBox("You must enter a positive numeric value to round",vbInformation,"Input Error")
			GoTo lblGetInput
		End If
		rc = App.feAppGetActiveView(viewID)
    	rc = vi.Get(viewID)
		rotX = Round(vi.rotation(0),places)
		rotY = Round(vi.rotation(1),places)
		rotZ = Round(vi.rotation(2),places)
		centerX = Round(vi.center(0),places)
		centerY = Round(vi.center(1),places)
		centerZ = Round(vi.center(2),places)
		mag = Round(vi.Magnification,places)

		rotX = Round(rotX,Val(dlg.rnd))
		rotY = Round(rotY,Val(dlg.rnd))
		rotZ = Round(rotZ,Val(dlg.rnd))
		centerX = Round(centerX,Val(dlg.rnd))
		centerY = Round(centerY,Val(dlg.rnd))
		centerZ = Round(centerZ,Val(dlg.rnd))
		mag = Round(mag,Val(dlg.rnd))
		vi.rotation(0) = rotX
		vi.rotation(1) = rotY
		vi.rotation(2) = rotZ
		vi.center(0) = centerX
		vi.center(1) = centerY
		vi.center(2) = centerZ
		vi.Magnification = mag
		vi.Put(viewID)
		rc = App.feViewRegenerate(viewID)
		GoTo lblGetInput
	ElseIf rc = 1 Then 'goto input view parameters
		lines = Split(dlg.gotoView,vbNewLine)
		If UBound(lines) = -1 Then 'ensure array isn't empty
			Exit Sub
		End If
		For i = 0 To 2
			vi.rotation(i) = Val(lines(i))
			vi.center(i) = Val(lines(i+4))
		Next
		vi.Magnification = Val(lines(8))
		vi.Put(viewID)
		If UBound(lines) = 11 Then
			App.feWindowSetSize(0,0,0,lines(10),lines(11))
		End If
		rc = App.feViewRegenerate(viewID)
	ElseIf rc = 4 Then	'Refresh
		rc = App.feViewRegenerate(viewID)
		GoTo lblGetView
	End If

End Sub


Function dialogfunc(DlgItem As String, Action As Integer, SuppValue As Integer) As Boolean
    Select Case Action
    Case 1 ' Dialog box initialization
        'do things
        DlgVisible "W", False
        DlgVisible "H", False
    Case 2 ' Value changing or button pressed
        'do things
        'MsgBox("DlgItem is: " & DlgItem & vbNewLine _
        '	& "Action is: " & Action & vbNewLine _
        '	& "SuppValue is: " & SuppValue,vbOkOnly,"Info")
        If SuppValue = 1 Then
        	If DlgText("W") = "" _
        	And DlgText("H") = "" Then
        		Dim WH As Variant
        		WH = GetViewSize
        		DlgText "CurrentViewText", DlgText("CurrentViewText") & vbNewLine & WH(0) & vbNewLine & WH(1)
				DlgText "W", Trim(Str(WH(0)))
				DlgText "H", Trim(Str(WH(1)))
			Else
				DlgText "CurrentViewText", DlgText("CurrentViewText") & vbNewLine & DlgText("W") & vbNewLine & DlgText("H")
			End If
		ElseIf SuppValue = 0 Then
			Dim lines As Variant
			Dim viewData As String
			lines = Split(DlgText("CurrentViewText"),vbNewLine)
			For i = 0 To 8
				viewData = viewData & lines(i) & vbNewLine
			Next
			DlgText "CurrentViewText",viewData
        End If
    Case 3 ' TextBox or ComboBox text changed
        'do things
    Case 4 ' Focus changed
        'do things
    Case 5 ' Idle
        'do things
        Wait .1
    Case 6 ' Function key
        'do things
    End Select
End Function

Function GetViewSize As Variant
	'========================================
	'This function gets the width and height of the view pane.
	'
	'Copyright (c) 2019 Aaron Jasso
	'
	'Since this functionality is not available in the Femap API, it
	'uses a workaround. The function saves a bitmap file of the
	'current view to the %TEMP% directory, reads the image size
	'from the bitmap header, deletes the file, and returns the
	'size as an integer array with two variables: the width and
	'height (in that order)
	'
	'Saving a bitmap is time-consuming if the view pane is large, so
	'hopefully an '.feWindowGetSize' method is added to the API
	'soon. Alternatively, it *might* be faster to save a different
	'filetype? Bitmap headers are fairly easy to read so I didn't look
	'any further when writing this.
	'
	'Written by AMJ, 5.8.2019
	'========================================
	Dim App2 As femap.model
	Set App2 = feFemap()

	Dim rc As Variant

	Dim filename As String
	Dim i As Integer
	Dim warr(3), harr(3) As Integer
	Dim WH(1) As Integer

	filename = "FemapTempPic.bmp"
	ChDir Environ("temp")

	rc = App2.feFilePictureSave2(False,FPRG_WINDOW,FPM_BMP,filename)

	'Close #256
	Open filename For Binary As #256

		'Get width and height from file info header
		Seek #256,19
		For i = 0 To 3
			warr(i) =Asc(Input(1,#256))
		Next
		For i = 0 To 3
			harr(i) = Asc(Input(1,#256))
		Next

		For i = 0 To 3
			WH(0) = WH(0) + warr(i)*2^(i*8)
			WH(1) = WH(1) + harr(i)*2^(i*8)
		Next

	Close #256
	Kill filename

	GetViewSize = WH

End Function
