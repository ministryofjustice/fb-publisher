require 'capybara/rspec'
require 'selenium/webdriver'
require 'ostruct'

RSpec.configure do |c|
  Capybara.register_driver :selenium do |app|
    chrome_options = Selenium::WebDriver::Chrome::Options.new.tap do |o|
      o.add_argument '--headless'
      o.add_argument '--no-sandbox'

      o.add_argument '--allow-insecure-localhost'
      o.add_argument '--disable-infobars'
      o.add_argument '--disable-extensions'
      o.add_argument '--ignore-certificate-errors'
      o.add_argument '--accept-ssl-certs'
      o.add_argument '--accept-insecure-certs'
    end
    Capybara::Selenium::Driver.new(app, browser: :chrome, options: chrome_options)
  end
  Capybara.default_driver = :selenium

  ip = `nslookup app`.scan(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/)[0]

  Capybara.app_host = "http://#{ip}:3000"
  c.include Capybara::DSL

  uri = URI("#{Capybara.app_host}/healthy")

  while true do
    begin
      if Net::HTTP.get(uri).include?('healthy')
        break
      end
    rescue
      sleep 1
    end
  end

  Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}

  c.after(:each) do
    Capybara.reset_sessions!
  end
end
