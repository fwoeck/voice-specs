class Call

  FORMAT = %w{call_id call_tag origin_id language skill extension caller_id hungup called_at mailbox queued_at hungup_at dispatched_at}
           .map(&:to_sym)

  attr_accessor *FORMAT


  def initialize(par={})
    FORMAT.each do |sym|
      self.send "#{sym}=", par.fetch(sym, nil)
    end
  end


  def store_dump(dump)
    RPool.with { |con|
      con.set(call_keyname, dump, {ex: 10.minutes})
    }
  end


  def rewrite_call_id(tm)
    return unless call_id
    self.call_id = call_id.sub(/[^-]+$/, tm)
  end


  def rewrite_timestamps(tm, dt)
    self.origin_id = origin_id.sub(/[^-]+$/, tm) if origin_id

    [:called_at, :queued_at, :hungup_at, :dispatched_at
    ].each { |sym|
      send("#{sym}=", send(sym) + dt) if send(sym)
    }
  end


  def rewrite_menu_choice(lang, skill)
    self.language = lang
    self.skill    = skill
  end


  def rewrite_extensions(agent)
    [:call_tag, :extension, :caller_id].each { |sym|
      send "#{sym}=", interpolate_names_for(send(sym), agent)
    }
  end


  private

  def call_keyname
    "#{SpecConfig['rails_env']}.call.#{call_id}"
  end


  def interpolate_names_for(field, agent)
    return unless field

    field.sub(SpecConfig['admin_name'], '03022446688')
         .sub(Agent::RecordedName, agent.name)
  end
end
