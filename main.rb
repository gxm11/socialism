require "sinatra"
require "sqlite-static"
require "sequel"
require "haml"
require "./model/rl_base"
require "./model/city"

get "/" do
  "Hello, world"
end