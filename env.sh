#!/bin/echo Must not be run as a command, instead try: .
#
# Activate the CouchDB environment. This script is idempotent and runs silently when not connected to a terminal.
#

# TODO: The idea here is, if Rake is available from the system, just skip the Ruby build.
#       For now, this just wraps ruby-inabox since that will call the Rake task.
. dependencies/ruby-inabox/env.sh

# vim: sts=4 sw=4 et
