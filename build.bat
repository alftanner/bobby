@echo off

odin build src -microarch:generic -out:BobbyCarrot.exe -o:speed -resource:res/main.rc -vet -subsystem:windows
