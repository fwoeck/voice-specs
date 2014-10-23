class YmlPlayer
  attr_reader :log, :tn, :tm, :t0, :dt, :obj, :dump


  def initialize(filename='./fixtures/successful-call.yml')
    @log = YAML.load_file(filename)
    log.each { |lo| lo.data = Marshal.load(lo.data) }

    @tn = Time.now
    @tm = Digest::MD5.hexdigest(tn.to_f.to_s)[0..11]
    @t0 = log.first.time
    @dt = tn - t0
  end


  # TODO Set skill according to current agent
  #
  def skill
    @memo_skill ||= SpecConfig['skills'].keys.sample
  end


  # TODO Set lang according to current agent
  #
  def lang
    @memo_lang ||= SpecConfig['languages'].keys.sample
  end


  def interpolate_current_data(agent)
    obj.rewrite_call_id(tm)
    obj.rewrite_extensions(agent)

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


  def send_messages_for(agent, lo)
    interpolate_current_data(agent)
    sleep 0.01 while lo.time + dt > Time.now

    store_object_in_redis
    AmqpManager.publish(dump, lo.custom, lo.numbers)
  end


  def replay_capture_data_with(agent)
    log.each_with_index { |lo, idx|
      @obj = lo.data
      send_messages_for(agent, lo)
      print "Replay message #{idx + 1}/#{log.size} for ##{agent.name}\n"
    }
  end


  def start
    Agent.with_agent { |agent|
      print "Checkout agent ##{agent.name}\n"
      replay_capture_data_with(agent)
      print "Checkin agent ##{agent.name}\n"
    }
  end


  def self.start(count=1)
    threads = []

    count.times do
      sleep rand(10)
      threads << Thread.new { YmlPlayer.new.start }
    end
    threads.map(&:join)
  end
end
