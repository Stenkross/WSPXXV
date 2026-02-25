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
end

def create_tables(db)
  db.execute('CREATE TABLE pictures (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL, 
              kategori INTEGER,
              kat_lag INTEGER,
              user_id INTEGER,
              location TEXT)')

  db.execute('CREATE TABLE usertabell (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT NOT NULL UNIQUE,
              pwd_digest TEXT NOT NULL)')
end


def populate_tables(db)
  db.execute('INSERT INTO pictures (name, kategori, kat_lag, user_id, location) VALUES ("Första foto", 1, 1, 1, "Elas.jpg")')

  db.execute('INSERT INTO usertabell (username, pwd_digest) VALUES ("anders", "qwe123")')


end


seed!(db)