# encoding: utf-8
require 'rubygems'
require 'bundler'
require 'jeweler'
require './lib/discreet_proxy'

Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.version = DiscreetProxy::VERSION
  gem.name = "discreet_proxy"
  gem.homepage = "http://github.com/julik/discreet_proxy"
  gem.license = "MIT"
  gem.summary = %Q{Parses and creates Flame/Smoke .p proxy icon files}
  gem.email = "me@julik.nl"
  gem.authors = ["Julik Tarkhanov"]
  gem.executables = ["flame_proxy_icon"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test