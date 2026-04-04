require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative './model.rb'

enable :sessions

include Model

# Körs automatiskt före varje route i applikationen. 
# Kollar om användaren är inloggad i sessionen och returnerar all dens data från databasen.
# 
# @see Model#get_user_id
before do
  if session[:user_id]
    @user = get_user_id(session[:user_id])
  else
    @user = nil
  end
end

# Skyddar de routes som behöver inloggning.
# Om anändaren inte är inloggad kommer @user = nil vilket avbryter koden och skickar användaren till login.
def re_login
  halt redirect('/PictureHold/account/login') unless @user
end

# Skickar användaren till startsidan på hemsidan där bilderna visas.
#
# @see Model#get_all_pics
# @see Model#groupe_comments
get '/PictureHold/home' do
  @home = true
  @pictures = get_all_pics
  @comments = groupe_comments
  slim(:index)
end

# Skickar användaren till sidan där man laddar upp bilder.
# För att använda sidan kräver det att man är inloggad.
#
# @see re_login
get '/PictureHold/upload' do
  re_login
  slim(:upload)
end 

# Skickar användaren till en sida där man kan skapa konton.
get '/PictureHold/account/create' do
  slim(:create)
end

# Skickar användaren till en sida där man kan logga in.
get '/PictureHold/account/login' do
  slim(:login)
end 

# Skickar användaren till sidan där man kan redigera en specifik bild.
# För att använda sidan kräver det att man är inloggad eller att man är en admin (user_id = 1).
#
# @param [Integer] :id, Bildens id hämtas från URL:en
#
# @see Model#get_pic_id
get '/PictureHold/:id/edit' do
  id = params[:id]
  @selected_pic = get_pic_id(id)

  if @user["id"] != 1
    halt "No access" unless @selected_pic["user_id"] == @user["id"]
  end
 
  slim(:edit)
end 

# Modifierar vilka bilder man ser på index sidan.
#
# @param [String] q, Sökordet från användaren (blir tomt om inget skrivs)
# @param [String] kategori, Den valda kategorin att filtrera på
#
# @see Model#search_pic
# @see Model#groupe_comments
get '/search' do
  query = params[:q] || ""
  category = params[:kategori] || ""

  @pictures = search_pic(query, category)

  @comments = groupe_comments

  @home = true
  slim(:index)
end

# Loggar användaren ut genom att rensa session.
# Skickar sedan användaren till inloggningssidan.
get '/logout' do
  session.clear
  redirect '/PictureHold/account/login'
end 

# Skapar en ny användare i databasen.
# Kontrolerar att fälten inte är tomma och att användarnamnent inte redan finns och att lösenorden matchar.
# Användaren skickas sedan tillbaka till startsidan om de kraven uppfylls.
# 
# @param [String] username, Användarnamnet som användaren har skrivit in i formuläret
# @param [String] password, Lösenordet från formuläret
# @param [String] confirm_password, Det konfermerade lösenordet från formuläret
#
# @see Model#user_exist_already
# @see Model#create_user
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

# Verifierar inloggninen från användaren.
# Om uppgifterna från formuläret stämmer överens sparas användarens id i sessionen och omdirigeras till startsidan.
#
# @param [String] username, Användarnamnet som användaren har skrivit in i formuläret
# @param [String] password, Lösenordet från formuläret
#
# @see Model#authenticate
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

# Tar bort den anginvna bilden från databasen.
# Kollar om personen som tar bort är den som äger bilden eller om det är en admin.
# Om föregånde krav går igenom omdirigeras användaren till startsidan.
#
# @param [Integer] :id, Bildens id hämtas från URL:en
#
# @see re_login
# @see Model#delete_picture
# @see Model#get_pic_id
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

# Tar bort en angiven kommentar från databasen.
# Kollar om det är en admin.
# Om föregående krav stämmer omderigeras användaren till startsidan.
#
# @param [Integer] :id, Bildens id hämtas från URL:en
#
# @see Model#delete_comment
post '/PictureHold/:id/delete_com' do
  if @user["id"] != 1
    halt "No access"
  end
  
  delete_comment(params[:id])
  redirect('/PictureHold/home')
end

# Uppdaterar den befintliga informationen kring en bild och dess kategori.
# Kräver att användaren är inloggad. Efter uppdatering omdirigeras användaren till startsidan.
#
# @param [Integer] :id, Bildens id hämtas från URL:en
# @param [String] namez, Det nya namnet på bilden från formuläret
# @param [String] kat-lage, Den nya kategorin från formuläret
# @param [Array<String>] categories, En lista med valda kategorier från formuläret som blir en tom lista om ingenting väljs
#
# @see re_login
# @see Model#delete_comment
post '/PictureHold/:id/update' do
  re_login
  
  pic_id = params[:id]
  new_name = params[:namez]
  new_kat_lag = params[:"kat-lage"]
  
  new_categories = params["categories"] || []

  update_picture(pic_id, new_name, new_kat_lag, new_categories)
  
  redirect('/PictureHold/home')
end

# Uppdaterar databasen med en ny bild och dess anhörande information.
# Kräver att användaren är inloggad, skriver ett namn och laddar upp en bild.
# Om följade krav är godkända omdirigeras användaren tillstartsidan.
#
# @param [String] namez, Namnet på bilden från formuläret
# @param [String] kat-lage, Kategorin för bilden från formuläret
# @param [Hash] picture, Själva filuppladdningen från formuläret (innehåller tempfile och filename)
# @param [Array<String>] categories, En lista med valda kategorier från formuläret kan bli tom
#
# @see re_login
# @see Model#create_picture
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

# Uppdaterar databasen med en ny kommentar.
# Kräver att användaren är inloggad, och personen har skrivit en kommentar.
# Om följande krav godkänns kommer användaren omdirigeras till startsidan.
#
# @param [String] picture_id, Den tillhörande bildens id.
# @param [String] content, Kommentarens text. 
# @param [String] user_id, Den kommenterande användarens id.
#
# @see re_login
# @see Model#create_comment
post "/comment" do 
  re_login
  pic_id = params[:picture_id]
  content = params[:content]
  user_id = session[:user_id]
  halt "Empty comment" if params[:content].to_s.strip == ""

  create_comment(pic_id, user_id, content)
  redirect('/PictureHold/home')
end 