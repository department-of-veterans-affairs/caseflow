# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

class ExternalApi::BoxService
  BASE_URL = "https://api.box.com"

  def initialize(config:)
    @config = config
  end

  def fetch_access_token
    url = URI::DEFAULT_PARSER.escape("#{BASE_URL}/oauth2/token")

    body = {
      grant_type: "client_credentials",
      client_id: ENV["BOX_CLIENT_ID"],
      client_secret: ENV["BOX_CLIENT_SECRET"],
      box_subject_type: "enterprise",
      box_subject_id: ENV["BOX_ENTERPRISE_ID"]
    }

    headers = {
      "Content-Type" => "application/x-www-form-urlencoded",
      "Accept" => "application/json",
      "Authorization" => CredStash.get("box_#{Rails.deploy_env}_access_token")
    }

    request = HTTPI::Request.new
    request.url = url
    request.body = URI.encode_www_form(body)
    request.headers = headers

    response = HTTPI.post(request)

    ExternalApi::BoxService::AccessTokenFetchResponse.new(response)
  end

  def refresh_access_token
    url = URI::DEFAULT_PARSER.escape("#{BASE_URL}/oauth2/token")

    body = {
      grant_type: "refresh_token",
      client_id: ENV["BOX_CLIENT_ID"],
      client_secret: ENV["BOX_CLIENT_SECRET"],
      refresh_token: CredStash.get("box_#{Rails.deploy_env}_refresh_token")
    }

    headers = {
      "Content-Type" => "application/x-www-form-urlencoded",
      "Accept" => "application/json",
      "Authorization" => CredStash.get("box_#{Rails.deploy_env}_access_token")
    }

    request = HTTPI::Request.new
    request.url = url
    request.body = URI.encode_www_form(body)
    request.headers = headers

    response = HTTPI.post(request)

    ExternalApi::BoxService::AccessTokenRefreshResponse.new(response)
  end

  def upload_to_box(transcription_package)
    uri = URI("https://upload.box.com/api/2.0/files/content")
    req = Net::HTTP::Post.new(uri)
    req["Authorization"] = "Bearer #{@config[:apikey]}"

    folder_name = "VBA_BVA/" + transcription_package.contractor_short_name + " Pickup"
    parent_id = get_folder_id(folder_name)

    preflight_check(transcription_package, transcription_package.name, parent_id)

    file = File.open(transcription_package.file_path)

    req.set_form(
      [
        ["attributes", '{"name":"' + transcription_package.name + '", "parent":{"id":"' + parent_id.to_s + '"}}'],
        ["file", file]
      ],
      "multipart/form-data"
    )

    req_options = {
      use_ssl: uri.scheme == "https"
    }

    resp = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(req)
    end

    file.close

    if resp.is_a?(Net::HTTPSuccess)
      # Handle successful upload
    else
      # Handle failed upload
    end
  end

  private

  #Gets the folder ID with the given folder name
  def get_folder_id(_folder)
    uri = URI("https://api.box.com/2.0/search")
    params = {
      query: "folder"
    }
    uri.query = URI.encode_www_form(params)

    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{@config[:apikey]}"

    req_options = {
      use_ssl: uri.scheme == "https"
    }
    res = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(req)
    end
  end

  def preflight_check(io, filename, parent_id)
    size = io.size

    attributes = { name: filename, parent: { id: "#{parent_id}" }, size: size }
    body_json, res = options("#{FILES_URI}/content", attributes)
  end
end
