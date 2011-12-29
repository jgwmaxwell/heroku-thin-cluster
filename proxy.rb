#$:<< '../lib' << 'lib'


require 'em-proxy'
require 'uri'
require 'socket'

ROOT = "/home/john/TestRuby/testapp/"
SERVERS = 5
# = Balancing Proxy
#
# A simple example of a balancing, reverse/forward proxy such as Nginx or HAProxy.
#
# Given a list of backends, it's able to distribute requests to backends
# via different strategies (_random_, _roundrobin_, _balanced_), see <tt>Backend.select</tt>.
#
# This example is provided for didactic purposes. Nevertheless, based on some preliminary benchmarks
# and live tests, it performs well in production usage.
#
# You can customize the behaviour of the proxy by changing the <tt>BalancingProxy::Callbacks</tt>
# callbacks. To give you some ideas:
#
# * Store statistics for the proxy load in Redis (eg.: <tt>$redis.incr "proxy>backends>#{backend}>total"</tt>)
# * Use Redis' _SortedSet_ instead of updating the <tt>Backend.list</tt> hash to allow for polling from external process
# * Use <b>em-websocket</b>[https://github.com/igrigorik/em-websocket] to build a web frontend for monitoring
#
module BalancingProxy
  extend self

  BACKENDS = []
  0.upto(SERVERS - 1){|i| BACKENDS << {:socket => "#{ROOT}tmp/thin.#{i}.sock"}}

  # Represents a "backend", ie. the endpoint for the proxy.
  #
  # This could be eg. a WEBrick webserver (see below), so the proxy server works as a _reverse_ proxy.
  # But it could also be a proxy server, so the proxy server works as a _forward_ proxy.
  #
  class Backend

    attr_reader   :socket
    attr_accessor :load
    #alias         :to_s :url

    def initialize(options={})
      #raise ArgumentError, "Please provide a :url and :load" unless options[:url]
      @socket = options[:socket]
      #@url   = options[:url]
      @load  = options[:load] || 0
      #parsed = URI.parse(@url)
      #@host, @port = parsed.host, parsed.port
    end

    # Select backend: balanced, round-robin or random
    #
    def self.select(strategy = :balanced)
      @strategy = strategy.to_sym
      case @strategy
        when :balanced
          backend = list.sort_by { |b| b.load }.first
        when :roundrobin
          @pool   = list.clone if @pool.nil? || @pool.empty?
          backend = @pool.shift
        when :random
          backend = list[ rand(list.size-1) ]
        else
          raise ArgumentError, "Unknown strategy: #{@strategy}"
      end

      Callbacks.on_select.call(backend)
      yield backend if block_given?
      backend
    end

    # List of backends
    #
    def self.list
      @list ||= BACKENDS.map { |backend| new backend }
    end

    # Return balancing strategy
    #
    def self.strategy
      @strategy
    end

    # Increment "currently serving requests" counter
    #
    def increment_counter
      self.load += 1
    end

    # Decrement "currently serving requests" counter
    #
    def decrement_counter
      self.load -= 1
    end

  end

  # Callbacks for em-proxy events
  #
  module Callbacks
    extend  self

    def on_select
      lambda do |backend|
        backend.increment_counter if Backend.strategy == :balanced
      end
    end

    def on_connect
    end

    def on_data
      lambda do |data|
        data
      end
    end

    def on_response
      lambda do |backend, resp|
        resp
      end
    end

    def on_finish
      lambda do |backend|
        backend.decrement_counter if Backend.strategy == :balanced
      end
    end

  end

  # Wrapping the proxy server
  #
  module Server
    def run(host='0.0.0.0', port=9999)

      puts "Launching proxy at #{host}:#{port}...\n"

      Proxy.start(:host => host, :port => port, :debug => false) do |conn|

        Backend.select do |backend|

          conn.server backend, :socket => backend.socket

          conn.on_connect  &Callbacks.on_connect
          conn.on_data     &Callbacks.on_data
          conn.on_response &Callbacks.on_response
          conn.on_finish   &Callbacks.on_finish
        end

      end
    end

    module_function :run
  end

end

class Proxy
    def self.stop
      puts "Terminating ProxyServer"
      EventMachine.stop
      $servers.each do |pid|
        puts "Terminating webserver #{pid}"
        Process.kill('KILL', pid)
      end
    end
end