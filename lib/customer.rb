class Customer
  include Mongoid::Document


  field :email,      type: String,   default: ""
  field :full_name,  type: String,   default: ""
  field :caller_ids, type: Array,    default: -> { [] }
  field :crmuser_id, type: String,   default: ""
  field :created_at, type: DateTime, default: -> { Time.now.utc }


  def self.all_numbers
    @_memo_all_numbers ||= only(:caller_ids).to_a.map(&:caller_ids).flatten.uniq - [Agent::AdminName]
  end
end
