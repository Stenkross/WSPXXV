require 'sqlite3'

db = SQLite3::Database.new("databas.db")

def seed!(db)
  puts "Using db file: db/todos.db"
  puts "🧹 Dropping old tables..."
  drop_tables(db)
  puts "🧱 Creating tables..."
  create_tables(db)
  puts "🍎 Populating tables..."
  populate_tables(db)
  puts "✅ Done seeding the database!"
end

def drop_tables(db)
  db.execute('DROP TABLE IF EXISTS pictures')
  db.execute('DROP TABLE IF EXISTS usertabell')
  db.execute('DROP TABLE IF EXISTS comments')
end

def create_tables(db)
  db.execute('CREATE TABLE pictures (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL, 
              kategori TEXT,
              kat_lag TEXT,
              user_id INTEGER,
              location TEXT)')

  db.execute('CREATE TABLE usertabell (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT NOT NULL UNIQUE,
              pwd_digest TEXT NOT NULL)')

  db.execute('CREATE TABLE category (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              namn TEXT)')

  db.execute('CREATE TABLE comments (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER,
              picture_id INTEGER,
              content TEXT)')
  db.execute('CREATE TABLE picture_category (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              picture_id INTEGER,
              category_id INTEGER)')
end

def populate_tables(db)
  db.execute('INSERT INTO pictures (name, kategori, kat_lag, user_id, location) VALUES ("Första foto", "vardag", "privat", 2, "/uploaded_pictures/Elas.jpg")')

  db.execute('INSERT INTO usertabell (username, pwd_digest) VALUES ("Admin", "$2a$12$UrPph/r5xcr6GEm5J6RbfOqGSzLjCZkYw2glpjHFaiq/CfzboD2I6")')

  db.execute('INSERT INTO comments (user_id, picture_id, content) VALUES (1, 1, "Snygg bild jani!")')

  db.execute('INSERT INTO pic_to_kat (namn) VALUES ("Vardag")')
  db.execute('INSERT INTO pic_to_kat (namn) VALUES ("Bröllop")')
  db.execute('INSERT INTO pic_to_kat (namn) VALUES ("Semester")')
  
end

seed!(db)