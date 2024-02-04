
#net use W: /d
#net use X: /d

net use W: \\192.168.0.120\Volume_2 /user:aaron bartfast
net use X: \\192.168.0.122\MyBookLive /user:ahamilton 1-am-Havelock!

robocopy W:\Backups\MyBookLive\Public\public  X: /e /copy:dat /dcopy:T /r:30 /w:30 /LOG+:c:\robolog4.txt /ETA /BYTES /tee

CaliperCowboy2009!