require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'erubi'
require 'erubi/capture_block'

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
  set :erb, escape_html: true
end

before do
  @storage = SessionPersistence.new(session)
end

helpers do
  def display_count(list)
    total = list[:todos].count
    done = list[:todos].inject(0) do |acc, todo|
      todo[:completed] ? acc + 1 : acc
    end

    [total, done]
  end

  def list_complete(list)
    total, done = display_count(list)
    return '' if total.zero? && done.zero?

    total == done ? 'complete' : ''
  end

  def sort_lists(lists, &block)
    complete_lists, incomplete_lists =
      lists.partition { |list| list_complete(list) == 'complete' }
    incomplete_lists.each(&block)
    complete_lists.each(&block)
  end

  def sort_todos(todos, &block)
    complete_todos, incomplete_todos =
      todos.partition { |todo| todo[:completed] }

    incomplete_todos.each(&block)
    complete_todos.each(&block)
  end
end

# ‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧

class SessionPersistence
  def initialize(session)
    @session = session
    @session[:lists] ||= []
  end

  def all_lists
    @session[:lists]
  end

  def add_to_list(list)
    all_lists << list
  end

  def lists_empty?
    @session[:lists].empty?
  end

  def update_lists=(value)
    @session[:lists] = value
  end

  def delete_list(list_id)
    all_lists.reject! { |list| list[:id] == list_id }
  end

  def list_size
    @session[:lists].size
  end

  def find_list(list_id)
    all_lists.find { |list| list[:id] == list_id }
  end

  def find_todos(list_id)
    find_list(list_id)[:todos]
  end

  def add_todo(list, todo)
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
end

# ‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧

def validate(list)
  if !(1..100).cover? list.size
    'List name must be between 1 and 100 characters'
  elsif @storage.all_lists.any? { |hsh| hsh[:name] == list }
    'List name must be unique.'
  end
end

def error_for_todo(name)
  return if (1..100).cover? name.size

  'Todo must be between 1 and 100 characters'
end

def load_list(list_id)
  @storage.find_list(@list_id)
end

# ◟◅◸◅▻◅▻◅▻◅▻◅▻◅▻◅▻◅▻◅▻◅▻◅▻◅▻◅▻◅▻◅▻◅▻◅▻◞

def check_if_empty(list)
  if list.nil?
    @storage.update_lists = 'The list was not found'
    redirect('/lists')
  else
    list
  end
end

def next_todo_id(list)
  return 1 if list[:todos].empty?

  list[:todos].size + 1
end

def next_list_id
  return 0 if @storage.lists_empty?

  @storage.list_size
end

# ◟◅◸◅▻◅▻◅▻◅▻◅▻◅▻◅▻◅▻◅▻◅▻◅▻◅▻◅▻◅▻◅▻◅▻◅▻◞

get '/' do
  redirect '/lists'
end

# View list of all lists
get '/lists' do
  @lists = @storage.all_lists
  erb :lists
end

# Render new list form
get '/lists/new' do
  erb :new_list
end

# Edit existing todo
get '/lists/:id/edit' do
  @list_id = params[:id].to_i
  @lists = load_list(@list_id)
  @lists = check_if_empty(@lists)

  erb :edit_list
end

# Visit curent todo
get '/lists/:id' do
  @list_id = params[:id].to_i
  @lists = load_list(@list_id)
  @lists = @storage.find_list(@list_id)

  @lists = check_if_empty(@lists)
  erb :list
end

# ‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧

# Create new list
post '/lists' do
  list_name = params[:list_name].strip

  error = validate(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    id = next_list_id
    list = { id: id, name: list_name, todos: [] }
    @storage.add_to_list(list)
    
    session[:success] = 'The list has been created!'
    redirect '/lists'
  end
end

# Add todo item
post '/lists/:list_id/todos' do
  @list_id = params[:list_id].to_i
  @lists = load_list(@list_id)
  text = params[:todo].strip

  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list
  else
    id = next_todo_id(@lists)
    todo = { id: id, name: text, completed: false }
    @storage.add_todo(@lists, todo)
    
    session[:success] = 'You added a todo'
    redirect "/lists/#{@list_id}"
  end
end

# Mark all todos complete
post '/lists/:list_id/todos/complete' do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  @list = check_if_empty(@list)

  @storage.mark_all_todos_complete(@list)

  session[:success] = 'All todos are complete'
  redirect "/lists/#{@list_id}"
end

# Mark todo complete
post '/lists/:list_id/todos/:todo_id' do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  @list = check_if_empty(@list)
  todo_id = params[:todo_id].to_i

  is_completed = params[:completed] == 'true'
  todo = @storage.select_first_todo(@list, todo_id)
  todo[:completed] = is_completed
  session[:success] = 'The todo item has been completed'
  redirect "/lists/#{@list_id}"
end

# Delete todo list
post '/lists/:list_id/delete' do
  @list_id = params[:list_id].to_i
  @storage.delete_list

  if env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest'
    '/lists'
  else
    session[:success] = 'The list has been deleted'
    redirect '/lists'
  end
end

# Delete todo item
post '/lists/:list_id/todos/:todo_id/delete' do
  @list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  @storage.remove_todo(@list_id, todo_id)

  if env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest'
    status 204
  else
    session[:success] = 'The todo item has been deleted'
    redirect "/lists/#{@list_id}"
  end
end

# Submit updated list
post '/lists/:id' do
  list_name = params[:list_name].strip
  id = params[:id].to_i
  @lists = @storage.all_lists[id]
  @lists = check_if_empty(@lists)

  error = validate(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    # session[:lists].reject! { |list| list[:id] == @list_id }
    @lists[:name] = list_name
    session[:success] = 'The list has been updated!'
    redirect "/lists/#{id}"
  end
end
