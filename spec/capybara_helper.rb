require 'rails_helper'
require 'capybara/rspec'
require 'capybara/rails'

require 'support/sessions'

require 'phantomjs'
require 'capybara/poltergeist'

Capybara.default_driver = :rack_test

options = {
  js_errors: false,
  phantomjs: Phantomjs.path
}

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, options)
end

Capybara.javascript_driver = :poltergeist
