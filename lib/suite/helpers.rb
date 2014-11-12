module Helpers
  ALL = 'Voice.store.all'


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


  def debug_error(err, timeout=180)
    puts err.message
    puts err.backtrace
    sleep timeout
  end


  def t(key)
    page.evaluate_script("i18n.#{key}")
  end


  def eval_js(line)
    page.evaluate_script line
  end


  def accept_dialog
    page.execute_script 'Voice.dialogController.accept()'
  end


  def cancel_dialog
    page.execute_script 'Voice.dialogController.cancel()'
  end


  def expect_dialog_message(msg)
    expect(find '#dialog_wrapper').to have_text msg
  end


  def visit_home_url
    visit '/'
    resize_browser(1100, 900)
  end


  def use_client(num)
    all_sessions.add num
    Capybara.session_name = num
    sleep 0.5
  end


  def login_as(email, password='P4ssw0rd')
    fill_in 'user[email]',    with: email
    fill_in 'user[password]', with: password
    click_button 'Log in' # TODO translate this

    expect(eval_js('env.userId').to_i).to be > 0
  end


  def resize_browser(width, height)
    window = Capybara.current_session.driver.browser.manage.window
    window.resize_to(width, height)
  end


  def wipe_dbs
    system 'CONFIRM_DELETE=1 ./script/wipe-all-dbs'
  end


  def wait_for_puma
    while `lsof -i :#{SpecConfig['puma_port']} | grep LISTEN | wc -l`.to_i < 1
      sleep 1
    end
  end


  def activate_dashboard
    activate_tab_for('headers.dashboard', 'index')
  end


  def activate_customers_tab
    activate_tab_for('headers.customers', 'customers')
  end


  def activate_agents_tab
    activate_tab_for('headers.agent_list', 'agents')
  end


  def activate_statistics_tab
    activate_tab_for('headers.call_statistics', 'stats')
  end


  def activate_tab_for(name, path)
    click_link(t name)
    sleep 0.1
    expect(
      eval_js "Voice.get('currentPath')"
    ).to eql path
  end


  def get_agent_id_for(num)
    eval_js(
      "#{ALL}('user').findProperty('name', '#{agents[num][:ext]}').get('id')"
    ).to_i
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
    eval_js "#{ALL}('user').get('length')"
  end


  def send_chat_message(msg)
    activate_dashboard
    fill_in 'chat_message', with: msg + "\n"

    all_sessions.each do |num|
      use_client num
      expect(
        eval_js "#{ALL}('chatMessage').get('firstObject.content')"
      ).to eql(msg)
    end
  end
end
