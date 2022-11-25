@echo off

odin build . -microarch:generic -out:bobby.exe -o:speed -resource:res/rc.rc -vet -subsystem:windows
