require "digest"
require "slim"
require "json"
require "securerandom"
require "sinatra/base"

require_relative "db.rb"
require_relative "utils.rb"

 def load_config(config_path)
   if not File.exist?(config_path)
     raise Exception.new("Please copy config.json.template into #{config_path} and edit it to your needs")
   end

   return JSON.parse(File.read(config_path))
 end

class Kurzy < Sinatra::Base

  configure do
    local_dir = File.expand_path(File.dirname(__FILE__))
    if @config_file
      config = load_config(ENV["CONFIG_FILE"])
    else
      config = load_config(File.join(local_dir, "config.json"))
    end
    set :bind, config["bind"] || "0.0.0.0"
    set :port, config["port"] || 4567
    set :server, config["server"] || :puma

    enable :sessions
    set :sessions, :expire_after => (config["cookie_expire_after"] || 2 * 60)
    set :sessions, :domain => config["domain"]
    set :session_secret,  SecureRandom.hex(64)
    set :session_store, Rack::Session::Pool

    set :adminpwd, Digest::SHA512.hexdigest(config["admin_password"])
    set :private_inserts, config["private_inserts"] || false

    if not adminpwd
      raise Exception.new("Please set admin_password in config.json")
    end
  end

  def truncate()
    KurzyDB.truncate()
  end


  def nay(msg)
      status 400
      return {msg: msg, success:false}
  end

  def yay(msg)
      status 200
      return {msg: msg, success:true}
  end

  def add(url:, short:"")
      unless url
          return nay('I need an url')
      end
      if "#{short}" == ""
          short = KurzyUtils.gen_hash()
      else
          short = KurzyUtils.short_filter(short)
      end

      begin
          url = KurzyUtils.url_filter(url)
      rescue URI::InvalidURIError => e
          return nay("Bad URI")
      rescue Exception => e
          return nay(e.message)
      end

      begin
          res = {success: true, url: url, short: KurzyDB.add(short:short, url:url)}
          return res
      rescue KurzyDB::Error =>  e
          return nay(e.message)
      end
  end

  def delete(short:)
      if not session[:logged]
        return nay("You are not allowed to perform this action (delete)").to_json
      end
      begin
          res = KurzyDB.delete(short: short)
          res[:success] = true
          return res
      rescue KurzyDB::Error => e
          return nay(e.message)
      end
  end

  def get(short:)
      res = {success: false}
      url = KurzyDB.get_url(short: short)
      if url
          res[:url] = url
          res[:success] = true
      else
          res = nay("No such short url: '#{short}'")
      end
      return res
  end

  def get_list(max: nil)
      if not session[:logged]
        # Just do nothing
        return {success: true, list: [] }
      end
      res={}
      res[:list] = KurzyDB.list(max: max)
      res[:success] = true
      return res
  end

  post '/a/add' do
      if (not session[:logged]) and settings.private_inserts
        return nay("You are not allowed to perform this action (add)").to_json
      end
      kurl = params['url']
      kurl_custom = params['shorturl']
      @res = add(url:kurl, short: kurl_custom)

      content_type 'application/json'
      status 400 unless @res[:success]
      return @res.to_json
  end

  get '/l/list' do
      if (not session[:logged] and not settings.private_inserts )
        return nay("You are not allowed to perform this action (list)").to_json
      end
      @liste = get_list()
      content_type 'application/json'
      return @liste.to_json
  end

  get '/d/*' do |shortened_url|
      if not session[:logged]
        return nay("You are not allowed to perform this action").to_json
      end
      @deleted = delete(short: shortened_url)
      content_type 'application/json'
      if not @deleted[:success]
          status 400
      end
      @deleted.to_json
  end

  post '/l/login' do
      pwd = params[:password]
      if pwd
          if Digest::SHA512.hexdigest(pwd) == settings.adminpwd
              session[:logged] = true
              content_type 'application/json'
              return yay('Successfully logged in').to_json
          else
              session[:logged] = false
              content_type 'application/json'
              return nay("Bad password.").to_json
          end
      end
  end

  get '/l/logout' do
      content_type 'application/json'
      if session["logged"]
          session["logged"] = false
          return yay('Successfully logged out').to_json
      else
          return nay('Not logged in').to_json
      end
  end

  get '/*' do |shortened_url|
      format = params[:format]
      if shortened_url == ""
          @logged = session[:logged]
          @private_inserts = settings.private_inserts
          return slim :main
      end

      res = get(short: shortened_url)

      if format == "json"
          content_type 'application/json'
          return res.to_json
      else
          if res[:success]
              expires 0, :no_store, :must_revalidate
              redirect to(res[:url]), 301
          else
              status 200
              @short = shortened_url
              slim :main
          end
      end
  end

  if app_file == $0
    run!
  end
end
