class YmlPlayer
  attr_reader :log, :tn, :tm, :t0, :dt, :obj, :dump, :agent, :cust


  def initialize(filename='./fixtures/successful-call.yml')
    @log = YAML.load_file(filename)
    log.each { |lo| lo.data = Marshal.load(lo.data) }

    @tn = Time.now
    @tm = Digest::MD5.hexdigest(tn.to_f.to_s)[0..11]
    @t0 = log.first.time
    @dt = tn - t0
  end


  def skill
    @memo_skill ||= agent.skills.sample
  end


  def lang
    @memo_lang ||= agent.languages.sample
  end


  def interpolate_sample_data
    obj.rewrite_call_id(tm)
    obj.rewrite_extensions(agent, cust)

    if obj.is_a?(Call)
      obj.rewrite_timestamps(tm, dt)
      obj.rewrite_menu_choice(lang, skill)
    end
  end


  def store_object_in_redis
    @dump = Marshal.dump(obj)

    obj.store_activity   if obj.is_a?(Agent)
    obj.store_dump(dump) if obj.is_a?(Call)
  end


  def send_messages_for(lo)
    interpolate_sample_data
    sleep 0.01 while lo.time + dt > Time.now

    store_object_in_redis
    AmqpManager.publish(dump, lo.custom, lo.numbers)
  end


  def replay_capture_data
    log.each_with_index { |lo, idx|
      @obj = lo.data
      send_messages_for(lo)
      print "Emit message #{'%02d' % (idx+1)}/#{log.size} for ##{agent.name}\n"
    }
  end


  def start
    Agent.with_agent { |_agent|
      Customer.with_customer { |_cust|
        @cust  = _cust
        @agent = _agent

        print "Replay agent ##{agent.name} with caller ##{cust}\n"
        replay_capture_data
        print "Finish agent ##{agent.name} with caller ##{cust}\n"
      }
    }
  end


  def self.start(count=1)
    threads = []

    count.times do |idx|
      sleep rand(4)
      print "Start call ##{'%04d' % (idx+1)}\n"
      threads << Thread.new { YmlPlayer.new.start }
    end
    threads.map(&:join)
  end
end
