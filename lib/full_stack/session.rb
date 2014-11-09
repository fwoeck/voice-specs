class Session

  include Helpers
  include Capybara::DSL
  include RSpec::Matchers


  def setup
    system 'CONFIRM_DELETE=1 ./script/wipe-all-dbs'
  end


  def start
    use_client(100)
    visit_home_url
    login_as('frank.woeckener@wimdu.com')

    use_client(101)
    visit_home_url
    login_as('eldridge-shanahan@mail.com')

    use_client(103)
    visit_home_url
    login_as('anika-borer@mail.com')
  rescue => e
    puts e.message
  ensure
    Capybara.reset_sessions!
  end
end
