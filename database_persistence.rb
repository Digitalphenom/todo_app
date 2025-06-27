require 'pg'

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: 'todos')
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def all_lists
    sql = 'SELECT * FROM lists'
    list = query(sql)

    list.map do |tuple|
      { id: tuple['id'],
        name: tuple['name'],
        todos: find_todos(tuple['id']) }
    end
  end

  def add_to_list(list_name)
    sql = 'INSERT INTO lists(name) VALUES ($1)'
    query(sql, list_name)
    all_lists
  end

  def lists_empty?
    all_lists.empty?
  end

  def delete_list(list_id)
    sql = 'DELETE FROM lists WHERE id = $1'
    query(sql, list_id)
    all_lists
  end

  def list_size
    all_lists.size
  end

  def find_list(list_id)
    sql = 'SELECT * FROM lists WHERE id = $1'
    result = query(sql, list_id)

    tuple = result.first
    { id: tuple['id'], name: tuple['name'], todos: find_todos(list_id) }
  end

  def update_list_name(list_name, id)
    update_sql = 'UPDATE lists SET name = $1 WHERE id = $2'
    query(update_sql, list_name, id)
    find_list(id)
  end

  def add_todo(list_id, text)
    sql = 'INSERT INTO todos (name, list_id) VALUES($1, $2)'
    query(sql, text, list_id)
  end

  def remove_todo(_list_id, todo_id)
    sql = 'DELETE FROM todos WHERE id = $1'
    query(sql, todo_id)
  end

  def select_first_todo(todo_id)
    sql = 'SELECT * FROM todos WHERE id = $1'
    query(sql, todo_id)
  end

  def mark_all_todos_complete(list_id)
    sql = 'UPDATE todos SET completed = TRUE WHERE list_id = $1'
    query(sql, list_id)
  end

  private

  def find_todos(list_id)
    sql = 'SELECT * FROM todos WHERE list_id = $1'
    result = query(sql, list_id)
    result.map do |tuple|
      { id: tuple['id'],
        name: tuple['name'],
        completed: tuple['completed'] == 't' }
    end
  end
end
