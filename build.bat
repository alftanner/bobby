@echo off

odin build src -microarch:generic -out:bobby.exe -o:speed -resource:res/main.rc -vet -subsystem:windows
