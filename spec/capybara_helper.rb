require 'rails_helper'
require 'capybara/rspec'
require 'capybara/rails'

require 'support/sessions'

Capybara.default_driver = :rack_test

Capybara.register_driver :selenium do |app|
  chrome_options = Selenium::WebDriver::Chrome::Options.new.tap do |o|
    o.add_argument '--headless'
    o.add_argument '--no-sandbox'
  end
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: chrome_options)
end

Capybara.javascript_driver = :selenium
