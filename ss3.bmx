SuperStrict
Framework brl.Pixmap
Import BRL.Blitz
Import BRL.PNGLoader
Import BRL.JPGLoader
Import BRL.LinkedList
Import BRL.FileSystem
Import BRL.StandardIO
Import BRL.RamStream

Import "datestamp.c"
Import "standardin.c"
Extern
    Function datestamp:Int()
    Function stdinIsEmpty:Int()
    Function readStdinLine$z()
End Extern

Const docs:String = ..
"Usage: ss3~n"+..
"~tTakes a newline delimited stdin of png/jpg paths and creates a sprite sheet and index.~n"+..
"~tLines starting with a ~q!~q will be read as options below and should be in the form of~n"+..
"~n~t!sheet_width=2048\n~n"+..
"~n~tInvalid paths or files that don't exist will be skipped or will use defaultimg.png~n"+..
"~tif located in the same directory as the ss3 executable.~n"+..
"~noptions:~n"+..
"~t!sheet_max_width=2048~n"+..
"~t!sheet_max_height=2048~n"+..
"~t!sheet_width=0 (if width or height 0, width and height will be auto calculated.)~n"+..
"~t!sheet_height=0~n"+..
"~t!sheet_quality=75~n"+..
"~t!sheet_path=~n"+..
"~t!sprite_width=64~n"+..
"~t!sprite_height=64~n"+..
"~t!sprite_resize=1~n"+..
"~n"

'Incbin "defaultimg.png"

Local time:Int = MilliSecs()
Local ssMaxWidth:Int = 2048
Local ssMaxHeight:Int = 2048
Local ssWidth:Int = 0
Local ssHeight:Int = 0
Local ssQuality:Int = 75
local ssPath:String = ""

If Not stdinIsEmpty()
    Local a:String
    Repeat
        a = readStdinLine()
        If Not a Then Exit
        a = a.Trim()

        If a[0] = Asc("!") Then
            Local opt$[] = a.split("=")
            'Print "found opt: "+opt[0]
            If opt[0] = "!sheet_path" Then ssPath = String(opt[1])
            If opt[0] = "!sheet_quality" Then ssQuality = Int(opt[1])
            If opt[0] = "!sheet_max_width" Then ssMaxWidth = Int(opt[1])
            If opt[0] = "!sheet_max_height" Then ssMaxHeight = Int(opt[1])
            If opt[0] = "!sheet_width" Then ssWidth = Int(opt[1])
            If opt[0] = "!sheet_height" Then ssHeight = Int(opt[1])
            If opt[0] = "!sprite_width" Then TPic.boxWidth = Int(opt[1])
            If opt[0] = "!sprite_height" Then TPic.boxHeight = Int(opt[1])
            If opt[0] = "!sprite_resize" Then TPic.resize = Int(opt[1])
        Else
            TPic.Add a
        End If

    Forever
Else
    Print docs
    End
EndIf
Local readtime:Int = (MilliSecs()-time)

If(ssWidth < 1 and ssHeight < 1) ' autogen square texture
    Local size:Int = 128
    While size <= ssMaxWidth and size <= ssMaxHeight
        if TPic.DoesFit(size,size) then exit
        size :* 2
    Wend
    ssWidth = size
    ssHeight = size
elseif(ssWidth>0 and ssHeight<1) ' autogen height based on width
    local h:int = 128
    while h <= ssMaxHeight
        if TPic.DoesFit(ssWidth,h) then exit
        h :+ TPic.boxHeight
    wend
    ssHeight = h
EndIf
Local ss:TPixmap = CreatePixmap(ssWidth,ssHeight,PF_RGBA8888)

Local x:Int = 0
Local y:Int = 0
Local i:Int = 0
Local ds:Int = datestamp()
Local filename:String = "shot_"+i+"_"+ds+".jpg"
For Local p:TPic = EachIn TPic.list
    p.destFile = filename
    p.Draw ss,x,y

    x = x + p.boxWidth
    If x >= ssWidth
        x = 0
        y = y + p.boxHeight
        If y >= ssHeight
            SavePixmapJPeg ss,StripSlash(ssPath)+filename,ssQuality
            i :+ 1
            x = 0
            y = 0
            ss = CreatePixmap(ssWidth,ssHeight,PF_RGBA8888)
            filename = "shot_"+i+"_"+ds+".jpg"
        EndIf
    EndIf
Next

If y < ssHeight Then SavePixmapJPeg ss,StripSlash(ssPath)+"/"+filename,ssQuality

time = MilliSecs()-time
'TPic.WriteIndex("index.json","~n~qread_time~q:"+readtime+",~n~qtotal_time~q:"+time)
TPic.PrintIndex("~n~qread_time~q:"+readtime+",~n~qtotal_time~q:"+time)


Type rect
    Field x:Double
    Field y:Double
    Field w:Double
    Field h:Double
    Method set:rect(x:Int,y:Int,w:Int,h:Int)
        Self.x = x
        Self.y = y
        Self.w = w
        Self.h = h
        Return Self
    End Method
End Type


Type TPic
    Global list:TList = New TList
    Global count:Int = 0
    Global boxWidth:Int = 64
    Global boxHeight:Int = 64
    Global resize:Int = 1
    Global defaultImg:TPixmap = LoadPixmap("defaultimg.png")
    'Global defaultImg:TPixmap = LoadPixmap("incbin::defaultimg.png")


    Field link:TLink
    Field path:String
    Field sid:String
    Field pixmap:TPixmap
    Field x:Int
    Field y:Int
    Field destFile:String

    Function Add:TPic( path:String )
        Local p:TPic = New TPic
        p.path = path
        p.sid = StripAll(p.path)

        If Not Len(p.sid) Then Return Null
        
        If FileType(p.path)=1
            p.pixmap = LoadPixmap(p.path)
        Else
            If Not defaultImg
                Return Null
            EndIf
            p.pixmap = defaultImg
        EndIf

        p.link = list.AddLast(p)
        TPic.count = TPic.count + 1

        Return p
    End Function

    Function DoesFit:int( w:Int, h:Int )
        Return TPic.count <= Int(w/boxWidth) * Int(h/boxHeight)
    End Function

    Function PrintIndex( meta:String )
        Local lastFile:String
        Local isOpen:Int
        Local firstComma:String
        Print "{"
        Print "~qindex~q:["
        For Local p:TPic = EachIn TPic.list

           If p.destFile <> lastFile
                firstComma = ""
                If isOpen
                    Print "]"
                    Print "}"

                EndIf
                If isOpen Print ","
                Print "{"
                Print "~qfilename~q:~q"+p.destFile+"~q,"
                Print "~qdata~q:["
                isOpen = 1
            EndIf
            Local s:String = firstComma+"{~qid~q:"+ p.sid +",~qx~q:"+ p.x +",~qy~q:"+ p.y +"}"
            firstComma = ","
            Print s
            lastFile = p.destFile
        Next
        Print "]"
        Print "}"

        Print "],"
        Print meta
        Print "}"
    End Function

    Function WriteIndex( path:String, meta:String )
        Local index:TStream = WriteFile(path)
        Local lastFile:String
        Local isOpen:Int
        Local firstComma:String
        WriteString index,"{"
        WriteString index,"~qindex~q:["
        For Local p:TPic = EachIn TPic.list

           If p.destFile <> lastFile
                firstComma = ""
                If isOpen
                    WriteString index,"]"
                    WriteString index,"}"

                EndIf
                If isOpen WriteString index,","
                WriteString index,"{"
                WriteString index,"~qfilename~q:~q"+p.destFile+"~q,"
                WriteString index,"~qdata~q:["
                isOpen = 1
            EndIf
            Local s:String = firstComma+"{~qid~q:"+ p.sid +",~qx~q:"+ p.x +",~qy~q:"+ p.y +"}"
            firstComma = ","
            WriteString index,s
            lastFile = p.destFile
        Next
        WriteString index,"]"
        WriteString index,"}"

        WriteString index,"],"
        WriteString index,meta
        WriteString index,"}"
    End Function

    Method Draw( ss:TPixmap, x:Int, y:Int )
        Self.x = x
        Self.y = y
        Self.destFile = destFile

        Local destRect:rect = GetDestRect(1,0)
        If resize Then pixmap = ResizePixmap(pixmap,Int(destRect.w),Int(destRect.h))
        For Local xi:Int = -destRect.x Until boxWidth-destRect.x
            For Local yi:Int = -destRect.y Until boxHeight-destRect.y
                Local currentData:Byte Ptr = pixmap.PixelPtr(xi,yi)
                Local newData:Byte Ptr = ss.PixelPtr(xi+Int(destRect.x)+x,yi+Int(destRect.y)+y)
                newData[0] = currentData[0]
                newData[1] = currentData[1]
                newData[2] = currentData[2]
                newData[3] = currentData[3]
            Next
        Next
    End Method

    Method GetDestRect:rect( centerFill:Int, skip:Int )
        Local rtnVal:rect = New rect
        rtnVal.set(0,0,boxWidth,boxHeight)
        If skip Return rtnVal

        Local imgWidth:Double = pixmap.width
        Local imgHeight:Double = pixmap.Height
        Local containerWidth:Double = boxWidth
        Local containerHeight:Double = boxHeight

        Local imageAspectRatio:Double = imgWidth/imgHeight
        Local containerAspectRatio:Double = containerWidth/containerHeight

        If centerFill
            If containerAspectRatio < imageAspectRatio
                Local newWidth:Double = imgWidth * containerHeight / imgHeight
                Local center:Int = (containerWidth - newWidth)/2
                rtnVal.set(center,0,Int(newWidth), Int(containerHeight))
            Else
                Local newHeight:Double = imgHeight * containerWidth / imgWidth
                Local center:Int = (containerHeight - newHeight)/2
                rtnVal.set(0,center,Int(containerWidth), Int(newHeight))
            EndIf
        Else
            If containerAspectRatio > imageAspectRatio
                rtnVal.set(0,0,Int(imgWidth * containerHeight / imgHeight), Int(containerHeight))
            Else
                rtnVal.set(0,0,Int(containerWidth), Int(imgHeight * containerWidth / imgWidth))
            EndIf
        EndIf
        Return rtnVal
    End Method
End Type

