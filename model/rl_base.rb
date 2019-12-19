# encoding: utf-8
# ---------------------------------------------------------
# Math supplement
# ---------------------------------------------------------
module Math
    module_function
  
    def softmax(array, beta)
      s = array.sum { |a| exp(a * beta) }
      return array.collect { |a| exp(a * beta) / s }
    end
  
    def mean_and_std(array)
      mean = array.sum / array.size
      d = array.sum { |a| (a - mean) * (a - mean) } / array.size
      return mean, sqrt(d)
    end
  
    def random_normal
      u, v = rand, rand
      x = sqrt(-2 * log(u)) * cos(2 * PI * v)
      # y = sqrt(-2 * log(u)) * sin(2 * PI * v)
      return x
    end
  
    def random_by_prob(array)
      r = rand * array.sum
      array.each_with_index { |a, i|
        r -= a
        return i if r < 0
      }
    end
  end
  
  # ---------------------------------------------------------
  # Action Base
  # ---------------------------------------------------------
  Action = Struct.new(:kind, :features, :description)
  
  # ---------------------------------------------------------
  # Env Base
  # ---------------------------------------------------------
  class Env_Base
    attr_reader :agents
  
    def initialize
      @counts = 0
      @exit = false
      @agents = []
      @values = []
    end
  
    def main
      reset
      loop do
        env_prepare
        agent_make_choice
        env_take_action
        agent_train_model
        break if @exit
      end
    end
  
    def reset
    end
  
    def env_prepare
      @counts += 1
    end
  
    def agent_make_choice
      @agents.each { |agent|
        _env_actions = self.env_actions
        probs = agent.make_action_probs(_env_actions)
        action_id = Math.random_by_prob(probs)
        agent.last_action = _env_actions[action_id]
        agent.last_action_prob = probs[action_id]
      }
    end
  
    def env_take_action
      @values.clear
      @agents.each { |agent|
        action = agent.last_action
        @values << 0
      }
    end
  
    def env_actions
      []
    end
  
    def agent_train_model
      mean, std = Math.mean_and_std(@values)
  
      @agents.each_with_index { |agent, index|
        action_value = @values[index]
  
        if action_value > mean + std * agent.sigma
          agent.train_model(1)
        elsif action_value < mean - std * agent.sigma
          agent.train_model(0)
        end
      }
    end
  end
  
  # ---------------------------------------------------------
  # Agent Base
  # ---------------------------------------------------------
  class Agent_Base
    attr_reader :weights
    attr_accessor :model
  
    attr_accessor :last_action
    attr_accessor :last_action_prob
  
    def initialize()
      @weights = {}
      @model = { alpha: 1.0, beta: 1.0, lambda: 0.0, sigma: 0.5 }
    end
  
    def random_weights(n)
      return [0] + n.times.collect { rand * 2 - 1 }
    end
  
    def estimate(action)
      k, fs = action.kind, action.features
      @weights[k] ||= random_weights(fs.size)
      score = ([1] + fs).zip(@weights[k]).sum { |f, w| f * w }
    end
  
    def make_action_probs(actions)
      scores = actions.collect { |action| self.estimate(action) }
      probs = Math.softmax(scores, beta)
      return probs
    end
  
    def train_model(target, action = self.last_action, prob = self.last_action_prob)
      k, fs = action.kind, action.features
      d = alpha * prob * (1 - prob) * (target - prob)
      l = lambda
      ([1] + fs).each_with_index { |f, i|
        w = @weights[k][i]
        @weights[k][i] += d * f - l * w
      }
    end
  
    # Hyper Parameters
    def alpha
      @model[:alpha]
    end
  
    def beta
      @model[:beta]
    end
  
    def lambda
      @model[:lambda]
    end
  
    def sigma
      @model[:sigma]
    end
  end
  