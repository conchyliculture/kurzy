#!/usr/bin/ruby
# encoding: utf-8

require "slim"
require "json"
require_relative "db.rb"
require "sinatra"

set :bind, "0.0.0.0"
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

def add(url:, short:, priv: true)
    begin
        return {success: true, url: url, short: KurzyDB.add(short:short, url:url, priv: priv)}
    rescue KurzyDB::Error =>  e
        message = e.message 
        return {msg: message, success: false}
    end
end

def delete(short:)
    begin
        res = KurzyDB.delete(short: short)
        res[:success] = true
        pp res
        return res
    rescue KurzyDB::Error => e
        message = e.message 
        return {msg: message, success: false}
    end
end

def get(short:)
    return KurzyDB.get_url(short: short)
end

def get_list(max: nil, priv: false)
    res={}
    res[:list] = KurzyDB.list(max: max, priv: priv)
    res[:success] = true
    return res
end


post '/a' do
    kurl = params['lsturl']
    kurl_custom = params['lsturl-custom']
    kurl_private = params['lsturl-private']
    format = params['format']
    
    @res = add(url:kurl, short: kurl_custom, priv: kurl_private == "on")
    
    if format == 'json'
        content_type 'application/json'
        status 400 unless @res[:success]
        return @res.to_json
    else
        slim :add
    end
end

get '/list' do
    format = params[:format]
    @liste = get_list()
    if format == 'json'
        content_type 'application/json'
        return @liste.to_json
    else
        slim :list
    end
end

get '/d/*' do |shortened_url|
    format = params['format']
    @deleted = delete(short: shortened_url)

    if format == 'json'
        content_type 'application/json'
        if @deleted[:success]
            @deleted.to_json
        else
            status 400
            {success: false, msg: @error}
        end
    else
        slim :delete
    end
end

get '/*.json' do |shortened_url|
    content_type 'application/json'
    begin
        url = get(short: shortened_url)
    rescue KurzyDB::Error => e
        return {msg: e.message, success: false}
    end

    {url: url, success: true}.to_json
end

get '/*' do |shortened_url|
    if shortened_url == ""
        slim :main
    else
        dest_url = get(short: shortened_url)
        if dest_url
            redirect to(dest_url), 301
        else
            @short = shortened_url
            slim :main
        end
    end
end
