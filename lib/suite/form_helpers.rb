module FormHelpers
  NA_FORM = 'form#new_agent_form'


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


  def confirm_new_agent_form
    find(NA_FORM).click_button t('domain.save_profile')
    wait_for_ajax
    accept_dialog
  end


  def create_agents
    activate_agents_tab
    open_new_agent_form

    @agent1_id = create_agent(1)
    @agent2_id = create_agent(2)
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
end
