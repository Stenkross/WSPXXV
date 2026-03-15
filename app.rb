require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative './model.rb'

enable :sessions

get '/PictureHold/home' do
  @home = true
  @pictures = db.execute("SELECT * FROM pictures")
  @user = db.execute("SELECT * FROM usertabell WHERE id=?", session[:user_id]).first
  slim(:homepage)
end

get '/PictureHold/upload' do
  @user = db.execute("SELECT * FROM usertabell WHERE id=?", session[:user_id]).first
  slim(:upload)
end 

get '/PictureHold/account/create' do
  @user = db.execute("SELECT * FROM usertabell WHERE id=?", session[:user_id]).first
  slim(:create)
end

post '/register' do
  username = params["username"]
  password = params["password"]
  password_confirm = params["confirm_password"]

  result = db.execute("SELECT id FROM usertabell WHERE username=?", username)

  if result.empty?
    if password == password_confirm
      password_digest = BCrypt::Password.create(password)
      p password_digest
      db.execute("INSERT INTO usertabell(username, pwd_digest) VALUES (?,?)", [username, password_digest])
      redirect('/PictureHold/home')
    else
      direct('/PictureHold/account/create?error=user')
    end 
  else 
    direct('/PictureHold/account/create?error=user') 
  end 
  redirect('/PictureHold/home')
end 

get '/PictureHold/account/login' do
  @user = db.execute("SELECT * FROM usertabell WHERE id=?", session[:user_id]).first
  slim(:login)
end 

post('/login') do
  username = params["username"]
  password = params["password"]
  result=db.execute("SELECT id, pwd_digest FROM usertabell WHERE username=?",username)
  if result.empty?
    redirect('/PictureHold/account/login?error=user')
  end
  used_id = result.first["id"]
  pwd_digest = result.first["pwd_digest"]
  if BCrypt::Password.new(pwd_digest) == password
    session[:user_id] = used_id
    redirect('/PictureHold/home')
  else
    redirect('/PictureHold/account/login?error=password') 
  end
end

post '/PictureHold/:id/delete' do
  id = params[:id]
  db.execute("DELETE from pictures WHERE id=?", [id])
  redirect('/PictureHold/home')
end 

get '/PictureHold/:id/edit' do
  @user = db.execute("SELECT * FROM usertabell WHERE id=?", session[:user_id]).first
  id = params[:id]
  @selected_pic = db.execute("SELECT * FROM pictures WHERE id = ?", [id]).first
  slim(:edit)
end 

post '/PictureHold/:id/update' do 
  id = params[:id]
  new_name = params[:name]
  new_desc = params[:description]

  db.execute("UPDATE picture SET name = ?, description = ?, WHERE id = ?", [new_name, new_desc, id])
  redirect('/PictureHold/home')
end 

post '/PictureHold/upload' do
  up_name = params[:namez]
  up_kat= params[:kategori]
  up_kat_lag = params[:"kat-lage"]
  up_per = params[:user_id]
  tempfile = params[:picture][:tempfile]
  filename = params[:picture][:filename].force_encoding("UTF-8")

  path = File.join(settings.public_folder, "uploaded_pictures", filename)

  File.open(path, "wb") do |f|
    f.write(tempfile.read)
  end

  db.execute("INSERT INTO pictures (name, kategori, kat_lag, user_id, location) VALUES (?,?,?,?,?)",[up_name, up_kat, up_kat_lag, up_per,  "/uploaded_pictures/#{filename}"])
  
  redirect('/PictureHold/home')
end

get '/search' do
  query = params[:q]

  if query && !query.empty?
    @pictures = db.execute("SELECT * FROM pictures WHERE name LIKE ?","%#{query}%")

  else 
    @pictures = db.execute("SELECT * FROM pictures")
    
  end

  @home = true
  @user = db.execute("SELECT * FROM usertabell WHERE id=?", session[:user_id]).first
  slim(:homepage)
end