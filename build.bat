@echo off

odin build . -microarch:generic -out:bobby.exe -o:speed -resource:res/main.rc -vet -subsystem:windows
