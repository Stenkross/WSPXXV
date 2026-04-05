require 'sqlite3'
require 'bcrypt'

DB_PATH = "db/databas.db"

module Model

  # Skapar och retunerar en anslutning till databasen.
  # Om en anslutning finns redan återanvänds den.
  #
  # @return [SQLite3::Database], Den aktiva databasobjektet
  def db
    return @db if @db

    @db = SQLite3::Database.new(DB_PATH)
    @db.results_as_hash = true

    db.execute('PRAGMA foreign_keys = ON')

    return @db
  end

  # Hämtar all information om en specifik användare från databasen.
  #
  # @param [Integer] id Användarens unika ID-nummer
  #
  # @return [Hash] En hash som innehåller användarens data
  # @return [nil] om ingen användare hittades

  def get_user_id(id)
    db.execute("SELECT * FROM usertabell WHERE id=?", [id]).first
  end 

  # Hämtar all information om en specifik bild från databasen.
  #
  # @param [Integer] id Bildens unika ID-nummer
  #
  # @return [Hash] En hash som innehåller bildens data
  # @return [nil] om ingen bild hittades
  def get_pic_id(id)
    db.execute("SELECT * FROM pictures WHERE id = ?", [id]).first
  end 

  # Hämtar all information om alla bilder.
  #
  # @return [Hash] En hash som innehåller bildernas data
  # @return [nil] om inga bilder hittas
  def get_all_pics
    db.execute("SELECT * FROM pictures")
  end 

  # Kollar med databasen om användarnamnent redan finns.
  #
  # @param [String] username, Användarens önskade användarnamn
  #
  # @return [Boolean] true om namnet redan finns, false om namnet är ledigt
  def user_exist_already(username)
    result = db.execute("SELECT id FROM usertabell WHERE username=?", [username])
    return !result.empty?
  end

  # Kollar om lösernordet och användarnamnet matchar med databasen.
  #
  # @param [String] username, Användarens givna användarnamn
  # @param [String] password, Användarens givna lösenord
  #
  # @return [Integer] om användarnamnet och lösernodet stämmer retuneras användarens id
  # @return [String] "sparrad" om användaren har gissat fel för många gånger
  # @return [nil] om inget stämmer överens
  def authenticate(username, password)
    
    result = db.execute("SELECT id, pwd_digest, login_attempt FROM usertabell WHERE username=?",username)

    if result.empty?
      return nil
    end 

    used_id = result.first["id"]
    pwd_digest = result.first["pwd_digest"]
    attempts_str = result.first["login_attempt"] || ""

    text = attempts_str.split(',')
    attempts = []                       

    text.each do |t|
      attempts << t.to_i
    end

    if attempts.length >= 3
      time_skillnad = attempts.last - attempts[-3]
      time_senaste = Time.now.to_i - attempts.last
      if time_skillnad < 10 && time_senaste < 15
        return "sparrad"
      end 
    end 
    

    if BCrypt::Password.new(pwd_digest) == password
      db.execute("UPDATE usertabell SET login_attempt = '' WHERE username = ?", username)
      return used_id 
    else
      attempts << Time.now.strftime("%s")
      attempts = attempts.last(3)
      combined_attempts = attempts.join(',')

      db.execute("UPDATE usertabell SET login_attempt = ? WHERE username = ?", [combined_attempts, username])
      return nil
    end
  end 

  # Skapar en användare i databasen (usertabell).
  #
  # @param [String] username, Användarens önskade användarnamn
  # @param [String] password, Användarens önskade lösenord
  #
  # @return [void]
  def create_user(username, password)
    password_digest = BCrypt::Password.create(password)
    db.execute("INSERT INTO usertabell(username, pwd_digest) VALUES (?,?)", [username, password_digest])
  end

  # Skapar en kommentar i databasen (comments).
  #
  # @param [Integer] pic_id Bildens id
  # @param [Integer] user_id Kommentatorns id
  # @param [String] content Kommentarens text
  #
  # @return [void]
  def create_comment(pic_id, user_id, content)
    db.execute("INSERT INTO comments (picture_id, user_id, content) VALUES (?,?,?)", [pic_id, user_id, content])
  end 

  # Skapar en bild i databasen (pictures) med des tillhörande information.
  # Hanterar även kopplingen av kategorier till den nya bilden.
  #
  # @param [String] name Bildens namn
  # @param [String] kat_lag Bildens kategori
  # @param [Integer] user_id Uppladdarens id
  # @param [String] filename Namnet på filen som sparats
  # @param [Array<String>] categories En lista med kategorier som bilden ska kopplas till
  #
  # @return [void]
  def create_picture(name, kat_lag, user_id, filename, categories)
    db.execute("INSERT INTO pictures (name, kat_lag, user_id, location) VALUES (?,?,?,?)", [name, kat_lag, user_id, "/uploaded_pictures/#{filename}"])

    pic_id = db.last_insert_row_id
    categories.each do |cat|
      result = db.execute("SELECT id FROM category WHERE namn=?", [cat])

      if result.empty?
        db.execute("INSERT INTO category (namn) VALUES (?)", [cat])
        cat_id = db.last_insert_row_id
      else
        cat_id = result.first["id"]
      end

      db.execute("INSERT INTO picture_category (picture_id, category_id) VALUES (?,?)", [pic_id, cat_id])
    end
  end

  # Uppdaterar den angivna bildens information i databasen (pictures).
  # Hanterar även borttagning av gamla kategorikopplingar.
  #
  # @param [Integer] pic_id Bildens id
  # @param [String] new_name Bildens nya namn
  # @param [String] new_kat_lag Bildens nya läge
  # @param [Array<String>] new_categories En lista med bildens nya kategorier
  #
  # @return [void]
  def update_picture(pic_id, new_name, new_kat_lag, new_categories)
    db.execute("UPDATE pictures SET name = ?, kat_lag = ? WHERE id = ?", [new_name, new_kat_lag, pic_id])

    db.execute("DELETE FROM picture_category WHERE picture_id = ?", pic_id)

    new_categories.each do |cat|
      result = db.execute("SELECT id FROM category WHERE namn=?", cat)

      if result.empty?
        db.execute("INSERT INTO category (namn) VALUES (?)", cat)
        cat_id = db.last_insert_row_id
      else
        cat_id = result.first["id"]
      end
    
      db.execute("INSERT INTO picture_category (picture_id, category_id) VALUES (?,?)", [pic_id, cat_id])
    end
  end 

  # Hämtar kommentarerna och deras tillhörande ägare från databasen.
  # Grupperar sedan dessa utefter bilder.
  #
  # @return [Hash] En hash där nyckeln är bildens id och värdet är en lista med bildens kommentarer
  def groupe_comments
    db.execute(<<-SQL).group_by { |c| c["picture_id"] }
       SELECT comments.*, usertabell.username
       FROM comments
       INNER JOIN usertabell ON usertabell.id = comments.user_id
     SQL
  end 

  # Tar bort en bild från databasen (pictures).
  #
  # @param [Integer] id, Bildens id
  #
  # @return [void]
  def delete_picture(id)
    db.execute("DELETE from pictures WHERE id=?", [id])
  end 

  # Tar bort en kommentar från databasen (comments).
  #
  # @param [Integer] id, kommentarens id
  #
  # @return [void]
  def delete_comment(id)
    db.execute("DELETE from comments WHERE id=?", [id])
  end 

  # Söker i databasen efter bilder baserat på användarens inskrivna text och kategori.
  # Om en kategori är vald filtreras sökningen på den annars söker den enbart på namnet.
  #
  # @param [String] query Sökordet för att hitta bilder med matchande namn
  # @param [String] category Den valda kategorin att filtrera på
  #
  # @return [Array<Hash>] En lista med de bilder som matchar sökningen
  def search_pic(query, category)
    if category != ""
     sql = "
       SELECT DISTINCT pictures.*
       FROM pictures
       INNER JOIN picture_category ON pictures.id = picture_category.picture_id
       INNER JOIN category ON category.id = picture_category.category_id
       WHERE pictures.name LIKE ?
       AND category.namn = ?
     "
     values = ["%#{query}%", category]
    else 
     sql = "
       SELECT DISTINCT pictures.*
       FROM pictures
       LEFT JOIN picture_category ON pictures.id = picture_category.picture_id
       LEFT JOIN category ON category.id = picture_category.category_id
       WHERE pictures.name LIKE ?
     "
     values = ["%#{query}%"] 
    end

    db.execute(sql, values)
  end 
end 