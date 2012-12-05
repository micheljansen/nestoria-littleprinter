require 'bundler'

Bundler.require

require './nestoria_app.rb'

map '/assets' do
  environment = Sprockets::Environment.new
  environment.append_path 'assets'
  environment.append_path 'assets/js'
  environment.append_path 'assets/js/models'
  environment.append_path 'assets/js/views'
  environment.append_path 'assets/js/controllers'
  run environment
end

map '/' do
  run Nestoria::App
end

#show logs in heroku
$stdout.sync = true

