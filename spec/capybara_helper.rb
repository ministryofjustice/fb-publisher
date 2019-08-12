require 'rails_helper'
require 'capybara/rspec'
require 'capybara/rails'
require "selenium/webdriver"

require 'support/sessions'

require 'capybara/poltergeist'

Capybara.default_driver = :rack_test
#
# Capybara.register_driver :chrome do |app|
#   Capybara::Selenium::Driver.new(app, browser: :chrome)
# end

Capybara.register_driver :headless_chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: { args: %w(headless disable-gpu ) }
  )

  Capybara::Selenium::Driver.new app,
    browser: :chrome,
    desired_capabilities: capabilities
end

Capybara.javascript_driver = :headless_chrome
