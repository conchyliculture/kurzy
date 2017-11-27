#!/usr/bin/ruby
# encoding: utf-8

ENV['RACK_ENV'] = 'test'

require_relative '../kurzy.rb'
require 'test/unit'
require 'rack/test'

class TestClasse < Test::Unit::TestCase
    require "json"
    require "nokogiri"
    include Rack::Test::Methods

    def app
        Sinatra::Application
    end

    def testIndex()
        get '/'
        assert last_response.ok?
        assert last_response.body.include?("title>Kurzy")
    end

    def testGetShortFail()
        KurzyDB.truncate()
        get '/fail'
        assert last_response.ok?
        assert last_response.body.include?("title>Kurzy")
        assert last_response.body.include?("value=\"fail\"")

        get '/fail', params = {"format" => "json"}
        assert {last_response.status == 400}
        assert {JSON.parse(last_response.body) == {"msg" => "No such short url: 'fail'", "success" => false}}
    end

    def genericTestAdd(p)
        KurzyDB.truncate()
        post '/a/add', params=p
        assert last_response.ok?
        response = JSON.parse(last_response.body)
        assert response["success"]
        assert {response["url"] == p["url"]}
        short = response["short"]
        assert {short=~/^.{6}$/}

        get "/#{short}"
        assert last_response.redirect?
        assert {last_response.body == ""}
        assert {last_response.header["Location"] == p["url"]}
    end

    def testAddJson()
        KurzyDB.truncate()
        url = "htps://twitter.com"
        rand6 = gen_hash()
        genericTestAdd({"url"=> url, "shorturl"=>rand6})
    end

    def testAddTwiceJson()
        KurzyDB.truncate()
        rand6 = gen_hash()
        post '/a/add', params={"url"=> "https://twitter.com", "shorturl"=>rand6}
        post '/a/add', params={"url"=> "https://twitter.com", "shorturl"=>rand6}
        assert last_response.bad_request?
        assert {JSON.parse(last_response.body) == {"msg"=> "The short url #{rand6} already exists", "success" => false}}
    end

    def testAddNoShort()
        url = "htps://twitter.com"
        genericTestAdd({"url"=> url})
    end

    def testAddBadURL()
        KurzyDB.truncate()
        url = "https://www.pute.ninja.lol/qloueskgjb_  /amohaazih&mlnk?jzda=z=A&5u#<MBDG~~F<"
        post '/a/add', params={"url"=> url}
        assert {last_response.status == 400}
        assert {JSON.parse(last_response.body) == {"msg" => "Bad URI", "success" => false}}
    end

    def testAddEvilURL()
        KurzyDB.truncate()
        url = "https://www.pute.ninja.lol/<script>alert('lol')</script>"
        post '/a/add', params={"url"=> url}
        assert {last_response.status == 400}
        assert {JSON.parse(last_response.body) == {"msg" => "Bad URI", "success" => false}}
    end

    def testDelete()
        b = Rack::Test::Session.new(Rack::MockSession.new(Sinatra::Application))
        KurzyDB.truncate()
        url = "https://twitter.com"
        rand6 = KurzyUtils.gen_hash(6)

        b.post '/a/add', params={"url"=> url, "shorturl"=>rand6}
        assert b.last_response.ok?
        b.get "/#{rand6}"
        assert b.last_response.redirect?
        assert {b.last_response.body == ""}
        assert {b.last_response.header["Location"] == url}

        b.get "/d/#{rand6}"
        assert {b.last_response.status == 400}
        assert {JSON.parse(b.last_response.body) == {"msg" => "You are not allowed to perform this action", "success" => false}}

        b.get "/d/#{rand6}", {}, "rack.session" => {"logged" => true}
        assert b.last_response.ok?
        assert JSON.parse(b.last_response.body)["success"]
        assert {JSON.parse(b.last_response.body)["short"] == rand6}
        b.get "/#{rand6}"
        assert b.last_response.ok?
        assert b.last_response.body.include?("value=\"#{rand6}\"")
    end

    def gen_hash()
        return KurzyUtils.gen_hash(6)
    end

    def testList()
        KurzyDB.truncate()
        rands = [gen_hash(), gen_hash(), gen_hash()]
        urls = ["https://twitter.com/#{rands[0]}", "https://twitter.com/#{rands[1]}", "https://twitter.com/#{rands[2]}"]
        rands.each_with_index do |r, i|
            if r == rands[2]
                post '/a/add',  params={"url"=> urls[i], "shorturl"=>rands[i], "privateurl" => "true"}
            else
                post '/a/add',  params={"url"=> urls[i], "shorturl"=>rands[i]}
            end
        end

        get '/l/list'
        assert last_response.ok?
        table = JSON.parse(last_response.body)["list"]
        assert {table.size() == 2}
        (0..1).each do |i|
            assert {rands[i] == table[i]['short']}
            assert {urls[i] == table[i]['url']}
        end
    end

    def testGenHash
        chars = [*'a'..'h', 'j', 'k', *'m'..'z', *'A'..'H', *'J'..'N', *'P'..'Z', *'0'..'9', '_', '-'].join()
        chars_r = "[#{chars}]"
        assert {KurzyUtils.gen_hash(10) =~ /^#{chars_r}{10}$/}
    end

    def testURLFilter
        url = "';!-\"<>=&{()}"
        assert {KurzyUtils.remove_bad_urlchar(url) == ";!-=&()"}

        url = "https://www.pute.ninja.lol/qloueskgjb_  /amohaazih&mlnk?jzda=z=A&5u#<MBDG~~F<"
        assert_raise URI::InvalidURIError do
            KurzyUtils.url_filter(url)
        end

        url = "https://www.pute.ninja.lol/qloueskgjb_/amohaazihmlnk?jzda=zA&5=u#MBDGF"
        assert {KurzyUtils.url_filter(url) == url}

        short = "<script>alert('lol')"
        assert {KurzyUtils.short_filter(short) == "scriptalert(lol)"}

    end

end
