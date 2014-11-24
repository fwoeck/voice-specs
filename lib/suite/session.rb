class Session

  attr_reader :admin_name, :admin_email, :admin_pass, :agents,
              :agent1_id, :agent2_id, :all_sessions

  include Helpers
  include FormHelpers
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


  def read_exit_confirmation
    return if ENV['BATCH_RUN']

    if ENV['RUN_PRY']
      binding.pry
    else
      puts 'Press a key to close all sessions and exit.'
      STDIN.getch
    end
  end


  def start
    login_as_admin

    create_agents
    check_form_validation

    login_as_agent(1)
    login_as_agent(2)
    send_chat_message

    update_my_settings_as(1)
    as_admin_grant_agent(2)
    as_admin_revoke_agent(2)

    create_fake_customers(10)
    # replay 2 event chains

    read_exit_confirmation
  rescue => e
    debug_error(e)
  ensure
  # Capybara.reset_sessions!
  end
end
