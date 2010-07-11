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

On Ubuntu and Debian:

    sudo apt-get install make gcc zlib1g-dev libssl-dev libreadline5-dev bison ruby

On OSX, install XCode.

## Getting the Code

You will need the Git tool. Check out the code and pull in the third-party
submodules.

    git clone git://github.com/jhs/build-couchdb
    cd build-couchdb
    git submodule init
    git submodule update

## How to Build CouchDB

Since CouchDB will be built and installed in an isolated, private location, you
must set several environment variables to access it, the shell search path,
Ruby gems, and Heaven knows what else. All of this is handled through one shell
script, `env.sh`, which has the following properties.

 * If CouchDB has not yet been built, it will kick off the process.
 * It is idempotent. Source it whenever you like.

In other words, to build CouchDB, run

    . ./env.sh

That will set up the environment with the Bash script, then drop into your
normal shell, with the path and other settings intact.

CouchDB and all its dependencies will be installed in `build/`. To
uninstall, simply delete that directory.

## Usage

It's CouchDB! Just type `couchdb`.

    $ couchdb
    Apache CouchDB 0.12.0aa63efb6-git (LogLevel=info) is starting.
    Apache CouchDB has started. Time to relax.
    [info] [<0.33.0>] Apache CouchDB has started on http://127.0.0.1:5984/

vim: tw=80
