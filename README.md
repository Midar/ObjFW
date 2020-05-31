ObjFW is a portable, lightweight framework for the Objective C language. It
enables you to write an application in Objective C that will run on any
platform supported by ObjFW without having to worry about differences between
operating systems or various frameworks that you would otherwise need if you
want to be portable.

See https://objfw.nil.im/ for more information.


<h1 id="table-of-contents">Table of Contents</h1>

 * [Installation](#installation)
   * [macOS and iOS](#macos-and-ios)
     * [Building as a framework](#building-framework)
     * [Using the macOS or iOS framework in Xcode](#framework-in-xcode)
     * [Broken Xcode versions](#broken-xcode-versions)
   * [Windows](#windows)
     * [Getting MSYS2](#getting-msys2)
     * [Updating MSYS2](#updating-msys2)
     * [Installing MinGW-w64 using MSYS2](#installing-mingw-w64)
     * [Getting, building and installing ObjFW](#steps-windows)
   * [Nintendo DS, Nintendo 3DS and Wii](#nintendo)
     * [Nintendo DS](#nintendo-ds)
     * [Nintendo 3DS](#nintendo-3ds)
     * [Wii](#wii)
   * [Amiga](#amiga)
 * [Writing your first application with ObjFW](#first-app)
 * [Bugs and feature requests](#bugs)
 * [Commercial use](#commercial-use)


<h1 id="installation">Installation</h1>

  To install ObjFW, just run the following commands:

    $ ./configure
    $ make
    $ make install

  In case you checked out ObjFW from the Fossil or Git repository, you need to
  run the following command first:

    $ ./autogen.sh

<h2 id="macos-and-ios">macOS and iOS</h2>

<h3 id="building-framework">Building as a framework</h3>

  When building for macOS or iOS, everything is built as a `.framework` by
  default if `--disable-shared` has not been specified to `configure`.

  To build for iOS, use something like this:

    $ clang="clang -isysroot $(xcrun --sdk iphoneos --show-sdk-path)"
    $ export OBJC="$clang -arch armv7 -arch arm64"
    $ export OBJCPP="$clang -arch armv7 -E"
    $ export IPHONEOS_DEPLOYMENT_TARGET="9.0"
    $ ./configure --prefix=/usr/local/ios --host=arm-apple-darwin

  To build for the iOS simulator, use something like this:

    $ clang="clang -isysroot $(xcrun --sdk iphonesimulator --show-sdk-path)"
    $ export OBJC="$clang -arch i386 -arch x86_64"
    $ export OBJCPP="$clang -arch i386 -E"
    $ export IPHONEOS_DEPLOYMENT_TARGET="9.0"
    $ ./configure --prefix=/usr/local/iossim --host=i386-apple-darwin

<h3 id="framework-in-xcode">Using the macOS or iOS framework in Xcode</h3>

  To use the macOS framework in Xcode, you need to add the `.framework`s to
  your project and add the following flags to `Other C Flags`:

    -fconstant-string-class=OFConstantString -fno-constant-cfstrings

<h3 id="broken-xcode-versions">Broken Xcode versions</h3>

  Some versions of Xcode shipped with a version of Clang that ignores
  `-fconstant-string-class=OFConstantString`. This will manifest in an error
  like this:

    OFAllocFailedException.m:94:10: error: cannot find interface declaration for
          'NSConstantString'
            return @"Allocating an object failed!";
                    ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    1 error generated.

  Unfortunately, there is no workaround for this other than to
  upgrade/downgrade Xcode or to build upstream Clang yourself.

  In particular, Xcode 11 Beta 1 to Beta 3 are known to be affected. While
  Xcode 11 Beta 4 to Xcode 11.3 work, the bug was unfortunately reintroduced in
  Xcode 11.4.1 and a fix is not expected before Xcode 11.6.

  You can get older versions of Xcode
  [here](https://developer.apple.com/download) by clicking on "More" in the
  top-right corner.

<h2 id='windows'>Windows</h2>

  Windows is only officially supported when following these instructions, as
  there are many MinGW versions that behave slightly differently and often
  cause problems.

<h3 id="getting-msys2">Getting MSYS2</h3>

  The first thing to install is [MSYS2](https://www.msys2.org) to provide a
  basic UNIX-like environment for Windows. Unfortunately, the binaries are not
  signed and there is no way to verify their integrity, so only download this
  from a trusted connection. Everything else you will download using MSYS2
  later will be cryptographically signed.

<h3 id="updating-msys2">Updating MSYS2</h3>

  The first thing to do is updating MSYS2. It is important to update things in
  a certain order, as `pacman` (the package manager MSYS2 uses, which comes
  from Arch Linux) does not know about a few things that are special on
  Windows.

  First, update the mirror list:

    $ pacman -Sy pacman-mirrors

  Then proceed to update the `msys2-runtime` itself, `bash` and `pacman`:

    $ pacman -S msys2-runtime bash pacman mintty

  Now close the current window and restart MSYS2, as the current window is now
  defunct. In a new MSYS2 window, update the rest of MSYS2:

    $ pacman -Su

  Now you have a fully updated MSYS2. Whenever you want to update MSYS2,
  proceed in this order. Notice that the first `pacman` invocation includes
  `-y` to actually fetch a new list of packages.

<h3 id="installing-mingw-w64">Installing MinGW-w64 using MSYS2</h3>

  Now it's time to install MinGW-w64. If you want to build 32 bit binaries:

    $ pacman -S mingw-w64-i686-clang mingw-w64-i686-gcc-objc

  For 64 bit binaries:

    $ pacman -S mingw-w64-x86_64-clang mingw-w64-x86_64-gcc-objc

  There is nothing wrong with installing them both, as MSYS2 has created two
  entries in your start menu: `MinGW-w64 Win32 Shell` and `MinGW-w64 Win64
  Shell`. So if you want to build for 32 or 64 bit, you just start the correct
  shell.

  Finally, install a few more things needed to build ObjFW:

    $ pacman -S autoconf automake fossil make

<h3 id="steps-windows">Getting, building and installing ObjFW</h3>

  Start the MinGW-w64 Win32 or Win64 Shell (depening on what version you want
  to build - do *not* use the MSYS2 Shell shortcut, but use the MinGW-w64 Win32
  or Win64 Shell shortcut instead!) and check out ObjFW:

    $ fossil clone https://objfw.nil.im objfw.fossil
    $ mkdir objfw && cd objfw
    $ fossil open ../objfw.fossil

  You can also download a release tarball if you want. Now go to the newly
  checked out repository and build and install it:

    $ ./autogen.sh && ./configure && make -j16 install

  If everything was successfully, you can now build projects using ObjFW for
  Windows using the normal `objfw-compile` and friends.

<h2 id="nintendo">Nintendo DS, Nintendo 3DS and Wii</h2>

  Download and install [devkitPro](https://devkitpro.org/wiki/Getting_Started).

<h3 id="nintendo-ds">Nintendo DS</h3>

  Follow the normal process, but instead of `./configure` run:

    $ ./configure --host=arm-none-eabi --with-nds

<h3 id="nintendo-3ds">Nintendo 3DS</h3>

  Follow the normal process, but instead of `./configure` run:

    $ ./configure --host=arm-none-eabi --with-3ds

<h3 id="wii">Wii</h3>

  Follow the normal process, but instead of `./configure` run:

    $ ./configure --host=powerpc-eabi --with-wii

<h2 id="amiga">Amiga</h2>

  Install [amiga-gcc](https://github.com/bebbo/amiga-gcc). Then follow the
  normal process, but instead of `./configure` run:

    $ ./configure --host=m68k-amigaos


<h1 id="first-app">Writing your first application with ObjFW</h1>

  To create your first, empty application, you can use `objfw-new`:

    $ objfw-new app MyFirstApp

  This creates a file `MyFirstApp.m`. The `-[applicationDidFinishLaunching]`
  method is called as soon as ObjFW finished all initialization. Use this as
  the entry point to your own code. For example, you could add the following
  line there to create a "Hello World":

    [of_stdout writeLine: @"Hello World!"];

  You can compile your new app using `objfw-compile`:

    $ objfw-compile -o MyFirstApp MyFirstApp.m

  `objfw-compile` is a tool that allows building applications and libraries
  using ObjFW without needing a full-blown build system. If you want to use
  your own build system, you can get the necessary flags from `objfw-config`.


<h1 id="bugs">Bugs and feature requests</h1>

  If you find any bugs or have feature requests, feel free to send a mail to
  js@nil.im!


<h1 id="commercial-use">Commercial use</h1>

  If for whatever reason neither the terms of the QPL nor those of the GPL work
  for you, a proprietary license for ObjFW including support is available upon
  request. Just write a mail to js@nil.im and we can find a reasonable solution
  for both parties.
