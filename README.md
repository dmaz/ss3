<pre>
- windows
bmk makeapp -a -r -g x86 -t console ss3.bmx

- linux / mac
bmk makeapp -a -r -t console ss3.bmx

Usage: ss3
        Takes a newline delimited stdin of png/jpg paths and creates a sprite sheet and index.
        Lines starting with a "!" will be read as options below and should be in the form of

        !sheet_width=2048\n

        Invalid paths or files that don't exist will be skipped or will use defaultimg.png
        if located in the same directory as the ss3 executable.

options:
        !sheet_max_width=2048
        !sheet_max_height=2048
        !sheet_width=0 (if width or height 0, width and height will be auto calculated.)
        !sheet_height=0
        !sheet_quality=75
        !sheet_path=
        !sprite_width=64
        !sprite_height=64
        !sprite_resize=1
</pre>        
