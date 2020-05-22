# frozen_string_literal: true

class ExternalApi::TableauService
  ERROR_CODE = -1

  def self.authenticate(username)
    uri = URI(ENV["TABLEAU_SSO"])
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Post.new(uri.path)
    req.body = "username=#{username}"
    http.request(req).body
  end
end
