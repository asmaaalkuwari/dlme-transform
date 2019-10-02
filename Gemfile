# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'activesupport', '~> 5.2'
gem 'dry-schema'
gem 'faraday'
gem 'hijri'
gem 'stanford-mods' # for date parsing
gem 'thor', '~> 0.20' # for CLI
gem 'timetwister' # for date parsing
gem 'traject_plus', '~> 1.3'

group :development, :test do
  gem 'byebug'
  gem 'pry-byebug'
end

group :test do
  gem 'rspec'
  gem 'rspec_junit_formatter'
  gem 'rubocop', '~> 0.64.0'
  gem 'rubocop-rspec', '~> 1.21.0'
  gem 'simplecov'
end
