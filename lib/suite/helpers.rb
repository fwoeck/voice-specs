module Helpers
  NA_FORM = 'form#new_agent_form'
  ALL     = 'Voice.store.all'


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


  def open_new_agent_form
    page.find('#new_agent').click
    sleep 0.1
    expect(page).to have_css(NA_FORM)
  end


  def create_agent(num)
    fillin_fields_for_agent(num)
    set_selections_for_agent(num)
    confirm_new_agent_form

    get_agent_id_for(num).tap { |aid| expect(aid).to be > 1 }
  end


  def get_agent_id_for(num)
    eval_js(
      "#{ALL}('user').findProperty('name', '#{agents[num][:ext]}').get('id')"
    ).to_i
  end


  def fillin_fields_for_agent(num)
    [ ['email',        agents[num][:email]],
      ['fullName',     agents[num][:name]],
      ['password',     agents[num][:pass]],
      ['extension',    agents[num][:ext]],
      ['confirmation', agents[num][:pass]]
    ].each { |key, val|
      find(NA_FORM).fill_in key, with: val
    }
  end


  def set_selections_for_agent(num)
    [[['Agent', 'roles']]].tap { |arr|
      arr << agents[num][:langs].map  { |val| [val.upcase, 'languages'] }
      arr << agents[num][:skills].map { |val| [translation_for_skill(val), 'skills'] }
    }.flatten(1).each { |key, val|
      find(NA_FORM).select key, from: val
    }
  end


  def translation_for_skill(val)
    eval_js("env.skills.#{val}[env.locale]")
  end


  def confirm_new_agent_form
    find(NA_FORM).click_button t('domain.save_profile')
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


  def check_form_validation
    fillin_fields_for_agent 1
    fillin_invalid_email
    fillin_duplicate_email
    clear_new_agent_form
  end


  def fillin_invalid_email
    find(NA_FORM).fill_in 'email', with: 'invalid.email'
    find(NA_FORM).click_button t('domain.save_profile')

    expect_dialog_message t('dialog.form_with_errors')
    accept_dialog
  end


  def fillin_duplicate_email
    find(NA_FORM).fill_in 'email', with: 'valid@email.com'
    find(NA_FORM).click_button t('domain.save_profile')

    expect_dialog_message 'SIP Extension has already been taken'
    accept_dialog
  end


  def clear_new_agent_form
    expect(new_agent_fullname_field).to eql(agents[1][:name])
    find(NA_FORM).click_button t('domain.clear')

    expect(new_agent_fullname_field).to eql('')
    expect(user_count).to eql(4)
  end


  def user_count
    eval_js "#{ALL}('user').get('length')"
  end


  def new_agent_fullname_field
    find("#{NA_FORM} input[name='fullName']").value
  end


  def send_chat_message(msg)
    activate_dashboard
    fill_in 'chat_message', with: msg + "\n"

    all_sessions.each { |num|
      use_client num
      expect(
        eval_js "#{ALL}('chatMessage').get('firstObject.content')"
      ).to eql msg
    }
  end
end
