require 'connection_pool'
require 'sequel'
require 'redis'


RPool = ConnectionPool.new(size: 5, timeout: 3) {
  Redis.new(
    host: SpecConfig['redis_host'],
    port: SpecConfig['redis_port'],
    db:   SpecConfig['redis_db']
  )
}


MysqlDb = Sequel.connect(
  "mysql2://#{SpecConfig['mysql_user']}:#{SpecConfig['mysql_pass']}@" +
  "#{SpecConfig['mysql_host']}:#{SpecConfig['mysql_port']}/#{SpecConfig['mysql_db']}"
)
