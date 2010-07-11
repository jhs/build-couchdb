#!/bin/echo Must not be run as a command, instead try: .
#
# Activate the CouchDB environment. This script is idempotent and runs silently when not connected to a terminal.
#

this_file="$BASH_SOURCE"
if [ -z "$this_file" ]; then
    this_file="$0"
fi

# Set this for ruby-inabox to find this project.
project_parent=$(dirname "$this_file")
ruby_env_sh="$project_parent/dependencies/ruby-inabox/env.sh"
unset this_file

# TODO: The idea here is, if Rake is available from the system, just skip the Ruby build.
#       For now, this just wraps ruby-inabox since that will call the Rake task.
. "$ruby_env_sh"
unset ruby_env_sh

# vim: sts=4 sw=4 et
