class User < Sequel::Model

  def self.agent_names
    @@agent_names ||= exclude(name: SpecConfig['admin_name']).select(:id, :name)
      .inject({}) { |hash, ds| hash[ds.id] = ds.name; hash }
  end
end
