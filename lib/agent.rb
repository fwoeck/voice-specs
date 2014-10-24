class Agent
  AgentName  = '101' # Original extensions from yml recording
  AdminName  = '999' #
  AgentMutex =  Mutex.new

  attr_accessor :id, :name, :activity, :visibility, :call_id, :availability
  attr_writer   :languages, :skills


  def initialize(_id, _name)
    @id   = _id
    @name = _name
  end


  def languages
    RPool.with { |con| con.smembers(language_keyname) }
  end


  def skills
    RPool.with { |con| con.smembers(skill_keyname) }
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


  def rewrite_extensions(agent, _cust)
    return if name == AdminName

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
      id   = User.agent_names.keys.sample
      name = id ? User.agent_names.delete(id) : nil

      new(id, name) if id
    }
  end


  def self.checkin_agent(agent)
    return unless agent

    AgentMutex.synchronize {
      User.agent_names[agent.id] = agent.name
    }
  end


  private

  def language_keyname
    "#{SpecConfig['rails_env']}.languages.#{self.id}"
  end


  def skill_keyname
    "#{SpecConfig['rails_env']}.skills.#{self.id}"
  end


  def activity_keyname
    "#{SpecConfig['rails_env']}.activity.#{self.id}"
  end
end
