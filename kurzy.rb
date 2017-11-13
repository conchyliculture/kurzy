#!/usr/bin/ruby
# encoding: utf-8

require "slim"
require "json"
require_relative "db.rb"
require "sinatra"

set :bind, "0.0.0.0"
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8


before do
end

def add(url:url, short: short)
    begin
        return {success: true, url: url, short: KurzyDB.add(short:short, url:url)}
    rescue KurzyDB::Error =>  e
        message = e.message 
        return {msg: message, success: false}
    end
end

def delete(short:)
    res = KurzyDB.delete(short: s)
    res[:success] = true
    return res
end

def get(short:)
    return KurzyDB.get_url(short: short)
end


post '/a' do
    kurl = params['lsturl']
    kurl_custom = params['lsturl-custom']
    format = params['format']
    
    @res = add(url:kurl, short: kurl_custom)
    
    if format == 'json'
        content_type 'application/json'
        status 400 unless @res[:success]
        return @res.to_json
    else
        slim :add
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

get '/d/*' do |shortened_url|
    format = params['format']
    @error = nil

    begin
        @deleted = delete(short: short)
    rescue Sequel::Error => e
        @error = e.message
    end

    if format == 'json'
        content_type 'application/json'
        if @error
            status 400
            {success: false, msg: @error}
        else
            @deleted.to_json
        end
    else
        slim :delete
    end
end
