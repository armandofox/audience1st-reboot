require 'rubygems'
require 'byebug'
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
  end

  enable :logging

  if ENV['RACK_ENV'] == 'production'
    use Rack::SSL
    use Rack::Auth::Basic, "Restricted Area" do |username, password|
      set :user,username if Figaro.env.send("#{username}_password!") == password
    end
  end

  get '/' do
    @user = settings.user.capitalize
    logger.info "Access by #{@user} at #{Time.now.asctime}"
    erb :reboot
  end

  post '/reboot' do
    @e = nil                    # will contain exception object if problem happens
    begin
      compute = Fog::Compute.new(:provider => 'Rackspace',
        :rackspace_username => Figaro.env.RACKSPACE_USERNAME! ,
        :rackspace_api_key => Figaro.env.RACKSPACE_API_KEY! ,
        :rackspace_region => Figaro.env.RACKSPACE_REGION!)
      @server = compute.servers.detect { |s| s.name == Figaro.env.server_name! }
      raise StandardError.new("Couldn't find server in server list") unless @server
      @server.reboot('SOFT')
      @success = true
    rescue StandardError,
      Fog::Rackspace::Errors::BadRequest,
      Fog::Rackspace::Errors::Conflict,
      Fog::Rackspace::Errors::InternalServerError,
      Fog::Rackspace::Errors::MethodNotAllowed,
      Fog::Rackspace::Errors::ServiceError,
      Fog::Rackspace::Errors::ServiceUnavailable => @e
    ensure
      erb :result
    end
  end
end
