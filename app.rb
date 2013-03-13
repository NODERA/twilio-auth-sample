# -*- encoding: UTF-8 -*-
require 'bundler/setup'
Bundler.require

SID = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
TOKEN = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
NUMBER = '+815012349876'

class App < Sinatra::Base 
  configure :development do 
    Bundler.require :development 
    register Sinatra::Reloader 
  end 
end

# Redis
redis = Redis.new

get '/' do
  erb :index
end

# 番号登録
post '/auth/register' do
  # 電話番号
  phone_number = params[:phone_number]
  # 一応数字のみにする
  phone_number.gsub!(/[^0-9]/,"")

  # 4桁の暗証番号を生成
  chars = (0..9).to_a
  @digit = ""
  4.times do
    @digit += chars[rand(chars.length)].to_s
  end

  # 一時的にredisにセットする
  redis.set(phone_number, @digit)

  erb :register
end

get '/auth.xml' do
  response = Twilio::TwiML::Response.new do |r|
    r.Gather :timeout => "10", :numDigits => "4", :action => "/auth/callback", :method => "GET" do
      r.Say "Please input your authentic numbers."
    end
    r.Say "We didn't receive any input. Goodbye!"
  end

  content_type 'xml'
  response.text
end

get '/auth/callback' do
  input_digit = params[:Digits]
  phone_number = params[:From]
  check_digit = redis.get(phone_number)
  response = Twilio::TwiML::Response.new do |r|
    if check_digit == nil or check_digit == ""
      r.Say "your phone number is invalid."
    else
      if input_digit == check_digit
        r.Say "Your authorize is complete!"
        # 一時的にRedisに保存していた番号を消す
        redis.del(phone_number)
      else
        r.Say "your input number is bad."
        r.Redirect "/auth.xml", :method => "GET"
      end
    end
  end
  content_type 'xml'
  response.text
end
