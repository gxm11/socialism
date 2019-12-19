require "sinatra"
require "./model/model"

set :bind, "0.0.0.0"
set :markdown, :layout_engine => :haml
enable :sessions

get "/" do
  markdown :index
end
