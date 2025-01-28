require "sinatra"
require "sinatra/reloader"
#require "tilt/erubis"

configure do 
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# View list of lists
get "/lists" do
  @lists = session[:lists]
  erb :lists
end

# Render new list form
get "/lists/new" do 
  erb :new_list
end

# Create new list
post "/lists" do
  list_name = params[:list_name].strip
  if (1..100).cover? list_name.size
    session[:lists] << {name: list_name, todos: []}
    session[:success] = "The list has been created!"
    redirect "/lists"
  elsif session[:lists].any? { |list| list[:name] == list_name }
    session[:error] = "List name must be unique."
    erb :new_list, layout: :layout
  else
    session[:error] = "List name must be between 1 and 100 characters"
    erb :new_list, layout: :layout
  end
end

