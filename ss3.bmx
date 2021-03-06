SuperStrict
Framework brl.Pixmap
Import BRL.Blitz
Import BRL.PNGLoader
Import BRL.JPGLoader
Import BRL.LinkedList
Import BRL.FileSystem
Import BRL.StandardIO
Import BRL.RamStream
Import BRL.Threads
'Import BaH.FreeImage

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
"~t!sheet_file_prefix=sheet~n"+..
"~t!sprite_width=64~n"+..
"~t!sprite_height=64~n"+..
"~t!sprite_resize=1~n"+..
"~t!circle_mask=0~n"+..
"~n"

'Incbin "defaultimg.png"

Local time:Int = MilliSecs()
Local ssMaxWidth:Int = 2048
Local ssMaxHeight:Int = 2048
Local ssWidth:Int = 0
Local ssHeight:Int = 0
Local ssQuality:Int = 75
local ssPath:String = ""
local ssFilePrefix:string = "sheet"

print "{"

try
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
                If opt[0] = "!sheet_file_prefix" Then ssFilePrefix = String(opt[1])
                If opt[0] = "!sheet_quality" Then ssQuality = Int(opt[1])
                If opt[0] = "!sheet_max_width" Then ssMaxWidth = Int(opt[1])
                If opt[0] = "!sheet_max_height" Then ssMaxHeight = Int(opt[1])
                If opt[0] = "!sheet_width" Then ssWidth = Int(opt[1])
                If opt[0] = "!sheet_height" Then ssHeight = Int(opt[1])
                If opt[0] = "!sprite_width" Then TPic.boxWidth = Int(opt[1])
                If opt[0] = "!sprite_height" Then TPic.boxHeight = Int(opt[1])
                If opt[0] = "!sprite_resize" Then TPic.resize = Int(opt[1])
                If opt[0] = "!circle_mask" Then TPic.circleMask = Int(opt[1])
            Else
                TPic.Add a
            End If

        Forever
    Else
        Print docs
        End
    EndIf

    'local threads:int
    'Repeat
    '    delay 100
    '    threads = 0
    '    For Local p:TPic = EachIn TPic.list
    '        if p.loaded = 0 then threads :+ 1
    '    Next
    '    comment threads
    'Until threads <= 0

    local ti:int 
    for local p:TPic = EachIn TPic.list
        comment ti
        if p.thread then WaitThread p.thread
        ti :+ 1
    Next
    

    Local readtime:Int = (MilliSecs()-time)
    'comment "added all sprites"

        'local ip:TPixmap
        'ip.writePixel(100,100,255)



    If(ssWidth < 1 and ssHeight < 1) ' autogen square texture
        Local size:Int = 128
        While size < ssMaxWidth and size < ssMaxHeight
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
    Local filename:String = ssFilePrefix+"_"+ds+"_"+i+".jpg"
    local path:string = ""
    if(ssPath <> "")
        path = StripSlash(ssPath) + "/"
    endif
    For Local p:TPic = EachIn TPic.list
        p.destFile = filename
        p.Draw ss,x,y

        x = x + p.boxWidth
        If x >= ssWidth
            x = 0
            y = y + p.boxHeight
            If y >= ssHeight
                SavePixmapJPeg ss,path+filename,ssQuality
                'TFreeImage.CreateFromPixmap(ss).convertTo24Bits().save path+filename,FIF_JPEG,ssQuality
                'TFreeImage.CreateFromPixmap(ss).convertTo24Bits().save path+filename,FIF_PNG
                i :+ 1
                x = 0
                y = 0
                ss = CreatePixmap(ssWidth,ssHeight,PF_RGBA8888)
                'comment "creating new sheet"
                filename = ssFilePrefix+"_"+ds+"_"+i+".jpg"
            EndIf
        EndIf
    Next

    If x > 0 or y > 0 Then SavePixmapJPeg ss,path+filename,ssQuality
    'If x > 0 or y > 0 Then TFreeImage.CreateFromPixmap(ss).convertTo24Bits().save path+filename,FIF_JPEG,ssQuality
    'If x > 0 or y > 0 Then TFreeImage.CreateFromPixmap(ss).convertTo24Bits().save path+filename,FIF_PNG

    time = MilliSecs()-time
    TPic.PrintIndex("~n~qread_time~q:"+readtime+",~n~qtotal_time~q:"+time)

catch ex:Object
    print "{~qsuccess~q:false,~n~qmsg~q:~q"+ex.ToString()+"~q}"
end try

function comment(txt:string)
    print "~qcomment~q:~q"+txt+"~q,"
end function

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

Function ThreadedLoad:Object(data:Object)
    local p:TPic = TPic(data)
    p.pixmap = LoadPixmap(p.path)
    p.loaded = 1
End Function

Type TPic
    Global list:TList = New TList
    Global count:Int = 0
    Global boxWidth:Int = 64
    Global boxHeight:Int = 64
    Global resize:Int = 1
    Global circleMask:Int = 0
    Global defaultImg:TPixmap = LoadPixmap("defaultimg.png")
    'Global defaultImg:TPixmap = LoadPixmap("incbin::defaultimg.png")


    Field link:TLink
    Field path:String
    Field sid:String
    Field pixmap:TPixmap
    Field x:Int
    Field y:Int
    Field destFile:String
    field thread:TThread
    field loaded:Int = 0

    Function Add:TPic( data:String )
        Local p:TPic = New TPic
        Local opt$[] = data.split(",")

        p.path = opt[0]
        if opt.length>1 then p.sid = opt[1].trim() else p.sid = StripAll(p.path)

        If Not Len(p.sid) Then Return Null
        
        If FileType(p.path)=1
            'p.pixmap = LoadPixmap(p.path)
            p.thread = CreateThread(ThreadedLoad,p)
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
        'Print "{"
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
            local error:string = ""
            Local s:String = firstComma+"{~qid~q:"+ p.sid +",~qx~q:"+ p.x +",~qy~q:"+ p.y +error+ "}"
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

    Method Draw( ss:TPixmap, x:Int, y:Int )
        'comment "Draw"
        Self.x = x
        Self.y = y
        Self.destFile = destFile
        local pixmap:TPixmap = self.pixmap

        if Not pixmap
            pixmap = LoadPixmap(path)
            if Not pixmap
                comment "load failed: "+path
                pixmap = defaultImg
            endif
        endif
        
        local maxDist:int = 0
        if self.circleMask maxDist = min(self.boxHeight/2,self.boxWidth/2) * min(self.boxHeight/2,self.boxWidth/2)
        
        Local destRect:rect = GetDestRect(1,0)
        If resize Then pixmap = ResizePixmap(pixmap,Int(destRect.w),Int(destRect.h))
        'comment "after ResizePixmap"

        For Local xi:Int = -destRect.x Until boxWidth-destRect.x
            For Local yi:Int = -destRect.y Until boxHeight-destRect.y
                if(xi<0 or yi<0 or xi>=pixmap.width or yi>=pixmap.height)
                    comment "src pixel coords out of bounds "+xi+":"+yi
                    continue
                endif

                local dxi:int = xi+Int(destRect.x)+x
                local dyi:int = yi+Int(destRect.y)+y
                if(dxi<0 or dyi<0 or dxi>=ss.width or dyi>=ss.height)
                    comment "dest pixel coords out of bounds "+dxi+":"+dyi
                    continue
                endif

                Local currentData:Byte Ptr = pixmap.PixelPtr(xi,yi)
                Local newData:Byte Ptr = ss.PixelPtr(dxi,dyi)
                newData[0] = currentData[0]
                newData[1] = currentData[1]
                newData[2] = currentData[2]
        '        newData[3] = currentData[3]
        '        local dist:int = getSqrDist(float(xi+destRect.x),float(yi+destRect.y),32,32)
        '        if maxDist and dist > maxDist then continue

        '        Local currentData:Byte Ptr = pixmap.PixelPtr(xi,yi)
        '        Local newData:Byte Ptr = ss.PixelPtr(xi+Int(destRect.x)+x,yi+Int(destRect.y)+y)
               
        '        local modifier:int = 1
        '        if maxDist and dist > maxDist*.98 then modifier = 2
               
        '        newData[0] = currentData[0] / modifier
        '        newData[1] = currentData[1] / modifier
        '        newData[2] = currentData[2] / modifier
        '        newData[3] = currentData[3] 
        '        'newData[3] = 255 
            Next
        Next
        'comment "after place"
        pixmap = null
    End Method

    Method GetDestRect:rect( centerFill:Int, skip:Int )
        'comment "start GetDestRect"
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
        'comment "end GetDestRect"
        Return rtnVal
    End Method
        
    method getSqrDist:Float( X1:Float, Y1:Float, X2:Float, Y2:Float )
        Local l1:Float = Abs(x1-x2)
        Local l2:Float = Abs(y1-y2)
        Return (l1*l1)+(l2*l2)
    End Method
    
End Type

