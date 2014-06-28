CALL_IDS = {}

def callid
  CALL_IDS[Capybara.session_name]
end

def callid=(other)
  CALL_IDS[Capybara.session_name] = other
end

def register_as(uid, pass='0000')
  puts "#{Capybara.session_name}: Register as #{uid}"
  page.execute_script "phone.app.login({login: '#{uid}', password: '#{pass}'})"
end

def get_audio_access
  puts "#{Capybara.session_name}: Get audio access"
  page.execute_script 'phone.app.getAccessToAudio()'
end

def call(ext)
  puts "#{Capybara.session_name}: Call #{ext}"
  page.execute_script "phone.app.call('#{ext}')"
end

def get_callid
  self.callid = page.evaluate_script 'phone.app.calls[0].id'
end

def send_dtmf(char)
  puts "#{Capybara.session_name}: Send DTMF #{char} to #{callid}"
  page.execute_script "phone.app.sendDTMF('#{callid}', '#{char}')"
end

def answer_call
  puts "#{Capybara.session_name}: Answer #{callid}"
  page.execute_script "phone.app.answer('#{callid}', false)"
end

def hangup_call
  puts "#{Capybara.session_name}: Hangup #{callid}"
  page.execute_script "phone.app.hangup('#{callid}')"
end
