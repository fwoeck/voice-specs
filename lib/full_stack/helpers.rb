module Helpers

  def visit_home_url
    visit '/'
    resize_browser(1100, 900)
  end


  def use_client(num)
    Capybara.session_name = "client_#{num}"
  end


  def login_as(email, password='P4ssw0rd')
    fill_in 'user[email]',    with: email
    fill_in 'user[password]', with: password
    click_button 'Log in'

    expect(page).to have_css('#logout_link')
    expect(find '#logout_link').to have_content('Logout')
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
end
