module ReplayHelpers

  def create_fake_customers(num=1)
    log "Create #{num} fake customers."
    system "curl -s 'https://127.0.0.1/seed/customers?count=#{num}' >/dev/null"
  end


  def replay_captured_events
    log 'Replay captured events:'

    Open3.popen3(replay_command) { |stdin, stdout, stderr, wait_thr|
      @std_in = stdin
      step_through_captured_events
      wait_thr.join
    }
  end


  def step_through_captured_events
    (1..16).each do |n|
      send("conduct_step_#{'%02d' % n}")
    end
  end


  def conduct_step_01
    conduct_step "01/16 Set the agent's visibility: online, activity: silent."
  end


  def conduct_step_02
    conduct_step "02/16 Set the customer's (agent 999) activity: talking."

    with_all_sessions do
      expect_with_retry('talking') {
        expect_js "#{find_js_user_by_name admin_name}.get('activity')"
      }
    end
  end


  def call_count
    "#{ALL}('call').get('length')"
  end


  def conduct_step_03
    conduct_step "03/16 Create the customer's call leg with call_id, extension, caller_id."

    check_admin_session_for_calls
    [1, 2].each { |num| check_agent_session_for_no_calls(num) }
  end


  def check_admin_session_for_calls
    use_client admin_name
    activate_dashboard

    expect_with_retry(2) { expect_js call_count }
    expect(find '#my_settings > h5 > span.stats').to have_text "I'm currently talking."
    expect(expect_js '$("#callstats_table .callstats_table").length').to eq 2
  end


  def check_agent_session_for_no_calls(num)
    use_client agents[num][:ext]
    activate_dashboard
    expect_with_retry(0) { expect_js call_count }
  end


  def conduct_step_04
    conduct_step "04/16 Set the customer's call language."
  end


  def conduct_step_05
    conduct_step "05/16 Set the customer's call skill."
  end


  def conduct_step_06
    conduct_step "06/16 Set the customer's call queued_at."

    [1, 2].each { |num|
      check_agent_session_for_one_call(num)
      check_incoming_call_fields
    }
  end


  def check_agent_session_for_one_call(num)
    use_client agents[num][:ext]
    expect_with_retry(1) { expect_js call_count }
    expect(expect_js '$("#callstats_table .callstats_table").length').to eq 1
  end


  def check_incoming_call_fields
    lang = eval_js "#{ALL}('call').get('firstObject.language')"
    expect(expect_js 'Voice.get("currentUser.languages")').to include lang

    skill = eval_js "#{ALL}('call').get('firstObject.skill')"
    expect(expect_js 'Voice.get("currentUser.skills")').to include skill
  end


  def conduct_step_07
    conduct_step "07/16 Create the agent's call leg with origin_id and other fields."
  end


  def conduct_step_08
    conduct_step "08/16 Set the agent's activity: ringing."

    [1, 2].each { |num|
      use_client agents[num][:ext]
      expect(find '#my_settings > h5 > span.stats').to have_text "I'm receiving a call."
    }
  end


  def conduct_step_09
    conduct_step "09/16 Repeat 07/16 (seems unnecessary)."
  end


  def conduct_step_10
    conduct_step "10/16 Set the agent's activity: talking."

    [1, 2].each { |num|
      use_client agents[num][:ext]
      expect(find '#my_settings > h5 > span.stats').to have_text "I'm currently talking."
    }
  end


  def conduct_step_11
    conduct_step "11/16 Set the agent call leg's call_tag and dispatched_at."
  end


  def conduct_step_12
    conduct_step "12/16 Set the customer call leg's call_tag and dispatched_at."
    binding.pry

    # as agent:
    # - add a remark, add a tag
    # - add " (test)" to name, save
    # - opt. create Zendesk user/ticket
    #
    # as admin check:
    # - dashboard / show dispatched
    # - customers / some patterns, remark, tags
    # - stats / active, dipatched calls
  end


  def conduct_step_13
    conduct_step "13/16 Set the agent's activity: silent."
  end


  def conduct_step_14
    conduct_step "14/16 Set the agent call leg's hungup_at."
  end


  def conduct_step_15
    conduct_step "15/16 Set the customer call leg's hungup_at."
  end


  def conduct_step_16
    conduct_step "16/16 Set the customers's activity: silent."
  end


  def conduct_step(msg)
    @std_in.print "\n"
    sleep 0.1
    log msg
  end


  def replay_command
    'SYNC_STEPS=1 ./script/replay-events 2'
  end
end
