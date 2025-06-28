require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'erubi'
require 'erubi/capture_block'

require_relative 'database_persistence'

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
  set :erb, escape_html: true
  also_reload 'database_persistence.rb'
end

before do
  @storage = DatabasePersistence.new(logger)
end

after do
  @storage.disconnect
end

helpers do
  def list_complete?(list)
    list[:todos_count].positive? && list[:todos_remaining_count].zero?
  end

  def sort_lists(lists, &block)
    complete_lists, incomplete_lists =
      lists.partition { |list| list_complete?(list) }
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
def disconnect
  @db.close
end

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
  @storage.find_list(list_id)
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

  erb :edit_list
end

# Visit current list
get '/lists/:id' do
  @list_id = params[:id].to_i
  @lists = load_list(@list_id)
  @todos = @storage.find_todos(@list_id)

  erb :list
end

# ‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧

# Create new list
post '/lists' do
  list_name = params[:list_name].strip
  error_msg = validate(list_name)

  if error_msg
    session[:error] = error_msg
    erb :new_list, layout: :layout
  else
    @storage.create_new_list(list_name)

    session[:success] = 'The list has been created!'
    redirect '/lists'
  end
end

# Add todo item
post '/lists/:list_id/todos' do
  @list_id = params[:list_id].to_i
  text = params[:todo].strip
  error = error_for_todo(text)

  if error
    session[:error] = error
    erb :list
  else
    @storage.create_todo(@list_id, text)

    session[:success] = 'You added a todo'
    redirect "/lists/#{@list_id}"
  end
end

# Mark all todos complete
post '/lists/:list_id/todos/complete' do
  @list_id = params[:list_id].to_i
  @storage.mark_all_todos_complete(@list_id)

  session[:success] = 'All todos are complete'
  redirect "/lists/#{@list_id}"
end

# Mark todo complete
post '/lists/:list_id/todos/:todo_id' do
  @list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i

  @storage.update_todo_status(todo_id) do |status|
    message = case status
              when 'TRUE'
                'The todo item has been marked completed'
              when 'FALSE'
                'The todo item has been marked uncompleted'
              end
    session[:success] = message
  end
  redirect "/lists/#{@list_id}"
end

# Delete todo list
post '/lists/:list_id/delete' do
  @list_id = params[:list_id].to_i
  @storage.delete_list(@list_id)
  session[:success] = 'The list has been deleted'
  '/lists'
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
  error = validate(list_name)

  if error
    session[:error] = error
    @lists = @storage.find_list(id)
    erb :edit_list, layout: :layout
  else
    @storage.update_list_name(list_name, id)
    session[:success] = 'The list has been updated!'
    redirect "/lists/#{id}"
  end
end
