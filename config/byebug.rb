# config/initializers/byebug.rb
# frozen_string_literal: true

if Rails.env.development?
  require 'byebug/core'
  begin
    Byebug.start_server 'localhost', 8900

  rescue Errno::EADDRINUSE
    Rails.logger.debug 'Byebug server already running'
  end
end
