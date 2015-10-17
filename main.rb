require 'rubygems'
require 'sinatra'

set :sessions, true

name = ""

get '/form' do
  erb :form
end

post '/myaction' do
  name = params['username']
end

puts name