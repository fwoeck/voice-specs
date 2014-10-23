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


  def rewrite_call_id
    return unless obj.call_id
    obj.call_id = obj.call_id.sub(/[^-]+$/, tm)
  end


  def interpolate_current_data(lo, agent)
    @obj = lo.data

    rewrite_call_id
    obj.rewrite_extensions(agent)
    obj.rewrite_timestamps(tm, dt) if obj.is_a?(Call)
  end


  def store_object_in_redis
    @dump = Marshal.dump(obj)

    obj.store_activity   if obj.is_a?(Agent)
    obj.store_dump(dump) if obj.is_a?(Call)
  end


  def replay_capture_data_with(agent)
    log.each_with_index { |lo, idx|
      interpolate_current_data(lo, agent)
      sleep 0.01 while lo.time + dt > Time.now

      store_object_in_redis
      AmqpManager.publish(dump, lo.custom, lo.numbers)
      print "Replay message #{idx + 1}/#{log.size} for ##{agent.name}\n"
    }
  end


  def start
    Agent.with_agent { |agent|
      if agent
        print "Checkout agent ##{agent.name}\n"
        replay_capture_data_with(agent)
        print "Checkin agent ##{agent.name}\n"
      else
        # TODO playback rejection
      end
    }
  end


  def self.start(count=1)
    threads = []

    count.times do
      sleep 0.1
      threads << Thread.new { YmlPlayer.new.start }
    end
    threads.map(&:join)
  end
end
