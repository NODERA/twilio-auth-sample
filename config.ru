require 'pp'
require 'uri'
require './app.rb'

enable :sessions, :logging

run Sinatra::Application