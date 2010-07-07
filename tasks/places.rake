DEPS = "#{HERE}/dependencies"       unless Kernel.const_defined? 'DEPS'
BUILD = "#{HERE}/ruby-inabox/build" unless Kernel.const_defined? 'BUILD'
JS_LIB = "#{BUILD}/bin/js-config"   unless Kernel.const_defined? 'JS_LIB'
ERL_BIN = "#{BUILD}/bin/erl"        unless Kernel.const_defined? 'ERL_BIN'

PIDS = "#{BUILD}/var/run/couchdb" unless Kernel.const_defined? 'PIDS'
directory PIDS

AUTOCONF_213 = "#{BUILD}/bin/autoconf2.13" unless Kernel.const_defined? 'AUTOCONF_213'
AUTOCONF_259 = "#{BUILD}/bin/autoconf2.59" unless Kernel.const_defined? 'AUTOCONF_259'
