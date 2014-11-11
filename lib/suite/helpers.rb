module Helpers

  def wait_for_ajax
    sleep 0.05
    Timeout.timeout(Capybara.default_wait_time) do
      loop until finished_all_ajax_requests?
    end
  end


  def finished_all_ajax_requests?
    page.evaluate_script('jQuery.active').zero?
  end


  def t(key)
    page.evaluate_script("i18n.#{key}")
  end


  def accept_dialog
    page.execute_script 'Voice.dialogController.accept()'
  end


  def cancel_dialog
    page.execute_script 'Voice.dialogController.cancel()'
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

    expect(page.evaluate_script('env.userId').to_i).to be > 0
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
      page.evaluate_script "Voice.get('currentPath')"
    ).to eql path
  end


  def open_new_agent_form
    page.find('#new_agent').click
    sleep 0.1
    expect(page).to have_css('form#new_agent_form')
  end


  def create_agent(num)
    fillin_fields_for_agent(num)
    set_selections_for_agent(num)
    confirm_new_agent_form

    get_agent_id_for(num).tap { |aid| expect(aid).to be > 1 }
  end


  def get_agent_id_for(num)
    page.evaluate_script(
      "Voice.store.all('user').findProperty('name', '#{agents[num][:ext]}').get('id')"
    ).to_i
  end


  def fillin_fields_for_agent(num)
    [ ['email',        agents[num][:email]],
      ['fullName',     agents[num][:name]],
      ['password',     agents[num][:pass]],
      ['extension',    agents[num][:ext]],
      ['confirmation', agents[num][:pass]]
    ].each { |key, val|
      find('form#new_agent_form').fill_in key, with: val
    }
  end


  def set_selections_for_agent(num)
    [[['Agent', 'roles']]].tap { |arr|
      arr << agents[num][:langs].map  { |val| [val.upcase, 'languages'] }
      arr << agents[num][:skills].map { |val| [translation_for_skill(val), 'skills'] }
    }.flatten(1).each { |key, val|
      find('form#new_agent_form').select key, from: val
    }
  end


  def translation_for_skill(val)
    page.evaluate_script("env.skills.#{val}[env.locale]")
  end


  def confirm_new_agent_form
    find('form#new_agent_form').click_button t('domain.save_profile')
    wait_for_ajax
    accept_dialog
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


  def create_agents
    activate_agents_tab
    open_new_agent_form

    @agent1_id = create_agent(1)
    @agent2_id = create_agent(2)
  end


  def send_chat_message(msg)
    activate_dashboard
    fill_in 'chat_message', with: msg + "\n"

    all_sessions.each { |num|
      use_client num
      expect(
        page.evaluate_script "Voice.store.all('chatMessage').get('firstObject.content')"
      ).to eql msg
    }
  end
end
