class Customer
  include Mongoid::Document
  CustMutex = Mutex.new


  field :email,      type: String,   default: ""
  field :full_name,  type: String,   default: ""
  field :caller_ids, type: Array,    default: -> { [] }
  field :crmuser_id, type: String,   default: ""
  field :created_at, type: DateTime, default: -> { Time.now.utc }


  def self.with_customer
    sleep 1 while !(cust = checkout_customer)
    yield cust
  ensure
    checkin_customer(cust)
  end


  def self.checkout_customer
    CustMutex.synchronize {
      all_numbers.delete all_numbers.sample
    }
  end


  def self.checkin_customer(cust)
    return unless cust

    CustMutex.synchronize {
      all_numbers << cust
    }
  end


  def self.all_numbers
    @_memo_all_numbers ||= only(:caller_ids).to_a.map(&:caller_ids)
                          .flatten.uniq - [Agent::AdminName]
  end
end
