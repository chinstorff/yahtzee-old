require 'grape'
require 'data_mapper'
require 'dm-sqlite-adapter'
require 'yahtzee'

DataMapper.setup(:default, 'sqlite::memory:')

class YahtzeeGame
  include DataMapper::Resource

  property :id, Serial
end

class API < Grape::API
  version 'v1.1', :using => :header, :vendor => :yahtzee

  get :start do
    @game = Yahtzee::Controller.new
  end
  
  get :continue do
    
  end
end
