#!/usr/bin/ruby
require "json"
require 'test/unit'
require 'rack/test'


ENV['RACK_ENV'] = 'unittest'
require_relative '../kurzy.rb'

class KurzyPublicInserts < Kurzy
  # A Kurzy class where new URL additions are open to the public
  set :private_inserts, false
  set :adminpwd, Digest::SHA512.hexdigest("terriblepassword")
end

class KurzyPrivateInserts < Kurzy
  # A Kurzy class where new URL additions are restricted to logged in
  set :adminpwd, Digest::SHA512.hexdigest("terriblepassword")
  set :private_inserts, true
end

class TestKurzy < Test::Unit::TestCase
end

class TestGeneric < TestKurzy
  # Tests that are the same for whether the insertion is public or not
  require_relative '../kurzy.rb'

  def testIndex()
    browser = Rack::Test::Session.new(Rack::MockSession.new(Kurzy))
    browser.get '/'
    assert browser.last_response.ok?
    assert browser.last_response.body.include?("title>Kurzy")
  end

  def testGetShortFail()

    browser = Rack::Test::Session.new(Rack::MockSession.new(Kurzy))
    browser.get '/fail'
    assert browser.last_response.ok?
    assert browser.last_response.body.include?("title>Kurzy")
    assert browser.last_response.body.include?("value=\"fail\"")

    browser.get '/fail', params = {"format" => "json"}
    assert_equal browser.last_response.status, 400
    assert_equal JSON.parse(browser.last_response.body), {"msg" => "No such short url: 'fail'", "success" => false}
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

    short = "<script>alert('LOL')"
    assert {KurzyUtils.short_filter(short) == "scriptalert(lol)"}

  end

end

class TestClassPubAdd < TestKurzy
  def getbrowser()
    browser = Rack::Test::Session.new(KurzyPublicInserts)
    #browser = Rack::Test::Session.new(Rack::MockSession.new(KurzyPublicInserts))
  end

  def testAddNoLogin()
    browser = getbrowser()
    url = "https://twitter.com"
    rand6 = KurzyUtils.gen_hash()

    browser.post '/a/add', params={"url"=> url, "shorturl"=>rand6}
    assert browser.last_response.ok?
    response = JSON.parse(browser.last_response.body)
    assert response["success"]
    assert_equal response["url"], url
    assert_equal response["short"], rand6

    browser.get "/#{rand6}"
    assert browser.last_response.redirect?
    assert_equal browser.last_response.body, ""
    assert_equal browser.last_response.header["Location"], url
  end

  def testAddTwiceJson()
    browser = getbrowser()
    rand6 = KurzyUtils.gen_hash()
    browser.post '/a/add', params={"url"=> "https://twitter.com", "shorturl"=>rand6}
    browser.post '/a/add', params={"url"=> "https://twitter.com", "shorturl"=>rand6}
    assert browser.last_response.bad_request?
    assert_equal JSON.parse(browser.last_response.body), {"msg"=> "The short url #{rand6} already exists", "success" => false}
  end

  def testAddNoShort()
    browser = getbrowser()
    url = "htps://twitter.com"
    browser.post '/a/add', params={"url"=> url}
    assert browser.last_response.ok?
    response = JSON.parse(browser.last_response.body)
    assert response["success"]
    assert_equal response["url"], url
    assert_match /^.{6}$/, response["short"]
  end

  def testAddBadURL()
    browser = getbrowser()
    url = "https://www.pute.ninja.lol/qloueskgjb_  /amohaazih&mlnk?jzda=z=A&5u#<MBDG~~F<"
    browser.post '/a/add', params={"url"=> url}
    assert_equal browser.last_response.status, 400
    assert_equal JSON.parse(browser.last_response.body), {"msg" => "Bad URI", "success" => false}
  end

  def testAddEvilURL()
    browser = getbrowser()
    url = "https://www.pute.ninja.lol/<script>alert('lol')</script>"
    browser.post '/a/add', params={"url"=> url}
    assert_equal browser.last_response.status, 400
    assert_equal JSON.parse(browser.last_response.body), {"msg" => "Bad URI", "success" => false}
  end

  def testDelete()
    b = getbrowser()
    url = "https://twitter.com"
    rand6 = KurzyUtils.gen_hash(6)

    b.post '/a/add', params={"url"=> url, "shorturl"=>rand6}
    assert b.last_response.ok?
    b.get "/#{rand6}"
    assert b.last_response.redirect?
    assert_equal b.last_response.body, ""
    assert_equal b.last_response.header["Location"], url

    b.get "/d/#{rand6}"
    assert_equal b.last_response.status, 400
    assert_equal JSON.parse(b.last_response.body), {"msg" => "You are not allowed to perform this action", "success" => false}

    b.get "/d/#{rand6}", {}, "rack.session" => {"logged" => true}
    assert b.last_response.ok?
    assert JSON.parse(b.last_response.body)["success"]
    assert_equal JSON.parse(b.last_response.body)["short"], rand6
    b.get "/#{rand6}"
    assert b.last_response.ok?
    assert b.last_response.body.include?("value=\"#{rand6}\"")
  end

  def testListFail()
    browser = getbrowser()
    rands = 0.upto(2).to_a.map{|i| KurzyUtils.gen_hash()}
    rands.each_with_index do |r, i|
      url = "https://twitter.com/#{rands[i]}"
      browser.post '/a/add',  params={"url"=> url, "shorturl"=>rands[i]}
      assert browser.last_response.ok?
      response = JSON.parse(browser.last_response.body)
      assert response["success"]
      assert_equal response["url"], url
      assert_equal response["short"], rands[i]
    end
    browser.get '/l/list'
    assert browser.last_response.bad_request?

    KurzyDB.truncate()
  end

  def testLogin()
    browser = getbrowser()
    browser.post '/l/login', params={"password" => "terriblepassword"}
    assert browser.last_response.ok?
    resp = JSON.parse(browser.last_response.body)
    assert_equal resp["msg"], "Successfully logged in"
    assert resp["success"]
  end

  def testBadLogin()
    browser = getbrowser()
    browser.post '/l/login', params={"password" => "anotherterriblepassword"}
    assert browser.last_response.bad_request?
    resp = JSON.parse(browser.last_response.body)
    assert_equal resp["msg"], "Bad password."
    assert_false resp["success"]
  end

  def testListLogged()
    browser = getbrowser()
    browser.post '/l/login', params={"password" => "terriblepassword"}
    assert browser.last_response.ok?

    rands = 0.upto(2).map{|i| KurzyUtils.gen_hash()}
    rands.each_with_index do |r, i|
      url = "https://twitter.com/#{rands[i]}"
      browser.post '/a/add',  params={"url"=> url, "shorturl"=>rands[i]}
      assert browser.last_response.ok?
      response = JSON.parse(browser.last_response.body)
      assert response["success"]
      assert_equal response["url"], url
      assert_equal response["short"], rands[i]
    end
    browser.get '/l/list', {}, 'rack.session' => {:logged =>true}
    assert browser.last_response.ok?
    response = JSON.parse(browser.last_response.body)["list"]
    KurzyDB.truncate()
    assert_equal response.size(), 3
    assert_equal response.map{|i| i['short']}, rands
  end
end

class TestClassePrivAdd < Test::Unit::TestCase

    def testAddNoLogin()
        browser = Rack::Test::Session.new(Rack::MockSession.new(KurzyPrivateInserts))
        url = "https://twitter.com"
        rand6 = KurzyUtils.gen_hash()
        browser.post '/a/add', params={"url"=> url, "shorturl"=>rand6}
        assert browser.last_response.bad_request?
        KurzyDB.truncate()
    end
end
