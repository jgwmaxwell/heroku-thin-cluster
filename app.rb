require 'sinatra'

class App < Sinatra::Base

    get '/' do
        @title = "This is the title!\n Hello there World!"
        erb :index
    end

end