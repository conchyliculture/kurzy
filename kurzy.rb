#!/usr/bin/ruby
# encoding: utf-8

require "slim"
require "json"
require "securerandom"
require "sinatra"

require_relative "db.rb"

$adminpwd = "toto"

set :bind, "0.0.0.0"

use Rack::Session::Cookie,  :key => 'rack.session',
                        :path => '/',
                        :expire_after => 86400*2,#Inseconds
                        :secret => SecureRandom.hex # Kills all sessions on restart, which is fine

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

def nay(msg)
    status 400
    return {msg: msg, success:false}
end

def yay(msg)
    return {msg: msg, success:true}
end

def add(url:, short:, priv: true)
    unless url
        return nay('I need an url')
    end
    begin
        res = {success: true, url: url, short: KurzyDB.add(short:short, url:url, priv: priv)}
        return res
    rescue KurzyDB::Error =>  e
        return nay(e.message)
    end
end

def delete(short:)
    if not session[:logged]
        return nay("You are not allowed to perform this action")
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

def get_list(max: nil, priv: false)
    $stderr.puts("get_list #{priv}")
    res={}
    res[:list] = KurzyDB.list(max: max, priv: priv)
    res[:success] = true
    return res
end

post '/a' do
    kurl = params['url']
    kurl_custom = params['shorturl']
    kurl_private = params['privateurl']
    @res = add(url:kurl, short: kurl_custom, priv: kurl_private == "true")

    content_type 'application/json'
    status 400 unless @res[:success]
    return @res.to_json
end

get '/list' do
    @liste = get_list(priv: session["logged"])
    content_type 'application/json'
    return @liste.to_json
end

get '/d/*' do |shortened_url|
    @deleted = delete(short: shortened_url)
    content_type 'application/json'
    if not @deleted[:success]
        status 400
    end
    @deleted.to_json
end

post '/login' do
    pwd = params[:password]
    if pwd
        if pwd == $adminpwd
            session["logged"] = true
            content_type 'application/json'
            return yay('Successfully logged in').to_json
        else
            content_type 'application/json'
            return nay("Bad password.").to_json
        end
    end
end

get '/logout' do
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
        return slim :main
    end

    res = get(short: shortened_url)

    if format == "json"
        content_type 'application/json'
        return res.to_json
    else
        if res[:success]
            redirect to(res[:url]), 301
        else
            @short = shortened_url
            slim :main
        end
    end
end
