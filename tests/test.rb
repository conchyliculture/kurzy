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
        assert_equal last_response.status, 400
        assert_equal JSON.parse(last_response.body), {"msg" => "No such short url: 'fail'", "success" => false}
    end

    def testAddJson()
        KurzyDB.truncate()
        rand3 = KurzyDB.gen_hash(3)
        url = "htps://twitter.com"
        post '/a/add', params={"url"=> url, "shorturl"=>rand3}
        assert last_response.ok?
        assert_equal JSON.parse(last_response.body), {"success" => true, "url" => url, "short" => rand3}

        get "/#{rand3}"
        assert last_response.redirect?
        assert_equal last_response.body, ""
        assert_equal last_response.header["Location"], url
    end

    def testAddTwiceJson()
        KurzyDB.truncate()
        rand3 = KurzyDB.gen_hash(3)
        post '/a/add', params={"url"=> "https://twitter.com", "shorturl"=>rand3}
        post '/a/add', params={"url"=> "https://twitter.com", "shorturl"=>rand3}
        assert last_response.bad_request?
        assert_equal({"msg"=> "The short url #{rand3} already exists", "success" => false},  JSON.parse(last_response.body))
    end

    def testAddNoShort()
        KurzyDB.truncate()
        rand3 = KurzyDB.gen_hash(3)
        url = "htps://twitter.com"
        post '/a/add', params={"url"=> url}
        assert last_response.ok?
        response = JSON.parse(last_response.body)
        assert_equal response["success"], true
        assert_equal response["url"], url
        short = response["short"]
        assert {short=~/^.{6}$/}

        get "/#{short}"
        assert last_response.redirect?
        assert_equal last_response.body, ""
        assert_equal last_response.header["Location"], url
    end

    def testDelete()
        b = Rack::Test::Session.new(Rack::MockSession.new(Sinatra::Application))
        KurzyDB.truncate()
        url = "https://twitter.com"
        rand3 = KurzyDB.gen_hash(3)

        b.post '/a/add', params={"url"=> url, "shorturl"=>rand3}
        assert b.last_response.ok?
        b.get "/#{rand3}"
        assert b.last_response.redirect?
        assert_equal b.last_response.body, ""
        assert_equal b.last_response.header["Location"], url

        b.get "/d/#{rand3}"
        assert_equal b.last_response.status, 400
        assert_equal({"msg" => "You are not allowed to perform this action", "success" => false}, JSON.parse(b.last_response.body))

        b.get "/d/#{rand3}", {}, "rack.session" => {"logged" => true}
        assert b.last_response.ok?
        assert JSON.parse(b.last_response.body)["success"]
        assert_equal rand3, JSON.parse(b.last_response.body)["short"]
        b.get "/#{rand3}"
        assert b.last_response.ok?
        assert b.last_response.body.include?("value=\"#{rand3}\"")
    end

    def testList()
        KurzyDB.truncate()
        rands = [KurzyDB.gen_hash(3), KurzyDB.gen_hash(3), KurzyDB.gen_hash(3)]
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
        assert_equal 2, table.size()
        (0..1).each do |i|
            assert_equal(rands[i], table[i]['short'])
            assert_equal(urls[i], table[i]['url'])
        end
    end

end
