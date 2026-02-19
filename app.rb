require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :sessions

DB_PATH = "db/todos.db"

def db
  return @db if @db

  @db = SQLite3::Database.new(DB_PATH)
  @db.results_as_hash = true

  return @db
end


get '/PictureHold/home' do


  slim(:homepage)
end 

get '/PictureHold/upload' do


  slim(:upload)
end

get '/PictureHold/account/create' do

  slim(:create)
end

get '/PictureHold/account/login' do

  slim(:login)
end 