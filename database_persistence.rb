require 'pg'

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: "todos")
    @logger = logger
  end
  
  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def all_lists
    sql = 'SELECT * FROM list'
    result = query(sql)

    result.map do |tuple|
      { id: tuple['id'], name: tuple['name'], todos: [] }
    end
  end

  def add_to_list(list_name)
    sql = 'INSERT INTO list(name) VALUES ($1)'
    result = query(sql, list_name)
    all_lists
  end

  def lists_empty?
    all_lists.empty?
  end

  def delete_list(list_id)
    sql = 'DELETE FROM list WHERE id = $1'
    result = query(sql, list_id)
    all_lists
  end

  def list_size
    all_lists.size
  end

  def find_list(list_id)
    sql = 'SELECT * FROM list WHERE id = $1'
    result = query(sql, list_id)

    tuple = result.first
    { id: tuple['id'], name: tuple['name'], todos: [] }
  end
  
  def update_list_name(list_name, id)
    update_sql = 'UPDATE list SET name = $1 WHERE id = $2'    
    result = query(update_sql, list_name, id)
    find_list(id)
  end

  def find_todos(list_id)
    #find_list(list_id)[:todos]
  end

  def add_todo(list, text)
    #todo = { id: next_todo_id(list), name: text, completed: false }
    #list[:todos] << todo
  end

  def remove_todo(list_id, todo_id)
    #find_todos(list_id).reject! { |todo| todo[:id] == todo_id }
  end

  def select_first_todo(list, todo_id)
    #list[:todos].select { |todo| todo[:id] == todo_id }.first
  end

  def mark_all_todos_complete(list)
    #list[:todos].each { |todo| todo[:completed] = true }
  end

  private

  def next_todo_id(list)
    list[:todos].empty? ? 1 : list[:todos].size + 1
  end
end
