require 'sqlite3'
require 'bcrypt'

DB_PATH = "db/databas.db"

def db
  return @db if @db

  @db = SQLite3::Database.new(DB_PATH)
  @db.results_as_hash = true

  db.execute('PRAGMA foreign_keys = ON')

  return @db
end

def get_user_id(id)
  db.execute("SELECT * FROM usertabell WHERE id=?", [id]).first
end 

def get_pic_id(id)
  db.execute("SELECT * FROM pictures WHERE id = ?", [id]).first
end 

def get_all_pics
  db.execute("SELECT * FROM pictures")
end 

def user_exist_already(username)
  result = db.execute("SELECT id FROM usertabell WHERE username=?", [username])
  return !result.empty?
end

def autenicate(username, password)
  result = db.execute("SELECT id, pwd_digest FROM usertabell WHERE username=?",username)
  if result.empty?
    return nil
  end 
  used_id = result.first["id"]
  pwd_digest = result.first["pwd_digest"]
  if BCrypt::Password.new(pwd_digest) == password
    return used_id 
  else
    return nil
  end
end 

def create_user(username, password)
  password_digest = BCrypt::Password.create(password)
  db.execute("INSERT INTO usertabell(username, pwd_digest) VALUES (?,?)", [username, password_digest])
end
def create_comment(pic_id, user_id, content)
  db.execute("INSERT INTO comments (picture_id, user_id, content) VALUES (?,?,?)", [pic_id, user_id, content])
end 

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

def groupe_comments
  db.execute(<<-SQL).group_by { |c| c["picture_id"] }
     SELECT comments.*, usertabell.username
     FROM comments
     INNER JOIN usertabell ON usertabell.id = comments.user_id
   SQL
end 

def delete_picture(id)
  db.execute("DELETE from pictures WHERE id=?", [id])
end 

def delete_comment(id)
  db.execute("DELETE from comments WHERE id=?", [id])
end 

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