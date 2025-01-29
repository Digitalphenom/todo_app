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

get '/' do
  redirect '/lists'
end

# View list of all lists
get '/lists' do
  @lists = session[:lists]
  @lists.each.with_index do |list, idx|
  end
  erb :lists
end

# Render new list form
get '/lists/new' do
  erb :new_list
end

def validate(list)
  if !(1..100).cover? list.size
    'List name must be between 1 and 100 characters'
  elsif session[:lists].any? { |hsh| hsh[:name] == list }
    'List name must be unique.'
  end
end

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

# Edit existing todo

get '/lists/:id/edit' do
  id = params[:id].to_i
  @lists = session[:lists][id]
  erb :edit_list
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

# Visit curent todo
get '/lists/:id' do
  @id = params[:id].to_i
  @lists = session[:lists][@id]
  erb :list
end

# Delete todo item
post '/lists/:id/delete' do
  id = params[:id].to_i
  session[:lists].delete_at id
  session[:success] = 'The list has been deleted'
  redirect "/lists"
end

# Add todo item
post '/lists/:id/todos' do
  id = params[:id].to_i
  session[:lists][id][:todos] << params[:todo] 
  session[:success] = 'You added a todo'
  redirect "/lists"
end
