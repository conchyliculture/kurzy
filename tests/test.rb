#!/usr/bin/ruby
# encoding: utf-8

require "pp"

ENV['RACK_ENV'] = 'test'

require_relative '../kurzy.rb'
require 'test/unit'
require 'rack/test'

class TestClasse < Test::Unit::TestCase
    require "json"
    include Rack::Test::Methods

    def app
        Sinatra::Application
    end

    def testIndex()
        get '/'
        assert last_response.ok?
        assert last_response.body.include?("Kurzy - URL shortener")
    end

    def testGetShortFail()
        get '/fail'
        assert last_response.ok?
        assert last_response.body.include?("Kurzy - URL shortener")
        assert last_response.body.include?("value=\"fail\"")

        get '/fail.json'
        assert last_response.ok?
        assert_equal JSON.parse(last_response.body), {"url" => nil, "success" => true}
    end

    def testAdd()
        rand = KurzyDB.gen_hash(3)
        post '/a', params={"lsturl"=> "https://twitter.com", "lsturl-custom"=>rand}
        assert last_response.ok?
        assert_equal last_response.body, "Successfully added short link <a href=\"https://twitter.com\">#{rand}</>"
    end

    def testAddJson()
        rand = KurzyDB.gen_hash(3)
        post '/a', params={"lsturl"=> "https://twitter.com", "lsturl-custom"=>rand, "format"=>"json"}
        pp last_response
        assert last_response.ok?
        assert_equal JSON.parse(last_response.body), {"success" => true, "url" => "https://twitter.com", "short" => rand}
    end

    def testAddTwice()
        rand = KurzyDB.gen_hash(3)
        post '/a', params={"lsturl"=> "https://twitter.com", "lsturl-custom"=>rand}
        post '/a', params={"lsturl"=> "https://twitter.com", "lsturl-custom"=>rand}
        assert last_response.ok?
        assert_equal "Error adding short link: 'The short url #{rand} already exists'", last_response.body
    end

    def testAddTwiceJson()
        rand = KurzyDB.gen_hash(3)
        post '/a', params={"lsturl"=> "https://twitter.com", "lsturl-custom"=>rand}
        post '/a', params={"lsturl"=> "https://twitter.com", "lsturl-custom"=>rand, "format"=>"json"}
        assert last_response.bad_request?
        assert_equal({"msg"=> "The short url #{rand} already exists", "success" => false},  JSON.parse(last_response.body))
    end


end
