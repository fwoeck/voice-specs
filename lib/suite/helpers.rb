POS    =  Struct.new(:x, :y)
ALL    = 'Voice.store.all'
GET    = 'Voice.store.getById'
POS_N  = [0, 1, 2, 3, 4, 5].cycle
DIALOG = 'Voice.dialogController'


module Helpers

  def log(text)
    puts "#{Time.now.utc} :: #{text}" unless ENV['BATCH_RUN']
  end


  def wait_for_ajax
    sleep 0.05
    Timeout.timeout(Capybara.default_wait_time) do
      loop until finished_all_ajax_requests?
    end
  end


  def finished_all_ajax_requests?
    page.evaluate_script('jQuery.active').zero?
  end


  def expect_with_retry(val, n=3, &block)
    expect(block.call).to eql val
  rescue RSpec::Expectations::ExpectationNotMetError => e
    sleep 0.2
    n -= 1
    n > 0 ? retry : raise(e)
  end


  def debug_error(err)
    puts err.message
    puts err.backtrace
    read_exit_confirmation
  end


  def t(key)
    page.evaluate_script("i18n.#{key}")
  end


  def expect_js(line)
    eval_js(line, :logging)
  end


  def eval_js(line, logging=false)
    page.evaluate_script("Ember.run(function () { return #{line}; })").tap { |res|
      log "Eval #{line} == #{res}" if logging
    }
  end


  def exec_js(line)
    page.execute_script "Ember.run(function () { #{line}; })"
  end


  def wait_for_active_dialog
    Timeout.timeout(Capybara.default_wait_time) do
      loop until eval_js("#{DIALOG}.get('isActive')")
    end
  end


  def accept_dialog(check=false)
    log 'Accept the dialog.'

    wait_for_active_dialog if check
    exec_js "#{DIALOG}.accept()"
  end


  def cancel_dialog
    log 'Cancel the dialog.'

    wait_for_active_dialog
    exec_js "#{DIALOG}.cancel()"
  end


  def expect_dialog_message(msg)
    log "Expect the dialog to say \"#{msg}\"."

    wait_for_active_dialog
    expect(find '#dialog_wrapper').to have_text msg
  end


  def visit_home_url
    log 'Visit the root url.'

    visit '/'
    resize_browser(1100, 900)
  end


  def use_client(num)
    log "Use the browser session #{num}."

    all_sessions.add num
    Capybara.session_name = num
    sleep 0.5
  end


  def login_as(email, password='P4ssw0rd')
    log "Login with the email address #{email}."

    fill_in 'user[email]',    with: email
    fill_in 'user[password]', with: password
    click_button 'Log in' # TODO translate this

    expect(expect_js('env.userId').to_i).to be > 0
  end


  def resize_browser(width, height)
    pos    = POS_N.next
    window = Capybara.current_session.driver.browser.manage.window

    window.resize_to(width, height)
    window.position = POS.new(10 + 200 * pos, 40 + 100 * pos)
  end


  def wipe_dbs
    log 'Prepare the database environment.'
    system 'CONFIRM_DELETE=1 ./script/wipe-all-dbs'
  end


  def wait_for_puma
    log 'Wait for the web server.'
    while `lsof -i :#{SpecConfig['puma_port']} | grep LISTEN | wc -l`.to_i < 1
      sleep 1
    end
  end


  def activate_dashboard
    log 'Activate the Dashboard.'
    activate_tab_for('headers.dashboard', 'index')
  end


  def activate_customers_tab
    log 'Activate the Customers tab.'
    activate_tab_for('headers.customers', 'customers')
  end


  def activate_agents_tab
    log 'Activate the Agent List.'
    activate_tab_for('headers.agent_list', 'agents')
  end


  def activate_statistics_tab
    log 'Activate the Call Statistics.'
    activate_tab_for('headers.call_statistics', 'stats')
  end


  def activate_tab_for(name, path)
    click_link(t name)
    sleep 0.1
    expect(
      expect_js "Voice.get('currentPath')"
    ).to eql path
  end


  def get_agent_id_for(num)
    expect(aid = expect_js(
      "#{ALL}('user').findProperty('name', '#{agents[num][:ext]}').get('id')"
    ).to_i).to be > 1

    [num, aid]
  end


  def translation_for_skill(val)
    eval_js("env.skills.#{val}[env.locale]")
  end


  def login_as_admin
    use_client admin_name
    visit_home_url
    login_as admin_email, admin_pass
  end


  def login_as_agent(num)
    use_client agents[num][:ext]
    visit_home_url
    login_as agents[num][:email], agents[num][:pass]
  end


  def user_count
    expect_js "#{ALL}('user').get('length')"
  end


  def ui_locales
    eval_js('env.uiLocales')
  end


  def current_locale
    eval_js('env.locale')
  end


  def with_all_sessions(&block)
    all_sessions.each do |num|
      use_client num
      block.call
    end
  end


  def send_chat_message(msg='Hello chat!')
    use_client admin_name
    activate_dashboard
    fillin_chat_input_with(msg)
  end


  def fillin_chat_input_with(msg)
    log "Send a chat message with \"#{msg}\"."
    fill_in 'chat_message', with: msg + "\n"

    with_all_sessions do |num|
      expect(
        expect_js "#{ALL}('chatMessage').get('firstObject.content')"
      ).to eql(msg)
    end
  end


  def check_user_record_for(num, name=nil)
    aid = agents[num][:id]

    with_all_sessions do
      expect(expect_js "#{GET}('user', #{aid}).get('fullName')").to eql(name) if name
      check_user_validity_for(aid)
    end
  end


  def check_user_validity_for(aid)
    [ ['isNew',    false], ['isDirty', false],
      ['isLoaded', true],  ['isValid', true]
    ].each { |key, val|
      expect(expect_js "#{GET}('user', #{aid}).get('#{key}')" ).to eql(val)
    }
  end


  def create_fake_customers(num=1)
    system "curl -s 'https://127.0.0.1/seed/customers?count=#{num}'"
  end
end
