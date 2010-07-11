DEPS = "#{HERE}/dependencies"       unless Kernel.const_defined? 'DEPS'
RUBY_BUILD = "#{DEPS}/ruby-inabox/build" unless Kernel.const_defined? 'BUILD'
BUILD = "#{HERE}/build"             unless Kernel.const_defined? 'BUILD'
JS_LIB = "#{BUILD}/bin/js-config"   unless Kernel.const_defined? 'JS_LIB'
ERL_BIN = "#{BUILD}/bin/erl"        unless Kernel.const_defined? 'ERL_BIN'
ICU_BIN = "#{BUILD}/bin/icu-config" unless Kernel.const_defined? 'ICU_BIN'

PIDS = "#{BUILD}/var/run/couchdb" unless Kernel.const_defined? 'PIDS'
directory PIDS

AUTOCONF_213 = "#{RUBY_BUILD}/bin/autoconf2.13" unless Kernel.const_defined? 'AUTOCONF_213'
AUTOCONF_259 = "#{RUBY_BUILD}/bin/autoconf2.59" unless Kernel.const_defined? 'AUTOCONF_259'
