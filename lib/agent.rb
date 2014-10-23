class Agent
  RecordedName = '101' # Original extension from yml recording
  AgentMutex   = Mutex.new

  attr_accessor :id, :name, :languages, :skills, :activity, :visibility, :call_id,
                :locked, :availability, :idle_since, :mutex, :unlock_scheduled


  def initialize(_id, _name, _activity)
    @id       = _id
    @name     = _name
    @activity = _activity
  end


  def store_activity
    RPool.with { |con|
      con.set(activity_keyname, activity, {ex: 1.week})
    }
  end


  def rewrite_call_id(tm)
    return unless call_id
    self.call_id = call_id.sub(/[^-]+$/, tm)
  end


  def rewrite_extensions(agent)
    return if name == SpecConfig['admin_name']

    self.id   = agent.id
    self.name = agent.name
  end


  def self.with_agent
    sleep 1 while !(agent = checkout_agent)
    yield agent
  ensure
    checkin_agent(agent)
  end


  def self.checkout_agent
    AgentMutex.synchronize {
      id   = (User.agent_names.keys & idle_ids).sample
      name = id ? User.agent_names[id] : nil

      new(id, name, 'undefined').tap { |a| a.store_activity } if id
    }
  end


  def self.checkin_agent(agent)
    return unless agent

    agent.activity = 'silent'
    agent.store_activity
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


  private

  def activity_keyname
    "#{SpecConfig['rails_env']}.activity.#{self.id}"
  end
end
