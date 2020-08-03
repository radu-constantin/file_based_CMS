require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
require "redcarpet"
#require "fileutils"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
	@files = Dir.glob("*", base: "./data")
end

def error_for_file_name(file_name)
	unless @files.include?(file_name)
		"#{file_name} does not exist."
	end
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

#Method for reading markdown files using Redcarpet
def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
    when ".txt"
      headers["Content-Type"] = "text/plain"
      content
    when ".md"
      render_markdown(content)
  end
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

get "/" do
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end
	erb :index
end

# Page in which you can edit the specific file
get "/:file_name/edit" do
  file_path = File.join(data_path, params[:file_name])

  @filename = params[:file_name]
  @content = File.read(file_path)

  erb :edit
end

# Page in which user can create a new file.
get "/new" do
  erb :new
end

#Processes the new file
post "/new" do
  if params[:title].strip.size == 0
    session[:message] = "A name is required."
    erb :new
  else
    file_path = File.join(data_path, params[:title])
    File.new(file_path, mode="w")
    session[:message] = "#{params[:title]} was created."
    redirect "/"
  end
end

# Access the requested file.
get "/:file_name" do
	file_path = File.join(data_path, params[:file_name])

  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:file_name]} does not exist."
    redirect "/"
  end
end

# Edits the file
post "/:file_name" do
  file_path = File.join(data_path, params[:file_name])

  File.write(file_path, params[:text_edit])

  session[:message] = "#{params[:file_name]} has been updated."
  redirect "/"
end
