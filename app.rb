require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative './model.rb'

enable :sessions

before do
  if session[:user_id]
    @user = db.execute("SELECT * FROM usertabell WHERE id=?", session[:user_id]).first
  else
    @user = nil
  end
end

def re_login
  halt redirect('/PictureHold/account/login') unless @user
end

get '/PictureHold/home' do
  @home = true
  @pictures = db.execute("SELECT * FROM pictures")
  @user = db.execute("SELECT * FROM usertabell WHERE id=?", session[:user_id]).first

  @comments = db.execute(<<-SQL).group_by { |c| c["picture_id"] }
    SELECT comments.*, usertabell.username
    FROM comments
    INNER JOIN usertabell ON usertabell.id = comments.user_id
  SQL

  slim(:homepage)
end

get '/PictureHold/upload' do
  re_login
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

  halt "Tomma fält" if username.to_s.strip == "" || password.to_s.strip == ""

  result = db.execute("SELECT id FROM usertabell WHERE username=?", username)

  
  
  if result.empty?
    if password == password_confirm
      password_digest = BCrypt::Password.create(password)
      db.execute("INSERT INTO usertabell(username, pwd_digest) VALUES (?,?)", [username, password_digest])
      redirect('/PictureHold/home')
    else
      halt "Lösenorden matchar inte" unless password == password_confirm
    end 
  else 
    halt "Användarnamn finns redan"
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

  result = db.execute("SELECT id, pwd_digest FROM usertabell WHERE username=?",username)

  used_id = result.first["id"]
  pwd_digest = result.first["pwd_digest"]
  if BCrypt::Password.new(pwd_digest) == password
    session[:user_id] = used_id
    redirect('/PictureHold/home')
  else
    halt "Fel användarnamn eller lösenord"
  end
end

post '/PictureHold/:id/delete' do
  re_login
  id = params[:id]
  picture = db.execute("SELECT * FROM pictures WHERE id=?", [id]).first

  if @user["id"] != 1
    halt "No access" unless picture["user_id"] == @user["id"]
  end
  db.execute("DELETE from pictures WHERE id=?", [id])
  redirect('/PictureHold/home')
end

get '/PictureHold/:id/edit' do
  @user = db.execute("SELECT * FROM usertabell WHERE id=?", session[:user_id]).first
  if @user["id"] != 1
    halt "No access" unless @selected_pic["user_id"] == @user["id"]
  end
  id = params[:id]
  @selected_pic = db.execute("SELECT * FROM pictures WHERE id = ?", [id]).first
  slim(:edit)
end 

post '/PictureHold/:id/update' do 
  id = params[:id]
  new_name = params[:name]
  new_kategori = params[:kategori]
  new_kat_lag = params[:"kat-lage"]  
  pic = db.execute("SELECT * FROM pictures WHERE id=?", [id]).first

   if @user["id"] != 1
    halt "No access" unless pic["user_id"] == @user["id"]
  end

  db.execute("UPDATE pictures SET name = ?, kategori = ?, kat_lag = ? WHERE id = ?", [new_name, new_kategori, new_kat_lag, id])

  redirect('/PictureHold/home')
end 

post '/PictureHold/upload' do
  re_login
  halt "Tomt namn" if params[:namez].to_s.strip == ""
  halt "Ingen bild vald" unless params[:picture]
  up_name = params[:namez]
  up_kat= params[:kategori]
  up_kat_lag = params[:"kat-lage"]
  up_per = session[:user_id]
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
  query = params[:q] || ""
  category = params[:kategori] || ""

  sql = "
    SELECT DISTINCT pictures.*
    FROM pictures
    LEFT JOIN picture_category ON pictures.id = picture_category.picture_id
    LEFT JOIN category ON category.id = picture_category.category_id
    WHERE pictures.name LIKE ?
  "

  values = ["%#{query}%"]

  if category != ""
    sql += " AND category.namn = ?"
    values << category
  end

  @pictures = db.execute(sql, values)

  @comments = db.execute(<<-SQL).group_by { |c| c["picture_id"] }
    SELECT comments.*, usertabell.username
    FROM comments
    INNER JOIN usertabell ON usertabell.id = comments.user_id
  SQL

  @user = db.execute("SELECT * FROM usertabell WHERE id=?", session[:user_id]).first

  @home = true
  slim(:homepage)
end

get '/logout' do
  session.clear
  redirect '/PictureHold/account/login'
end 

post "/comment" do 
  re_login
  pic_id = params[:picture_id]
  content = params[:content]
  user_id = session[:user_id]
  halt "Empty comment" if params[:content].to_s.strip == ""

  db.execute("INSERT INTO comments (picture_id, user_id, content) VALUES (?,?,?)", [pic_id, user_id, content])

  redirect('/PictureHold/home')
end 