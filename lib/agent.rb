class Agent

  attr_accessor :id, :name, :languages, :skills, :activity, :visibility, :call_id,
                :locked, :availability, :idle_since, :mutex, :unlock_scheduled


  def activity_keyname
    "#{SpecConfig['rails_env']}.activity.#{self.id}"
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
