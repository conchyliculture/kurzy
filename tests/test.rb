#!/usr/bin/ruby
# encoding: utf-8

require "pp"

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
        assert last_response.body.include?("Kurzy - URL shortener")
    end

    def testGetShortFail()
        KurzyDB.truncate()
        get '/fail'
        assert last_response.ok?
        assert last_response.body.include?("Kurzy - URL shortener")
        assert last_response.body.include?("value=\"fail\"")

        get '/fail', params = {"format" => "json"}
        assert last_response.ok?
        assert_equal JSON.parse(last_response.body), {"msg" => "No such short url: 'fail'", "success" => false}
    end

    def testAdd()
        KurzyDB.truncate()
        rand3 = KurzyDB.gen_hash(3)
        url = "https://twitter.com"
        post '/a', params={"lsturl"=> url, "lsturl-custom"=>rand3}
        assert last_response.ok?
        assert_equal last_response.body, "Successfully added short link <a href=\"#{url}\">#{rand3}</>"

        get '/list?format=json'
        assert last_response.ok?
        table = JSON.parse(last_response.body)["list"]
        assert_equal 0, table[0]["counter"]

        (0..5).each do |i|
            get "/#{rand3}"
            assert last_response.redirect?
            assert_equal last_response.body, ""
            assert_equal last_response.header["Location"], url
        end

        get '/list?format=json'
        assert last_response.ok?
        table = JSON.parse(last_response.body)["list"]
        assert_equal 6, table[0]["counter"]
    end

    def testAddJson()
        KurzyDB.truncate()
        rand3 = KurzyDB.gen_hash(3)
        url = "htps://twitter.com"
        post '/a', params={"lsturl"=> url, "lsturl-custom"=>rand3, "format"=>"json"}
        assert last_response.ok?
        assert_equal JSON.parse(last_response.body), {"success" => true, "url" => url, "short" => rand3}

        get "/#{rand3}"
        assert last_response.redirect?
        assert_equal last_response.body, ""
        assert_equal last_response.header["Location"], url
    end

    def testAddTwice()
        KurzyDB.truncate()
        rand3 = KurzyDB.gen_hash(3)
        post '/a', params={"lsturl"=> "https://twitter.com", "lsturl-custom"=>rand3}
        post '/a', params={"lsturl"=> "https://twitter.com", "lsturl-custom"=>rand3}
        assert last_response.ok?
        assert_equal "Error adding short link: 'The short url #{rand3} already exists'", last_response.body
    end

    def testAddTwiceJson()
        KurzyDB.truncate()
        rand3 = KurzyDB.gen_hash(3)
        post '/a', params={"lsturl"=> "https://twitter.com", "lsturl-custom"=>rand3}
        post '/a', params={"lsturl"=> "https://twitter.com", "lsturl-custom"=>rand3, "format"=>"json"}
        assert last_response.bad_request?
        assert_equal({"msg"=> "The short url #{rand3} already exists", "success" => false},  JSON.parse(last_response.body))
    end

    def testDelete()
        b = Rack::Test::Session.new(Rack::MockSession.new(Sinatra::Application))
        KurzyDB.truncate()
        url = "https://twitter.com"
        rand3 = KurzyDB.gen_hash(3)
        b.get "/d/#{rand3}"
        assert b.last_response.ok?
        assert_equal "Error deleting short link: 'You are not allowed to perform this action'", b.last_response.body
        b.get "/d/#{rand3}",  {'rack.session' =>  { :logged => true } }
        assert b.last_response.ok?
        assert_equal "Error deleting short link: 'You are not allowed to perform this action'", b.last_response.body

        b.post '/a', params={"lsturl"=> "https://twitter.com", "lsturl-custom"=>rand3}
        assert b.last_response.ok?
        assert_equal b.last_response.body, "Successfully added short link <a href=\"#{url}\">#{rand3}</>"
        b.get "/d/#{rand3}", {'rack.session' =>  { :logged => true } }
        assert b.last_response.ok?
        assert_equal "Error deleting short link: 'You are not allowed to perform this action'", b.last_response.body
        b.get "/#{rand3}"
        assert b.last_response.redirect?
        assert_equal b.last_response.body, ""
        assert_equal b.last_response.header["Location"], url
    end

    def testList()
        KurzyDB.truncate()
        rands = [KurzyDB.gen_hash(3), KurzyDB.gen_hash(3), KurzyDB.gen_hash(3)]
        urls = ["https://twitter.com/#{rands[0]}", "https://twitter.com/#{rands[1]}", "https://twitter.com/#{rands[2]}"]
        rands.each_with_index do |r, i|
            if r == rands[2]
                post '/a',  params={"lsturl"=> urls[i], "lsturl-custom"=>rands[i], "lsturl-private" => "on"} 
            else
                post '/a',  params={"lsturl"=> urls[i], "lsturl-custom"=>rands[i]} 
            end
        end

        get '/list'
        assert last_response.ok?
        table = Nokogiri::HTML.parse(last_response.body).css('tbody tr')
        assert_equal 2, table.size()
        (0..1).each do |i|
            assert_equal(rands[i], table[i].css('td')[1].text)
            assert_equal(urls[i], table[i].css('td')[2].text)
        end

        get '/list?format=json'
        assert last_response.ok?
        table = JSON.parse(last_response.body)["list"]
        assert_equal 2, table.size()
        (0..1).each do |i|
            assert_equal(rands[i], table[i]['short'])
            assert_equal(urls[i], table[i]['url'])
        end
    end

end
