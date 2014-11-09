class Session

  attr_reader :admin_name, :admin_email, :admin_pass, :agents,
              :agent1_id, :agent2_id, :all_sessions

  include Helpers
  include Capybara::DSL
  include RSpec::Matchers

  LANGS  = SpecConfig['languages'].keys.cycle
  SKILLS = SpecConfig['skills'].keys.cycle


  def initialize
    @all_sessions = Set.new
    @admin_email  = SpecConfig['admin_email']
    @admin_name   = SpecConfig['admin_name']
    @admin_pass   = SpecConfig['admin_pass']

    @agents = [{},
      { ext:    '101',
        pass:   'P4ssw0rd',
        name:   'Anna Agent',
        email:  'anna-agent@mail.com',
        langs:  [LANGS.next, LANGS.next].uniq,
        skills: [SKILLS.next, SKILLS.next].uniq
      },
      { ext:    '102',
        pass:   'P4ssw0rd',
        name:   'Arnold Agent',
        email:  'arnold-agent@mail.com',
        langs:  [LANGS.next, LANGS.next].uniq,
        skills: [SKILLS.next, SKILLS.next].uniq
      }
    ]
  end


  def setup
    wipe_dbs
    wait_for_puma
  end


  def start
    login_as_admin
    create_agents
    login_as_agent(1)
    login_as_agent(2)
    send_chat_message('Hello!')
  sleep 30
  rescue => e
    puts e.message
  ensure
    Capybara.reset_sessions!
  end
end
