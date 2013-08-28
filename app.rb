require 'sinatra'

class Game < Sinatra::Application

  get '/' do
    erb :board
  end
end


