::@echo off
@echo off
set repoDir=C:\Users\Brandon\Documents\Git Repositories\hdmi_tx\
set projDir=C:\Users\Brandon\Documents\Development_Drive\DE10-Nano\091923_hdmi_v0\

echo Creating hard link to project QSF file...
set filename=de10_nano_standalone.qsf
mklink /h "%repoDir%synthesis\%filename%" "%projDir%%filename%"

echo Creating hard link to project timing constraints...
set filename=de10_nano_standalone.sdc
mklink /h "%repoDir%synthesis\%filename%" "%projDir%%filename%"

echo Creating hard link to Platform Designer .qsys file...
set filename=soc_system.qsys
mklink /h "%repoDir%synthesis\%filename%" "%projDir%%filename%"
echo Done creating link
pause

