# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

group :development, :test do
  gem 'pry'
  gem 'rubocop', require: false
  # Provides a quality report of your Ruby code
  gem 'rubycritic', require: false
end

group :test do
  gem 'rspec'
  gem 'simplecov', require: false

  # gem 'cucumber'
end

group :development do
  # uncomment yard if you are building an API
  # for help see: https://github.com/lsegal/yard
  # gem 'yard'
end
