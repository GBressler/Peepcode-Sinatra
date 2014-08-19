require 'rubygems'
require 'sinatra'
require 'adserver.rb'

set :environment, :production
set :run, false

run Sinatra::Application
