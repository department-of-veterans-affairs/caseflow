#! /usr/bin/env ruby
# concatenate-log.rb

require "json"
require "open-uri"

artifacts_url = "https://circleci.com/api/v1.1/project/github/department-of-veterans-affairs/caseflow/#{ENV['CIRCLE_BUILD_NUM']}/artifacts"
artifacts = JSON.parse(open(artifacts_url).read)

log_file_urls = artifacts.map do |artifact|
  if artifact["path"] =~ /\.log$/
    artifact["url"]
  end
end.compact

log_file_urls.sort! { |a, b| a.split("/")[-1] <=> b.split("/")[-1] }

log_file_urls.each do |log_file_url|
  puts open(log_file_url).read
end
