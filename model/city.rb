# encoding: utf-8
# kind: 0: base / 1: extra
# features: [plant, reclaim, science]

class City
    attr_accessor :id
    attr_accessor :city_level
    attr_accessor :farm_level
    attr_accessor :food_storage
    attr_accessor :citizen
    attr_accessor :extra_actions
  
    def initialize(id)
      @id = id
      @city_level = 1.0
      @city_upgrade = 0.0
      @farm_level = 1.0
      @food_storage = 1000.0
      @citizen = []
      @extra_actions = []
      @policy = {
        action: [0.0, 0.0, 0.0], alms: 0.0, welfare: 0.0,
      }
    end
  
    # -----------------------------------
    # properties
    # -----------------------------------
    def actions
      base_actions + extra_actions
    end
  
    def base_actions
      [
        Action.new(0, [1.0, 0.0, 0.0], "* Agriculture *"),
        Action.new(0, [0.0, 1.0, 0.0], "* Reclaimation *"),
        Action.new(0, [0.0, 0.0, 1.0], "* Construction *"),
      ]
    end
  
    def daily_food
      @city_level
    end
  
    def population
      @citizen.size
    end
  
    # -----------------------------------
    # citizen manage
    # -----------------------------------
    def add_citizen(citizen)
      return if @food_storage < daily_food
      @citizen << citizen
      @food_storage -= daily_food
      citizen.food += daily_food
    end
  
    def del_citizen(citizen)
      return if @food_storage < daily_food
      @food_storage -= daily_food
      if @citizen.include?(citizen)
        @citizen.delete(citizen)
        if citizen.food > 0
          @food_storage += citizen.food
        end
      end
    end
  
    def levelup_city
      return if @food_storage < daily_food * population
      return if @city_upgrade < @city_level
      @city_level += 1
      @city_upgrade = 0
      @food_storage -= daily_food * population
    end
  
    # -----------------------------------
    # implement action
    # -----------------------------------
    def update
      citizen_make_actions
      citizen_take_actions
      citizen_train_model
    end
  
    def citizen_make_actions
      actions = self.actions
      @action_ids = @citizen.collect { |c| c.make_action_id(actions) }
    end
  
    def citizen_take_actions
      all_actions = self.actions
      plant_num = @action_ids.sum { |id| all_actions[id].features[0] } / @farm_level
      plant_factor = (plant_num == 1) ? 1 : Math.tanh(plant_num - 1) / (plant_num - 1)
      @action_values = []
      @citizen.zip(@action_ids) do |c, id|
        action = all_actions[id]
        if c.food > 0
          value = citizen_take_normal_action(c, id, plant_factor)
          @action_values << value
        else
          citizen_take_hungry_action(c)
          @action_values << nil
        end
      end
    end
  
    def citizen_take_normal_action(citizen, id, plant_factor)
      action = self.actions[id]
      a, f = citizen.ability, action.features
      _food = -daily_food
      # 1. gain food
      _food += f[0] * a[0] * Math.sqrt(@farm_level) * plant_factor
      # 2. increase farm
      @farm_level += f[1] * a[1] / @farm_level
      # 3. increase city
      @city_upgrade += f[2] * a[2] / (@city_level * @city_level)
      _food -= f[2] * @city_level * daily_food
      # 4. increase ability
      if rand < 1.0 / @city_level
        ix = f.find_index(f.max)
        if a[ix] < @city_level
          a[ix] += 1 - a[ix] / @city_level
          _food -= daily_food
        end
      end
      # 5. policy: action and welfare
      _food += @policy[:action][id]
      @food_storage -= @policy[:action][id]
      _food += @policy[:welfare]
      @food_storage -= @policy[:welfare]
      # 6. done
      citizen.food += _food
      return _food
    end
  
    def citizen_take_hungry_action(citizen)
      # 1. get alms
      _food = -@city_level
      _food += @policy[:alms]
      @food_storage -= @policy[:alms]
      # done
      citizen.food += _food
    end
  
    def citizen_train_model
      return if @action_values.all?(nil)
      mean, std = Math.mean_and_std(@action_values.compact)
      @citizen.zip(@action_values) do |c, v|
        next if v.nil?
        if v > mean + c.sigma * std
          c.train(1)
        elsif v < mean - c.sigma * std
          c.train(0)
        end
      end
    end
  
    # -----------------------------------
    # policy
    # -----------------------------------
    def set_policy(hsh = {})
      hsh.each_pair do |key, value|
        case key
        when :alms then @policy[:alms] = value
        when :welfare then @policy[:welfare] = value
        when :action then @policy[:action][0..2] = value if value.size == 3
        end
      end
    end
  
    def set_policy_human()
      puts "cmd: u a d p"
      loop do
        k, v = gets.chop.split("=")
        break if k.nil?
  
        if k.start_with?("p")
          case k
          when "pa" then @policy[:alms] = v.to_f
          when "pw" then @policy[:welfare] = v.to_f
          when /p(\d+)/
            @policy[:action][$1.to_i] = v.to_f
          else
            puts "cmd pa=xxx for alms"
            puts "cmd pw=xxx for welfare"
            puts "cmd pi=x for action [i], i is int"
            next
          end
        else
          case k
          when "u" then levelup_city
          when "a"
            c = Citizen.new(@citizen.collect(&:id).max + 1)
            c.ability = [rand, rand, rand] * @city_level
            add_citizen(c)
          when "d"
            c = @citizen[v.to_i]
            del_citizen(c)
            @action_values.delete_at(v.to_i)
          end
        end
        render
      end
    end
  
    # -----------------------------------
    # render
    # -----------------------------------
    def render
      # city
      puts "-" * 50
      puts "City #{@id}: Lv. #{@city_level.to_i}"
      puts "-" * 50
      puts ""
      puts "People: #{population}"
      puts "Food: #{@food_storage}"
      puts "Daily Food: #{daily_food * population}"
      puts "Farm Level: %.2f" % @farm_level
      puts "Upgrade: %.2f" % @city_upgrade
      puts "Alms: %.2f" % @policy[:alms]
      puts "Welfare: %.2f" % @policy[:welfare]
      puts ""
      # citizen
      puts "Citizen: "
      @citizen.each_with_index do |c, index|
        if @action_values[index]
          puts c.render
        else
          puts c.render(true)
        end
      end
      # actions
      puts "Actions: "
      self.actions.each_with_index do |action, index|
        puts "  %d. %-16s [%.2f %.2f %.2f] %.2f" % [
          index + 1, action.description, *action.features, @policy[:action][index],
        ]
      end
      puts ""
    end
  end
  
  class Citizen
    attr_accessor :id
    attr_accessor :food
    attr_accessor :ability
    attr_accessor :agent
  
    def initialize(id)
      @id = id
      @food = 0
      @ability = [0.0, 0.0, 0.0]
      # Agent
      @agent = Agent_Citizen.new
      @last_action = nil
      @last_action_prob = 0.0
    end
  
    def sigma
      @agent.sigma
    end
  
    def train(score)
      @agent.train_model(score, @last_action, @last_action_prob)
    end
  
    def make_action_id(actions)
      probs = @agent.make_action_probs(actions)
      action_id = Math.random_by_prob(probs)
      @last_action = actions[action_id]
      @last_action_prob = probs[action_id]
      return action_id
    end
  
    def render(hungry = false)
      str = <<~render
        %2d. F: %4.2f, A: [%4.2f, %4.2f, %4.2f] | %-16s | %.2f
      render
      if hungry
        data = [@id, @food, *@ability, "!! HUNGRY !!", 0.0]
      else
        data = [@id, @food, *@ability, @last_action.description, @last_action_prob]
      end
      return str.strip % data
    end
  end
  
  class Agent_Citizen < Agent_Base
    def initialize
      super
    end
  end
  