DB_PATH = "db/databas.db"

def db
  return @db if @db

  @db = SQLite3::Database.new(DB_PATH)
  @db.results_as_hash = true

  return @db
end

def account_create

  return nil
end 

