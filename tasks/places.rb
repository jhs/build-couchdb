DEPS = "#{HERE}/dependencies"
BUILD = ENV['prefix'] || "#{HERE}/build"
JS_LIB = "#{BUILD}/bin/js-config"
ERL_BIN = "#{BUILD}/bin/erl"
ICU_BIN = "#{BUILD}/bin/icu-config"
COUCH_BUILD = ENV['couchdb_build'] || BUILD
COUCH_BIN = "#{COUCH_BUILD}/bin/couchdb"
MANIFESTS = "#{BUILD}/manifests"

PIDS = "#{BUILD}/var/run/couchdb"

AUTOCONF_213 = "#{BUILD}/bin/autoconf2.13"
AUTOCONF_259 = "#{BUILD}/bin/autoconf2.59"
