require "sinatra"
require "./model/model"

set :bind, "0.0.0.0"
set :markdown, :layout_engine => :haml
# enable :sessions

Caches = {}
Dir.glob("./saves/city_*.data") do |fn|
  city = Marshal.load(File.binread(fn))
  Caches[city.name] = city
end

get "/readme" do
  markdown :readme
end

get "/" do
  haml :index
end

post "/api/create_city" do
  name = params[:name]
  if name =~ /^[0-9a-zA-Z_\-]+$/ && !Caches.key?(name)
    id = Dir.glob("./saves/*.data").size
    city = City.new(id)
    Caches[name] = city
    city.name = name
    city.city_level = params[:city_level].to_i.to_f
    city.farm_level = params[:farm_level].to_f
    city.food_storage = params[:food].to_f
    params[:population].to_i.times do |i|
      c = Citizen.new(i)
      c.ability = 3.times.collect { rand * city.city_level }
      city.citizen << c
    end
    File.open("./saves/city_#{id}.data", "wb") do |f|
      Marshal.dump(city, f)
    end
    redirect "/city/#{name}"
  else
    redirect "/"
  end
end

get "/city/:name" do
  name = @params[:name]
  if !Caches.key?(name)
    redirect "/"
  else
    @city = Caches[name]
    haml :city
  end
end

get "/citizen/:name" do
  name = @params[:name]
  if !Caches.key?(name)
    redirect "/"
  else
    @city = Caches[name]
    haml :citizen
  end
end

post "/api/set_policy" do
  name = params[:name]
  city = Caches[name]
  if city
    city.policy[:welfare] = params[:welfare].to_f
    city.policy[:alms] = params[:alms].to_f
    city.policy[:auto_upgrade] = (params[:auto_upgrade] == "1")
    redirect "/city/#{name}"
  else
    redirect "/"
  end
end

post "/api/set_tax" do
  name = params[:name]
  city = Caches[name]
  if city
    city.base_tax = params[:tax].collect(&:to_f)
    redirect "/city/#{name}"
  else
    redirect "/"
  end
end

post "/api/set_action" do
  name = params[:name]
  city = Caches[name]
  if city
    city.extra_actions.clear
    city.extra_tax.clear
    params[:d] ||= []
    params[:d].size.times do |i|
      f = [:f0, :f1, :f2].collect { |f| params[f][i].to_f }
      next if f.sum > 1.001 || f.min < 0.0
      action = Action.new(1, f, params[:d][i])
      city.extra_actions << action
      city.extra_tax << params[:tax][i].to_f
      if city.extra_actions.size == city.city_level.to_i
        break
      end
    end
    redirect "/city/#{name}"
  else
    redirect "/"
  end
end

post "/api/update" do
  name = params[:name]
  city = Caches[name]
  if city
    city.update
    File.open("./saves/city_#{city.id}.data", "wb") do |f|
      Marshal.dump(city, f)
    end
    redirect request.referrer
  else
    redirect "/"
  end
end

get "/api/del_citizen" do
  name = params[:name]
  city = Caches[name]
  if city
    c = city.citizen.find { |c| c.id == params[:id].to_i }
    city.del_citizen(c)
    redirect "/citizen/#{name}"
  else
    redirect "/"
  end
end

get "/api/add_citizen" do
  name = params[:name]
  city = Caches[name]
  if city
    id = city.citizen.collect(&:id).max + 1
    c = Citizen.new(id)
    c.ability = 3.times.collect { rand * city.city_level }
    city.add_citizen(c)
    redirect "/citizen/#{name}"
  else
    redirect "/"
  end
end
