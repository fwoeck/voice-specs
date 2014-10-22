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


  def interpolate_current_data(lo)
    @obj = lo.data

    rewrite_call_id
    obj.rewrite_history(tm, dt) if obj.is_a?(Call)
  end


  def store_object_in_redis
    @dump = Marshal.dump(obj)

    obj.store_activity   if obj.is_a?(Agent)
    obj.store_dump(dump) if obj.is_a?(Call)
  end


  def replay_capture_data
    log.each_with_index { |lo, idx|
      interpolate_current_data(lo)
      sleep 0.01 while lo.time + dt > Time.now

      store_object_in_redis
      AmqpManager.publish(dump, lo.custom, lo.numbers)
      puts "Replay message #{idx + 1}/#{log.size}"
    }
  end


  def start
    Agent.with_agent do |agent|
      if agent
        puts "Checkout agent ##{agent.id}"
        replay_capture_data
        puts "Checkin agent ##{agent.id}"
      else
        # TODO playback rejection
      end
    end
  end
end
