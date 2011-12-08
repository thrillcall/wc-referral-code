# -*- encoding: utf-8 -*-

require 'rubygems'
require 'bundler'
Bundler.setup

require 'minitest/spec'
require 'minitest/autorun'
require 'redis'
require 'redis-namespace'

r = Redis.new(:host => "localhost", :port => 6379)
$redis = Redis::Namespace.new("test", :redis => r)
$redis.select 10
