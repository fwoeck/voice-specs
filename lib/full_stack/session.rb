class Session

  attr_reader :admin_name, :admin_email, :admin_pass

  include Helpers
  include Capybara::DSL
  include RSpec::Matchers


  def initialize
    @admin_email = SpecConfig['admin_email']
    @admin_name  = SpecConfig['admin_name']
    @admin_pass  = SpecConfig['admin_pass']
  end


  def setup
    wipe_dbs
    wait_for_puma
  end


  def start
    use_client admin_name
    visit_home_url
    login_as admin_email, admin_pass
  rescue => e
    puts e.message
  ensure
    Capybara.reset_sessions!
  end
end
