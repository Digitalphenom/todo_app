class DatabasePersistence
  def initialize
    @db = PG.connect(dbname: "todos")
  end
  def all_lists
    @session[:lists]
  end

  def add_to_list(list_name)
    new_list = { id: next_list_id, name: list_name, todos: [] }
    all_lists << new_list
  end

  def lists_empty?
    all_lists.empty?
  end

  def update_lists=(value)
    @session[:lists] = value
  end

  def delete_list(list_id)
    all_lists.reject! { |list| list[:id] == list_id }
  end

  def list_size
    all_lists.size
  end

  def find_list(list_id)
    all_lists.find { |list| list[:id] == list_id }
  end

  def find_todos(list_id)
    find_list(list_id)[:todos]
  end

  def add_todo(list, text)
    todo = { id: next_todo_id(list), name: text, completed: false }
    list[:todos] << todo
  end

  def remove_todo(list_id, todo_id)
    find_todos(list_id).reject! { |todo| todo[:id] == todo_id }
  end

  def select_first_todo(list, todo_id)
    list[:todos].select { |todo| todo[:id] == todo_id }.first
  end

  def mark_all_todos_complete(list)
    list[:todos].each { |todo| todo[:completed] = true }
  end

  def current_list(id)
    all_lists[id]
  end

  def update_list_name(list_name, id)
    current_list(id)[:name] = list_name
  end

  private

  def next_todo_id(list)
    list[:todos].empty? ? 1 : list[:todos].size + 1
  end

  def next_list_id
    lists_empty? ? 0 : list_size
  end
end
