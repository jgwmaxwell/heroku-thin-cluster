require 'rubygems'
require 'bundler'

Bundler.require(:default)

$port = ARGV.first
ROOT = File.expand_path(File.dirname(File.dirname(__FILE__)))
SERVERS = 4

#require './app'


# Run app on sockets thin.0.sock -> thin.2.sock
#$servers = []
$servers = spawn("bundle exec thin start -R app.rb -s #{SERVERS} --socket #{ROOT}/tmp/thin.sock -e production ")

#require './proxy'

# Start proxy
#BalancingProxy::Server.run