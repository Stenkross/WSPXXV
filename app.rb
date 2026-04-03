require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative './model.rb'

enable :sessions

before do
  if session[:user_id]
    @user = get_user_id(session[:user_id])
  else
    @user = nil
  end
end

#before do
#  if session[:login_attempt] == nil
#    session[:login_attempt] = []
#  end 
#end 

def re_login
  halt redirect('/PictureHold/account/login') unless @user
end

get '/PictureHold/home' do
  @home = true
  @pictures = get_all_pics
  @comments = groupe_comments
  slim(:homepage)
end

get '/PictureHold/upload' do
  re_login
  slim(:upload)
end 

get '/PictureHold/account/create' do
  slim(:create)
end

get '/PictureHold/account/login' do
  slim(:login)
end 

get '/PictureHold/:id/edit' do
  id = params[:id]
  @selected_pic = get_pic_id(id)

  if @user["id"] != 1
    halt "No access" unless @selected_pic["user_id"] == @user["id"]
  end
 
  slim(:edit)
end 

get '/search' do
  query = params[:q] || ""
  category = params[:kategori] || ""

  @pictures = search_pic(query, category)

  @comments = groupe_comments

  @home = true
  slim(:homepage)
end

get '/logout' do
  session.clear
  redirect '/PictureHold/account/login'
end 

post '/register' do
  username = params["username"]
  password = params["password"]
  password_confirm = params["confirm_password"]

  halt "Tomma fält" if username.to_s.strip == "" || password.to_s.strip == ""
  
  if !user_exist_already(username)
    if password == password_confirm
      create_user(username, password)
      redirect('/PictureHold/home')
    else
      halt "Lösenorden matchar inte"
    end 
  else 
    halt "Användarnamn finns redan"
  end
  redirect('/PictureHold/home')
end 

post '/login' do
  username = params["username"]
  password = params["password"]

  user_id = authenticate(username, password)

  if user_id
    session[:user_id] = user_id
    redirect('/PictureHold/home')
  else
    halt "Fel användarnamn eller lösenord"
  end
end

post '/PictureHold/:id/delete' do
  re_login
  id = params[:id]
  picture = get_pic_id(id)

  if @user["id"] != 1
    halt "No access" unless picture["user_id"] == @user["id"]
  end
  delete_picture(id)
  redirect('/PictureHold/home')
end

post '/PictureHold/:id/delete_com' do
  if @user["id"] != 1
    halt "No access"
  end
  
  delete_comment(params[:id])
  redirect('/PictureHold/home')
end

post '/PictureHold/:id/update' do
  re_login
  
  pic_id = params[:id]
  new_name = params[:namez]
  new_kat_lag = params[:"kat-lage"]
  
  new_categories = params["categories"] || []

  update_picture(pic_id, new_name, new_kat_lag, new_categories)
  
  redirect('/PictureHold/home')
end

post '/PictureHold/upload' do
  re_login
  halt "Tomt namn" if params[:namez].to_s.strip == ""
  halt "Ingen bild vald" unless params[:picture]
  
  up_name = params[:namez]
  up_kat_lag = params[:"kat-lage"]
  user_id = session[:user_id]
  categories = params["categories"] || []

  tempfile = params[:picture][:tempfile]
  filename = params[:picture][:filename].force_encoding("UTF-8")

  path = File.join(settings.public_folder, "uploaded_pictures", filename)

  File.open(path, "wb") do |f|
    f.write(tempfile.read)
  end

  create_picture(up_name, up_kat_lag, user_id, filename, categories)
  redirect('/PictureHold/home')
end

post "/comment" do 
  re_login
  pic_id = params[:picture_id]
  content = params[:content]
  user_id = session[:user_id]
  halt "Empty comment" if params[:content].to_s.strip == ""

  create_comment(pic_id, user_id, content)
  redirect('/PictureHold/home')
end 