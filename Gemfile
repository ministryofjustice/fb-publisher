source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

gem 'git'

# Gov.uk styling (TODO: upgrade to use new Design System)
gem 'govuk_frontend_toolkit', '~> 9.0.1'
gem 'govuk_elements_rails', '~> 3.1.3'
gem 'govuk_elements_form_builder',  '~>1.3.0'
gem 'govuk_template'

gem 'haml'
gem 'haml-rails'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.11'
gem 'jquery-rails'

gem 'omniauth-auth0', '~> 3.0.0'
gem 'omniauth-rails_csrf_protection', '~> 1.0'

# Pagination
gem 'pagy'

# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
# Use Puma as the app server
gem 'puma', '~> 5.6'

# Policy-based authorization
gem 'pundit'

# allow Cross-origin requests, otherwise CDN cache-fetch requests show up
# as cancelled, even though they work when you copy-and-paste the URL into
# a browser
gem 'rack-cors', require: 'rack/cors'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '7.0.3.1'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 6.0'

# must explicitly mention sprockets with this version to get round
# https://blog.heroku.com/rails-asset-pipeline-vulnerability
gem 'sprockets', '~>4.0.2'

# parallel HTTP requests
gem 'typhoeus'
# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem 'therubyracer'
gem 'uglifier', '>= 1.3.0'
gem 'resque'
gem 'rails-data-migrations'
gem 'uri-ssh_git'
gem 'sentry-raven'

gem 'activerecord-session_store'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'rubocop'
  gem 'factory_bot_rails'
end

group :development do
  gem 'i18n-debug'
  gem 'listen', '>= 3.0.5', '< 3.8'
  gem 'guard-rspec', require: false
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15', '< 4.0'
  gem 'database_cleaner'
  gem 'rspec', '~>3.11.0'
  gem 'rspec-rails', '5.1.2'
  gem 'selenium-webdriver'
  gem 'simplecov'
  gem 'webmock'
end
