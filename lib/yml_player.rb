class YmlPlayer
  attr_reader :log, :tn, :tm, :t0, :dt


  def initialize(filename='./fixtures/successful-call.yml')
    @log = YAML.load_file(filename)
    log.each { |lo| lo.data = Marshal.load(lo.data) }

    @tn = Time.now
    @tm = Digest::MD5.hexdigest(tn.to_f.to_s)[0..11]
    @t0 = log.first.time
    @dt = tn - t0
  end


  def rewrite_history_for_call(lo)
    lo.data.tap { |d|
      d.origin_id = d.origin_id.sub(/[^-]+$/, tm) if d.origin_id

      [:called_at, :queued_at, :hungup_at, :dispatched_at
      ].each { |sym|
        d.send("#{sym}=", d.send(sym) + dt) if d.send(sym)
      }
    }
  end


  def update_redis_for_agent(lo)
    RPool.with { |con|
      con.set(lo.data.activity_keyname, lo.data.activity, {ex: 1.week})
    }
  end


  def update_redis_for_call(lo, dump)
    RPool.with { |con|
      con.set(lo.data.call_keyname, dump, {ex: 10.minutes})
    }
  end


  def rewrite_call_id_for(lo)
    return unless lo.data.call_id
    lo.data.call_id = lo.data.call_id.sub(/[^-]+$/, tm)
  end


  def start
    log.each_with_index { |lo, idx|
      sleep 0.01 while lo.time + dt > Time.now

      rewrite_call_id_for(lo)
      rewrite_history_for_call(lo) if lo.data.is_a?(Call)
      update_redis_for_agent(lo)   if lo.data.is_a?(Agent)

      dump = Marshal.dump(lo.data)
      update_redis_for_call(lo, dump) if lo.data.is_a?(Call)

      AmqpManager.publish(dump, lo.custom, lo.numbers)
      puts "Replay message #{idx + 1}/#{log.size}"
    }
  end
end
