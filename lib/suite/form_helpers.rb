module FormHelpers

  NA_FORM = 'form#new_agent_form'
  MS_FORM = 'form#current_user_form'

  AGENT_PANELS = '#agent_table_wrapper .jspPane > .ember-view'
  FIRST_AGENT  = "#{AGENT_PANELS} > .agent"


  def open_new_agent_form
    page.find('#new_agent').click
    sleep 0.1
    expect(page).to have_css(NA_FORM)
  end


  def create_agent(num)
    fillin_fields_for_agent(num)
    set_selections_for_agent(num)

    confirm_new_agent_form
    get_agent_id_for(num)
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


  def submit_form(form, check=true)
    find(form).click_button t('domain.save_profile')
    wait_for_ajax
    accept_dialog(check)
  end


  def confirm_new_agent_form
    submit_form(NA_FORM)
  end


  def create_agents
    activate_agents_tab
    open_new_agent_form

    [1, 2].each { |n|
      num, aid = create_agent(n)
      agents[num][:id] = aid
    }
  end


  def check_form_validation
    fillin_fields_for_agent(1)
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


  def new_agent_fullname_field
    find("#{NA_FORM} input[name='fullName']").value
  end


  def update_my_settings_as(num)
    use_client agents[num][:ext]
    activate_agents_tab
    change_ui_locale
    update_agent_name_for(num)
  end


  def as_admin_grant_agent(num)
    use_client admin_name
    activate_agents_tab
    filter_for_agent(num)
    give_admin_role_to(num)
  end


  def as_admin_revoke_agent(num)
    # TODO
    # revoke admin role from agent
  end


  def filter_for_agent(num)
    expect(page.all(AGENT_PANELS).size).to eql(3)
    find('#agent_table').fill_in 'agent_search', with: agents[num][:ext]
    sleep 0.5
    expect(page.all(AGENT_PANELS).size).to eql(1)
  end


  def give_admin_role_to(num)
    find(FIRST_AGENT).click
    expect(page).to have_css("form#agent_form_#{agents[num][:id]}")
    # TODO ...
  end


  def change_ui_locale
    cl = current_locale
    return unless nl = (ui_locales - [cl]).sample

    [nl, cl].each { |loc|
      open_my_settings
      choose_ui_locale(loc)
    }
  end


  def open_my_settings
    find('#my_config').click
    expect(page).to have_css(MS_FORM)
  end


  def choose_ui_locale(loc)
    find(MS_FORM).select loc, from: 'locale'
    submit_form(MS_FORM)
    sleep 1

    expect(eval_js 'env.locale').to eql(loc)
    expect(find('#logout_link a').text).to eql t('domain.logout')
  end


  def update_agent_name_for(num)
    new_name = agents[num][:name] + ' II'

    open_my_settings
    find(MS_FORM).fill_in 'fullName', with: new_name
    submit_form(MS_FORM, false)
    check_user_record_for(num, new_name)
  end
end
