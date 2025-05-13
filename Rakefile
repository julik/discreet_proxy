# frozen_string_literal: true

# encoding: utf-8

# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "lib"
  t.test_files = FileList["test/test_*.rb"]
end

task default: [:test]
