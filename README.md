Build CouchDB
=============

Build CouchDB is a wrapper or master project which pulls in, from official
sources, CouchDB plus all of its dependencies. It is the most straightforward
and reliable procedure to build official CouchDB releases from source.

Build CouchDB builds an isolated, independent server. You do not need
administrator access to run it. You can run several couches (for example, 0.10,
0.11, 1.0 releases) side-by-side.

## Supported Platforms

Build CouchDB is developed and tested on the following operating systems:

 * Ubuntu 10.04 LTS (Lucid Lynx)
 * Ubuntu 9.10 (Karmic Koala)
 * Fedora 13
 * Apple OSX

The following systems are planned for support in the near future:

 * MS Windows Vista, Windows 7

## Requirements

You need only a few packages provided by the operating system. Copy and paste
the commands below.

On Ubuntu and Debian:

    sudo apt-get install make gcc zlib1g-dev libssl-dev libreadline5-dev bison rake

On Fedora:

    sudo yum install gcc gcc-c++ libtool libcurl-devel \
                     zlib-devel openssl-devel rubygem-rake

On OSX, install XCode.

## Getting the Code

You will need the Git tool. Check out the code and pull in the third-party
submodules.

    git clone git://github.com/jhs/build-couchdb
    cd build-couchdb
    git submodule init
    git submodule update

## How to Build CouchDB

Just run Rake.

    rake

CouchDB and all its dependencies will install in the `build/`. To uninstall,
simply delete that directory.

## Usage

It's CouchDB! Just type `couchdb`. (But remember the path)

    $ build/bin/couchdb
    Apache CouchDB 0.12.0aa63efb6-git (LogLevel=info) is starting.
    Apache CouchDB has started. Time to relax.
    [info] [<0.33.0>] Apache CouchDB has started on http://127.0.0.1:5984/

You can of course call it by absolute path. If your username is `amit` and you
checked out the code in your home directory, you would run:

    /home/amit/build-couchdb/build/bin/couchdb

## Conveniently Add CouchDB to the PATH

The `env` task will output a script which will add this CouchDB build to your
path. Then you can simply type `couchdb`. To load these settings into your
current shell, run:

    eval `rake env --silent`

vim: tw=80
