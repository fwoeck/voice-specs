class RemoteRequest

  attr_accessor :id, :verb, :klass, :params, :req_from, :res_to, :value, :status, :error


  class << self

    def new_request_id
      BSON::ObjectId.new.to_s
    end


    def rpc_to_custom(*args)
      rpc_to_service(:custom, *args)
    end


    def rpc_to_service(target, klass, verb, params=[])
      id      = new_request_id
      request = build_fom(id, verb, klass, params)

      AmqpManager.publish_to target, Marshal.dump(request)
    end


    def build_fom(id, verb, klass, params)
      RemoteRequest.new.tap { |r|
        r.id       =  id
        r.verb     =  verb
        r.klass    =  klass
        r.params   =  params
        r.req_from = 'voice.rails'
      }
    end
  end
end
