# Real time fluid dynamics simulation

# Supported Platforms
This project supports the main 3 desktop platforms:
* Windows
* Linux
* MacOS

*Note* The project has only been tested on Linux and MacOS.

## Running preset scenes
If you have generated the approriate Makefiles on Linux or MacOs, you can try some predefined test scenes with `just`.
You can see a list of scenes with `just -l`.

*Note* There is a bug when you try to rerun a scene after running another, it will default back to the latest scene you have tried.
To fix this, you can delete the obj directory with `rm -rf build/build_files/obj` then regenerate the build files as detailed below.

## Building the project
### Linux Users (Recommended)
* CD into the build folder
* run `./premake5 gmake`
* CD back to the root
* run `make`
* you are good to go

### MacOS Users (Recommended)
* CD into the build folder
* run `./premake5.osx gmake`
* CD back to the root
* run `make`
* you are good to go

### VSCode Users (all platforms)
*Note* You must have a compiler toolchain installed in addition to vscode.

* Clone the project
* Open the folder in VSCode
* Run the build task ( CTRL+SHIFT+B or F5 )
* You are good to go

### Windows Users
There are two compiler toolchains available for windows, MinGW-W64 (a free compiler using GCC), and Microsoft Visual Studio
#### Using MinGW-W64
* Double click the `build-MinGW-W64.bat` file
* CD into the folder in your terminal
  * if you are usiing the W64devkit and have not added it to your system path environment variable, you must use the W64devkit.exe terminal, not CMD.exe
  * If you want to use cmd.exe or any other terminal, please make sure that gcc/mingw-W64 is in your path environment variable.
* run `make`
* You are good to go

##### Note on MinGW-64 versions
Make sure you have a modern version of MinGW-W64 (not mingw).
The best place to get it is from the W64devkit from
https://github.com/skeeto/w64devkit/releases
or the version installed with the raylib installer
###### If you have installed raylib from the installer
Make sure you have added the path

`C:\raylib\w64devkit\bin`

To your path environment variable so that the compiler that came with raylib can be found.

DO NOT INSTALL ANOTHER MinGW-W64 from another source such as msys2, you don't need it.

#### Microsoft Visual Studio
* Run `build-VisualStudio2022.bat`
* double click the `.sln` file that is generated
* develop your game
* you are good to go

### Output files
The built code will be in the bin dir

