AgentMutex = Mutex.new

class Agent

  attr_accessor :id, :name, :languages, :skills, :activity, :visibility, :call_id,
                :locked, :availability, :idle_since, :mutex, :unlock_scheduled


  def initialize(_id, _name, _activity)
    @id       = _id
    @name     = _name
    @activity = _activity
  end


  def activity_keyname
    "#{SpecConfig['rails_env']}.activity.#{self.id}"
  end


  def store_activity
    RPool.with { |con|
      con.set(activity_keyname, activity, {ex: 1.week})
    }
  end


  def self.with_agent
    agent = checkout_agent
    yield agent
    checkin_agent(agent)
  end


  def self.checkout_agent
    AgentMutex.synchronize {
      id   = idle_ids.sample
      name = id ? User.agent_names[id] : nil

      new(id, name, 'undefined').tap { |a| a.store_activity } if id
    }
  end


  def self.checkin_agent(agent)
    return unless agent

    AgentMutex.synchronize {
      agent.activity = 'silent'
      agent.store_activity
    }
  end


  def self.idle_ids
    RPool.with { |con|
      con.keys(activity_pattern).map { |key| con.get(key) == 'silent' && key }
         .select { |key| key }.map { |key| key[/\d+$/].to_i }
    }
  end


  def self.activity_pattern
    "#{SpecConfig['rails_env']}.activity.*"
  end
end
