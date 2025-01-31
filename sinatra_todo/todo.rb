require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
# require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

before do
  session[:lists] ||= []
end

helpers do
  def display_count(list)
    total = list[:todos].count
    done = list[:todos].inject(0) do |acc, todo|
      todo[:completed] ? acc += 1 : acc
    end

    "#{total} / #{done}"
  end
end

#‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧

def validate(list)
  if !(1..100).cover? list.size
    'List name must be between 1 and 100 characters'
  elsif session[:lists].any? { |hsh| hsh[:name] == list }
    'List name must be unique.'
  end
end

def error_for_todo(name)
  if !(1..100).cover? name.size
    'Todo must be between 1 and 100 characters'
  end
end

#‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧

get '/' do
  redirect '/lists'
end

# View list of all lists
get '/lists' do
  @lists = session[:lists]

  erb :lists
end

# Render new list form
get '/lists/new' do
  erb :new_list
end

# Edit existing todo
get '/lists/:id/edit' do
  @list_id = params[:id].to_i
  @lists = session[:lists][@list_id]
  erb :edit_list
end

# Visit curent todo
get '/lists/:id' do
  @list_id = params[:id].to_i
  @lists = session[:lists][@list_id]
  erb :list
end

#‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧

# Create new list
post '/lists' do
  list_name = params[:list_name].strip

  error = validate(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'The list has been created!'
    redirect '/lists'
  end
end

# Add todo item
post '/lists/:list_id/todos' do
  @list_id = params[:list_id].to_i
  @lists = session[:lists][@list_id]
  text = params[:todo].strip

  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list
  else
    @lists[:todos] << {name: text, completed: false}
    session[:success] = 'You added a todo'
    redirect "/lists/#{@list_id}"
  end
end

# Mark all todos complete
post '/lists/:list_id/todos/complete' do
  @list_id = params[:list_id].to_i
  current_list = session[:lists][@list_id]

  current_list[:todos].each { |todo| todo[:completed] = true }

  session[:success] = 'All todos are complete'
  redirect "/lists/#{@list_id}"
end

# Mark todo complete
post '/lists/:list_id/todos/:todo_id' do
  @list_id = params[:list_id].to_i
  curent_list = session[:lists][@list_id]
  
  todo_id = params[:todo_id].to_i
  is_completed = params[:completed] == "true"
  curent_list[:todos][todo_id][:completed] = is_completed

  session[:success] = 'The todo item has been completed'
  redirect "/lists/#{@list_id}"
end

# Delete todo list
post '/lists/:list_id/delete' do
  @list_id = params[:list_id].to_i
  session[:lists].delete_at @list_id
  session[:success] = 'The list has been deleted'
  redirect "/lists"
end

# Delete todo item
post '/lists/:list_id/todos/:todo_id/delete' do
  @list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  session[:lists][@list_id][:todos].delete_at todo_id
  session[:success] = 'The todo item has been deleted'
  redirect "/lists/#{@list_id}"
end

# Submit updated list
post '/lists/:id' do
  list_name = params[:list_name].strip
  id = params[:id].to_i
  @lists = session[:lists][id]
  
  error = validate(list_name)
  if error  
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @lists[:name] = list_name
    session[:success] = 'The list has been updated!'
    redirect "/lists/#{id}"
  end
end

