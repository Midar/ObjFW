Platforms
=========

ObjFW is known to work on the following platforms, but should run on many
others as well.


AmigaOS
-------

  * OS Versions: 3.1, 4.1 Final Edition Update 1
  * Architectures: m68k, PowerPC
  * Compilers: GCC 6.4.1b (amiga-gcc), GCC 8.3.0 (adtools)
  * Runtimes: ObjFW


Android
-------

  * OS Versions: 4.0.4, 4.1.2, 6.0.1
  * Architectures: ARMv6, ARMv7, ARM64
  * Compilers: Clang 3.3, Clang 3.8.0
  * Runtimes: ObjFW


Bare metal ARM Cortex-M4
------------------------

  * Architectures: ARMv7E-M
  * Compilers: Clang 3.5
  * Runtimes: ObjFW
  * Notes: Bootloader, libc (newlib) and possibly external RAM required


DOS
---

  * OS Versions: Windows XP DOS Emulation, DOSBox, MS-DOS 6.0, FreeDOS 1.2
  * Architectures: x86
  * Compilers: DJGPP GCC 4.7.3 (djdev204)
  * Runtimes: ObjFW


DragonFlyBSD
------------

  * OS Versions: 3.0, 3.3-DEVELOPMENT
  * Architectures: x86, x86_64
  * Compilers: GCC 4.4.7
  * Runtimes: ObjFW


FreeBSD
-------

  * OS Versions: 9.1-rc3, 10.0
  * Architectures: x86_64
  * Compilers: Clang 3.1, Clang 3.3
  * Runtimes: ObjFW


Haiku
-----

  * OS version: r1-alpha4
  * Architectures: x86
  * Compilers: Clang 3.2, GCC 4.6.3
  * Runtimes: ObjFW


iOS
---

  * Architectures: ARMv7, ARM64
  * Compilers: Clang
  * Runtimes: Apple


Linux
-----

  * Architectures: Alpha, ARMv6, ARMv7, ARM64, Itanium, m68k, MIPS (O32),
                   MIPS64 (N64), RISC-V 64, PowerPC, S390x, SuperH-4, x86,
                   x86_64
  * Compilers: Clang 3.0-10.0, GCC 4.6-10.0
  * Runtimes: ObjFW


macOS
-----

  * OS Versions: 10.5, 10.7-10.15, Darling
  * Architectures: PowerPC, PowerPC64, x86, x86_64
  * Compilers: Clang 3.1-10.0, Apple GCC 4.0.1 & 4.2.1
  * Runtimes: Apple, ObjFW


MorphOS
-------

  * OS Versions: 3.9-3.11
  * Architectures: PowerPC
  * Compilers: GCC 5.3.0, GCC 5.4.0
  * Runtimes: ObjFW
  * Notes: libnix and ixemul are both supported


NetBSD
------

  * Architectures: ARM, ARM (big endian, BE8 mode), MIPS (O32), PowerPC, SPARC,
                   SPARC64, x86, x86_64
  * Compilers: Clang 3.0-3.2, GCC 4.1.3 & 4.5.3 & 7.4.0
  * Runtimes: ObjFW


Nintendo 3DS
------------

  * OS Versions: 9.2.0-20E, 10.5.0-30E / Homebrew Channel 1.1.0
  * Architectures: ARM (EABI)
  * Compilers: GCC 5.3.0 (devkitARM release 45)
  * Runtimes: ObjFW
  * Limitations: No threads


Nintendo DS
-----------

  * Architectures: ARM (EABI)
  * Compilers: GCC 4.8.2 (devkitARM release 42)
  * Runtimes: ObjFW
  * Limitations: No threads, no sockets
  * Notes: File support requires an argv-compatible launcher (such as HBMenu)


OpenBSD
-------

  * OS Versions: 5.2-6.7
  * Architectures: MIPS64, PA-RISC, PowerPC, SPARC64, x86_64
  * Compilers: GCC 6.3.0, Clang 4.0
  * Runtimes: ObjFW


PlayStation Portable
--------------------

  * OS Versions: 5.00 M33-4
  * Architectures: MIPS (EABI)
  * Compiler: GCC 4.6.2 (devkitPSP release 16)
  * Runtimes: ObjFW
  * Limitations: No threads, no sockets


QNX
---

  * OS Versions: 6.5.0
  * Architectures: x86
  * Compilers: GCC 4.6.1
  * Runtimes: ObjFW


Solaris
-------

  * OS Versions: OpenIndiana 2015.03
  * Architectures: x86, x86_64
  * Compilers: Clang 3.4.2, GCC 4.8.3
  * Runtimes: ObjFW


Wii
---

  * OS Versions: 4.3E / Homebrew Channel 1.1.0
  * Architectures: PowerPC
  * Compilers: GCC 4.6.3 (devkitPPC release 26)
  * Runtimes: ObjFW
  * Limitations: No threads


Windows
-------

  * OS Versions: 98 SE, NT 4.0, XP (x86), 7 (x64), 8 (x64), 8.1 (x64), 10,
                 Wine (x86 & x64)
  * Architectures: x86, x86_64
  * Compilers: GCC 5.3.0 & 6.2.0 from msys2 (x86 & x64),
               Clang 3.9.0 from msys2 (x86),
               Clang 10.0 from msys2 (x86 & x86_64)
  * Runtimes: ObjFW


Others
------

Basically, it should run on any POSIX system to which GCC >= 4.6 or a recent
Clang version has been ported. If not, please send an e-mail with a bug report.

If you successfully ran ObjFW on a platform not listed here, please send an
e-mail to js@nil.im so it can be added here!

If you have a platform on which ObjFW does not work, please contact me as well!


Forwarding
==========

As forwarding needs hand-written assembly for each combination of CPU
architecture, executable format and calling convention, it is only available
for the following platforms (except resolveClassMethod: and
resolveInstanceMethod:, which are always available):

  * ARM (EABI/ELF, Apple/Mach-O)
  * ARM64 (ARM64/ELF, Apple/Mach-O)
  * MIPS (O32/ELF, EABI/ELF)
  * PowerPC (SysV/ELF, EABI/ELF, Apple/Mach-O)
  * SPARC (SysV/ELF)
  * SPARC64 (SysV/ELF)
  * x86 (SysV/ELF, Apple/Mach-O, Win32/PE)
  * x86_64 (SysV/ELF, Apple/Mach-O, Mach-O, Win64/PE)

Apple/Mach-O means both, the Apple ABI and runtime, while Mach-O means the
ObjFW runtime on Mach-O.
