require 'rubygems'
require 'bundler'

Bundler.require(:default)

$port = ARGV.first
ROOT = File.expand_path(File.dirname(File.dirname(__FILE__)))
SERVERS = 3

require './app'

$servers = spawn("bundle exec thin start -R app.rb -s #{SERVERS} --socket #{ROOT}/tmp/thin.sock -e production")

# Because we need the servers to be fully loaded before we require the proxy script
# we need to let the Thin instances spin up before the file is required. Spawn returns
# before the servers are fully loaded, so lets have the app sleep until they are finished
# loading.
#
# This is a hacky way to do it, sure, but it is also deeply simple, and thus ideal for this
# basic example.
#
# Of course in a production application we would need to monitor each of these instances
# so we can restart them if they crash etc, etc etc
sleep 10
require './proxy'

# Start proxy
BalancingProxy::Server.run