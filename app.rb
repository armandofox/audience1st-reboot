require 'rubygems'
require 'rack/ssl'
require 'bundler'
Bundler.require

module Figaro
  class Application
    def path
      @path ||= File.join(Audience1stReboot.settings.root, "config", "application.yml")
    end
    def environment
      Audience1stReboot.settings.environment
    end
  end
end

class Audience1stReboot < Sinatra::Base
  configure do
    Figaro.load
    Rollbar.configure do |config|
      config.access_token = Figaro.env.ROLLBAR_ACCESS_TOKEN!
    end
    HEROKU_API_BASE = 'https://api.heroku.com'
    APP = Figaro.env.HEROKU_APP_NAME!
    AUTH = Figaro.env.HEROKU_API_TOKEN!
  end

  if ENV['RACK_ENV'] == 'production'
    use Rack::SSL
    use Rack::Auth::Basic, "Restricted Area" do |username, password|
      if Figaro.env.send("#{username}_password") == password
        Rollbar.info "Successful login by #{username}"
        set :user, username.capitalize
      else
        Rollbar.info "    Failed login by #{username}"
        nil
      end
    end
  else
    enable :logging
    require 'byebug'
    set :user, 'Tester'
  end

  get '/' do
    @user = settings.user
    erb :reboot
  end

  post '/reboot' do
    @e = nil                    # will contain exception object if problem happens
    begin
      headers = {
        "Accept" => "application/vnd.heroku+json; version=3",
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{AUTH}"
      }
      uri = "#{HEROKU_API_BASE}/apps/#{APP}/dynos"
      res = HTTParty.delete(uri, :headers => headers).code.to_s
      if res =~ /^2/
        Rollbar.info "Successful reboot by #{settings.user}"
      else
        @e = StandardError.new("Heroku returned HTTP status #{res}")
        Rollbar.info @e.message
      end
    rescue StandardError => @e
      Rollbar.error @e
    end
    erb :result
  end

end
