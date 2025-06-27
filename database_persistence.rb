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
    sql = <<~HEREDOC
    SELECT lists.*,
      COUNT(todos.id) AS todos_count,
      COUNT(NULLIF(todos.completed, true)) AS todos_remaining_count
      FROM lists
      LEFT JOIN todos on todos.list_id = lists.id
      GROUP BY lists.id;
    HEREDOC
    list = query(sql)

    list.map do |tuple|
      { id: tuple['id'],
        name: tuple['name'],
        todos_count: tuple['todos_count'].to_i,
        todos_remaining_count: tuple['todos_remaining_count'].to_i }
    end
  end

  def find_list(list_id)
    sql = 'SELECT * FROM lists WHERE id = $1'
    result = query(sql, list_id)

    tuple = result.first
    { id: tuple['id'], name: tuple['name'] }
  end

  def create_new_list(list_name)
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

  def update_list_name(list_name, id)
    update_sql = 'UPDATE lists SET name = $1 WHERE id = $2'
    query(update_sql, list_name, id)
    find_list(id)
  end

  def create_todo(list_id, todo_name)
    sql = 'INSERT INTO todos (list_id, name) VALUES($1, $2)'
    query(sql, list_id, todo_name)
  end

  def remove_todo(list_id, todo_id)
    sql = 'DELETE FROM todos WHERE id = $1 AND list_id = $2'
    query(sql, todo_id, list_id)
  end

  def update_todo_status(todo_id)
    sql = 'SELECT completed FROM todos WHERE id = $1'
    result = query(sql, todo_id).first

    boolean = result['completed'] == 't' ? 'FALSE' : 'TRUE'
    yield(boolean)
    sql = 'UPDATE todos SET completed = $1 WHERE id = $2'
    query(sql, boolean, todo_id)
  end

  def mark_all_todos_complete(list_id)
    sql = 'UPDATE todos SET completed = TRUE WHERE list_id = $1'
    query(sql, list_id)
  end

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
