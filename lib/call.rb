class Call

  FORMAT = %w{call_id call_tag origin_id language skill extension caller_id hungup called_at mailbox queued_at hungup_at dispatched_at}
           .map(&:to_sym)

  attr_accessor *FORMAT


  def initialize(par={})
    FORMAT.each do |sym|
      self.send "#{sym}=", par.fetch(sym, nil)
    end
  end


  def call_keyname
    "#{SpecConfig['rails_env']}.call.#{call_id}"
  end


  def store_dump(dump)
    RPool.with { |con|
      con.set(call_keyname, dump, {ex: 10.minutes})
    }
  end


  def rewrite_history(tm, dt)
    tap { |c|
      c.origin_id = c.origin_id.sub(/[^-]+$/, tm) if c.origin_id

      [:called_at, :queued_at, :hungup_at, :dispatched_at
      ].each { |sym|
        c.send("#{sym}=", c.send(sym) + dt) if c.send(sym)
      }
    }
  end
end
