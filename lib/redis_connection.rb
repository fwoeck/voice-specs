require 'connection_pool'
require 'redis'


RPool = ConnectionPool.new(size: 5, timeout: 3) {
  Redis.new(
    host: SpecConfig['redis_host'],
    port: SpecConfig['redis_port'],
    db:   SpecConfig['redis_db']
  )
}
