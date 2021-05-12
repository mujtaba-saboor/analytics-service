# frozen_string_literal: true

require 'itly'

Itly.load do |options|
  options.environment = ENV['APP_ENV'] || :development
end
