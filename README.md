Build CouchDB
=============

Build CouchDB is a wrapper or master project which pulls in, from official
sources, CouchDB plus all of its dependencies. It is the most straightforward
and reliable procedure to build official CouchDB releases from source.

Build CouchDB builds an isolated, independent server. You do not need
administrator access. You can run several couches (for example, 0.10, 0.11, 1.0
releases) side-by-side.

## Supported Platforms

Build CouchDB is developed and tested on the following operating systems:

 * Ubuntu 10.04 LTS (Lucid Lynx)
 * Apple OSX

The following systems are planned for support in the near future:

 * MS Windows Vista, Windows 7

## Requirements

You need only the basic GNU development toolchain.  These are often included in
modern operating systems.

The prepped zip and tar files are best for the vast majority of CouchDB usage.
However, to contribute to Build CouchDB development, you will want Git.

Installing Git is not covered here. On Linux, the OS package will do fine. On
OSX, I have no idea. On Windows, you can add git from within the "Devel" section
in the Cygwin "Select Packages" window. Or, consider using msysgit at
http://code.google.com/p/msysgit/downloads/list. Build CouchDB is confirmed to
work with the Git-1.7.0.2-preview20100309.exe version.

### Windows

Install [Cygwin][cygwin]

 1. Run the [Cygwin installer][dl_cygwin]
 2. Select "Install from Internet", then click Next
 3. Accept the default options by clicking Next
 4. Accept the default Local Package Directory by clicking Next
 5. Choose your Internet settings (Direct Connection is usually correct), then
    click Next
 6. Choose a download site (http://mirrors.kernel.org is usually fast),
    then click Next
 7. An information message about upgrades may pop up. If so, click OK.
 8. In the "Select Packages" window, in the "Devel" section, click the following
     1. "bison: A parser generator that is compatible with YACC"
     2. "gcc: C compiler upgrade helper"
     3. "make: The GNU version of the 'make' utility"
     3. "libncurses-devel: (devel) libraries for terminal handling"
     4. "ruby: Interpreted object-oriented scripting language"
     5. **Optional:** "git: Fast Version Control System - core files"
 9. Click Next to begin installation
 10. After installation is complete, click Finish
 11. Click the Start button. At the prompt, type "\cygwin\bin\ash" and press
     Enter.
 12. Type: `/usr/bin/rebaseall && exit`

 [cygwin]: http://www.cygwin.com/
 [dl_cygwin]: http://www.cygwin.com/setup.exe

### OSX

Install XCode.

### Ubuntu and Debian:

    sudo apt-get install make gcc zlib1g-dev libssl-dev libreadline5-dev bison ruby

## Getting the Code

### From the Prepped Download

Please see http://www.couch.io/get where the downloads do not exist yet.

### With Git

Check out the code and also the third-party submodules.

    git clone git://github.com/couchone/build-couchdb
    cd build-couchdb
    git submodule init
    git submodule update

## How to Build CouchDB

Since CouchDB will be built and installed in an isolated, private location, you
must set several environment variables to access it, the shell search path,
Ruby gems, and Heaven knows what else. All of this is handled through one shell
script, `ruby-inabox/env.sh`, which has the following properties.

 * If CouchDB has not yet been built, it will kick off the process.
 * It is idempotent. Source it whenever you like.

In other words, to build CouchDB, run

    . ruby-inabox/env.sh

CouchDB and all its dependencies will be installed in `build/`. To
uninstall, simply delete that directory.

## Usage

It's CouchDB! Just type `couchdb`.

    $ couchdb
    Apache CouchDB 0.12.0aa63efb6-git (LogLevel=info) is starting.
    Apache CouchDB has started. Time to relax.
    [info] [<0.33.0>] Apache CouchDB has started on http://127.0.0.1:5984/

vim: tw=80
