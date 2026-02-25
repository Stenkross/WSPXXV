require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative './model.rb'

enable :sessions

get '/PictureHold/home' do
  @pictures = db.execute("SELECT * FROM pictures")
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

post '/PictureHold/:id/delete' do
  id = params[:id]
  db.execute("DELETE from pictures WHERE id=?", [id])
  redirect('/PictureHold/home')
end 

get '/PictureHold/:id/edit' do
  id = params[:id]
  @selected_todo = db.execute("SELECT * FROM pictures WHERE id = ?", [id]).first
  slim(:edit)
end 

post '/PictureHold/:id/update' do 
  id = params[:id]
  new_name = params[:name]
  new_desc = params[:description]

  db.execute("UPDATE picture SET name = ?, description = ? WHERE id = ?", [new_name, new_desc, id])

  redirect '/'
end 
