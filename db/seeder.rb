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
  db.execute('DROP TABLE IF EXISTS category')
  db.execute('DROP TABLE IF EXISTS picture_category')
end

def create_tables(db)
  db.execute('CREATE TABLE pictures (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL, 
              kat_lag TEXT,
              user_id INTEGER,
              location TEXT)')

  db.execute('CREATE TABLE usertabell (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT NOT NULL UNIQUE,
              pwd_digest TEXT NOT NULL, 
              last_login)')

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
  db.execute('INSERT INTO pictures (name, kat_lag, user_id, location) VALUES ("Första foto", "Offentlig", 1, "/uploaded_pictures/17656885_orig.jpg")')
  db.execute('INSERT INTO pictures (name, kat_lag, user_id, location) VALUES ("Andra foto", "Offentlig", 1, "/uploaded_pictures/20231211_123300.jpg")')
  db.execute('INSERT INTO pictures (name, kat_lag, user_id, location) VALUES ("Tredje foto", "Offentlig", 1, "/uploaded_pictures/20240124_121326.jpg")')
  db.execute('INSERT INTO pictures (name, kat_lag, user_id, location) VALUES ("Fjärde foto", "Offentlig", 1, "/uploaded_pictures/Arabian-dromedary-camel-calf.png")')

  db.execute('INSERT INTO usertabell (username, pwd_digest) VALUES ("Admin", "$2a$12$UrPph/r5xcr6GEm5J6RbfOqGSzLjCZkYw2glpjHFaiq/CfzboD2I6")')

  db.execute('INSERT INTO comments (user_id, picture_id, content) VALUES (1, 1, "Snygg bild jani!")')

  db.execute('INSERT INTO category (namn) VALUES ("Vardag")')
  db.execute('INSERT INTO category (namn) VALUES ("Bröllop")')
  db.execute('INSERT INTO category (namn) VALUES ("Semester")')
  db.execute('INSERT INTO category (namn) VALUES ("Natur")')

  db.execute('INSERT INTO picture_category (picture_id, category_id) VALUES (1, 1)')
  db.execute('INSERT INTO picture_category (picture_id, category_id) VALUES (1, 2)')
  db.execute('INSERT INTO picture_category (picture_id, category_id) VALUES (2, 1)')
  
end

seed!(db)