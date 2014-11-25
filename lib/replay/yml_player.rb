require 'thread'

class YmlPlayer
  SyncQueues = ThreadSafe::Array.new

  attr_reader :log, :tn, :tm, :t0, :dt, :obj,
              :dump, :agent, :cust, :queue


  def initialize(filename='./fixtures/successful-call.yml')
    @queue = Queue.new
    SyncQueues << queue

    @log = YAML.load_file(filename)
    log.each { |lo| lo.data = Marshal.load(lo.data) }
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
    wait_for_next_step(lo)

    store_object_in_redis
    print obj.inspect + "\n" if ENV['DEBUG']
    AmqpManager.publish(dump, lo.custom, lo.numbers)
  end


  def wait_for_next_step(lo)
    if ENV['SYNC_STEPS']
      queue.pop
    else
      sleep 0.01 while lo.time + dt > Time.now
    end
  end


  def replay_capture_data
    log.each_with_index { |lo, idx|
      @obj = lo.data
      send_messages_for(lo)
      print "Emit message #{'%02d' % (idx+1)}/#{log.size} for ##{agent.name}\n"
    }
  end


  def tag_history_entry
    Customer.rpc_update_history_with(
      user_id:     agent.id,
      tags:        fake_tags,
      remarks:     Faker::Lorem.sentence(3, true, 20),
      customer_id: Customer.where(caller_ids: cust).first.id
    )
  end


  def fake_tags
    [ SpecConfig['languages'].keys.sample.upcase,
      SpecConfig['skills'].keys.sample.sub('_', '-'),
      SpecConfig['default_tags'].keys.sample
    ]
  end


  def reset_data_for(_cust, _agent)
    @cust  = _cust
    @agent = _agent

    @tn = Time.now
    @tm = Digest::MD5.hexdigest((rand(0.9) + tn.to_f).to_s)[0..11]
    @t0 = log.first.time
    @dt = tn - t0
  end


  def start
    Agent.with_agent { |_agent|
      Customer.with_customer { |_cust|
        reset_data_for(_cust, _agent)

        print "Replay agent ##{agent.name} with caller ##{cust}\n"
        replay_capture_data
        tag_history_entry
        print "Finish agent ##{agent.name} with caller ##{cust}\n"
        SyncQueues.delete(queue)
      }
    }
  end


  def self.trigger_next_step
    STDIN.readline
    SyncQueues.each { |q| q.push 1 }
  end


  def self.sync_steps
    Thread.new {
      sleep 0.05
      trigger_next_step while SyncQueues.size > 0
    }
  end


  def self.start(count=1)
    threads = []

    count.times do |idx|
      threads << Thread.new { YmlPlayer.new.start }
    end

    sync_steps if ENV['SYNC_STEPS']
    threads.map(&:join)
  end
end
