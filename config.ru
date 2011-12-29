require 'rubygems'
require 'bundler'

Bundler.require(:default)

require './app'
require './proxy'

# Run app on sockets thin.0.sock -> thin.2.sock
$servers = []
$servers << spawn("bundle exec thin start -R app.rb -s #{SERVERS} --socket tmp/thin.sock -e production ")

# Start proxy
BalancingProxy::Server.run