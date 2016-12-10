require 'rubygems'
require 'byebug'
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

  use Rack::Auth::Basic, "Restricted Area" do |username, password|
    USER = username if Figaro.env.send("#{username}_password") == password
  end

  get '/' do
    @user = USER.capitalize
    erb :reboot
  end

  post '/hard' do
    begin
      compute = Fog::Compute.new(
        :provider => 'Rackspace',
        :rackspace_username => ENV["RACKSPACE_USERNAME"],
        :rackspace_api_key => ENV["RACKSPACE_API_KEY"],
        :rackspace_region => :ord)
      
      server_list = compute.servers
      a1_server = server_list.detect { |s| s.name == 'audience1st' }
      a1.reboot('SOFT')
    rescue Fog::Rackspace::Errors::BadRequest,
      Fog::Rackspace::Errors::Conflict,
      Fog::Rackspace::Errors::InternalServerError,
      Fog::Rackspace::Errors::MethodNotAllowed,
      Fog::Rackspace::Errors::ServiceError,
      Fog::Rackspace::Errors::ServiceUnavailable => e
      ;;
    ensure
      ;;
    end

  end
end
