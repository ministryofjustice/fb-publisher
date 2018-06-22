require 'phantomjs'

Capybara.default_driver = :poltergeist
Capybara.javascript_driver = :poltergeist

options = {
  js_errors: false,
  phantomjs: Phantomjs.path
}

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, options)
end
