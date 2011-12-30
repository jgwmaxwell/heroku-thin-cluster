require 'sinatra'
require 'syntaxi'
require 'mongoid'
Mongoid.load!("config/mongoid.yml")

class Snippet
  include Mongoid::Document
  include Mongoid::Timestamps
  
  
  field :id, type: String
  field :title, type: String
  field :body, type: String

  validates_presence_of :body
  validates_length_of :body, :minimum => 1

  Syntaxi.line_number_method = 'floating'
  Syntaxi.wrap_at_column = 80
  #Syntaxi.wrap_enabled = false

  def formatted_body
    replacer = Time.now.strftime('[code-%d]')
    html = Syntaxi.new("[code lang='ruby']#{self.body.gsub('[/code]',
    replacer)}[/code]").process
    "<div class=\"syntax syntax_ruby\">#{html.gsub(replacer, 
    '[/code]')}</div>"
  end
end

class App < Sinatra::Base


    get '/' do
      erb :new
    end
    
    #for blitz
    get '/mu-c9ac6757-c683d474-e22d5a21-e325d9fc' do
      '42'
    end
    
    # create
    post '/' do
      snippet = Snippet.new(:title => params[:snippet_title],
                             :body  => params[:snippet_body])
      if snippet.save
        redirect "/#{snippet.id}"
      else
        redirect '/'
      end
    end
    
    # show
    get '/:id' do
      @snippet = Snippet.find(params[:id])
      if @snippet
        erb :show
      else
        redirect '/'
      end
    end


end