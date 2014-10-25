TOPICS      = [:rails, :numbers, :custom, :ahn]
LogObject   = Struct.new(:time, :data, :custom, :numbers)
MESSAGE_LOG = []


class AmqpManager
  include Celluloid

  TOPICS.each { |name|
    class_eval %Q"
      def #{name}_channel
        @#{name}_channel ||= connection.create_channel
      end
    "

    class_eval %Q"
      def #{name}_xchange
        @#{name}_xchange ||= #{name}_channel.topic('voice.#{name}', auto_delete: false)
      end
    "

    class_eval %Q"
      def #{name}_queue
        @#{name}_queue ||= #{name}_channel.queue('voice.#{name}', auto_delete: false)
      end
    "
  }


  def publish(data, incl_custom, incl_numbers)
    publish_to(:rails,   data)
    publish_to(:custom,  data) if incl_custom
    publish_to(:numbers, data) if incl_numbers
  end


  def publish_to(target, data)
    self.send("#{target}_xchange").publish(data, routing_key: "voice.#{target}")
  end


  def connection
    establish_connection unless @@connection
    @@connection
  end


  def shutdown
    connection.close
  end


  def establish_connection
    @@connection = Bunny.new(
      host:     SpecConfig['rabbit_host'],
      user:     SpecConfig['rabbit_user'],
      password: SpecConfig['rabbit_pass']
    ).tap { |c| c.start }
  rescue Bunny::TCPConnectionFailed
    sleep 1
    retry
  end


  def start
    establish_connection
  end


  class << self

    def start
      Celluloid.logger = nil
      Celluloid::Actor[:amqp] = AmqpManager.pool(size: 32)
      @@manager ||= new.tap { |m| m.start }
    end


    def shutdown
      @@manager.shutdown
    end


    def publish(*args)
      @@manager.publish(*args)
    end


    def publish_to(*args)
      @@manager.publish_to(*args)
    end
  end
end
