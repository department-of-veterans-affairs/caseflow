# frozen_string_literal: true

require "net/http"
require "json"
require "jwt"
require "openssl"
require "securerandom"
require "net/http/post/multipart"
require "mime/types"
require "fileutils"

class ExternalApi::VaBoxService
  BASE_URL = "https://api.box.com"
  FILES_URI = "#{BASE_URL}/2.0/files"
  CHUNK_SIZE = 50 * 1024 * 1024 # 50 MB

  def initialize(client_secret:, client_id:, enterprise_id:, private_key:, passphrase:)
    @client_secret = client_secret
    @client_id = client_id
    @enterprise_id = enterprise_id
    @private_key = private_key
    @passphrase = passphrase
  end

  def initialized?
    @initialized
  end

  def fetch_access_token
    response = fetch_jwt_access_token
    @access_token = response["access_token"]

    if response["expires_in"] <= Time.now.to_i
      # Fetch a new JWT access token
      response = fetch_jwt_access_token
      @access_token = response["access_token"]
    end
  end

  def public_upload_file(file_path, folder_id)
    upload_file(file_path, folder_id)
  end

  def public_folder_details(folder_id)
    get_folder_collaborations(folder_id)
  end

  def download_file(file_id, destination_path)
    download_url = "#{FILES_URI}/#{file_id}/content"
    uri = URI.parse(download_url)

    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{@access_token}"

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    response = http.request(request)

    if response.code == "200" || response.code == "302"
      File.open(destination_path, "wb") do |file|
        file.write(response.body)
      end
      Rails.logger.info("File downloaded successfully to #{destination_path}")
    else
      Rails.logger.info("Failed to download the file. Response code: #{response.code}")
      Rails.logger.info("Response body: #{response.body}")
      fail "Error: #{response.body}"
    end
  rescue StandardError => error
    log_error(error)
  end

  private

  # rubocop:disable Metrics/MethodLength
  def fetch_jwt_access_token
    url = "#{BASE_URL}/oauth2/token"
    payload = {
      iss: @client_id,
      sub: @enterprise_id,
      box_sub_type: "enterprise",
      aud: url,
      jti: SecureRandom.uuid,
      exp: (Time.now.utc + 60).to_i
    }

    rsa_private = OpenSSL::PKey::RSA.new(@private_key, @passphrase)
    token = JWT.encode(payload, rsa_private, "RS256")

    body = {
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: token,
      client_id: @client_id,
      client_secret: @client_secret
    }

    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri, { "Content-Type" => "application/json" })
    request.body = body.to_json

    response = http.request(request)

    if response.code == "200"
      body = JSON.parse(response.body)
      body
    else
      fail "Error: #{response.body}"
    end
  rescue StandardError => error
    log_error(error)
  end
  # rubocop:enable Metrics/MethodLength

  def upload_file(file_path, folder_id)
    file_size = File.size(file_path)

    if file_size <= CHUNK_SIZE
      upload_single_file(file_path, folder_id)
    else
      chunkify_and_upload(file_path, folder_id)
    end
  end

  def upload_single_file(file_path, folder_id)
    url = "https://upload.box.com/api/2.0/files/content"
    uri = URI.parse(url)

    request = Net::HTTP::Post::Multipart.new(uri.path,
                                             "file" => UploadIO.new(File.new(file_path), "application/zip", File
                                             .basename(file_path)),
                                             "attributes" => { name: File.basename(file_path), parent: { id: folder_id } }
                                             .to_json)
    request["Authorization"] = "Bearer #{@access_token}"

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    response = http.request(request)

    if response.code == "201"
      body = JSON.parse(response.body)
      body
    else
      Rails.logger.info("Response body: #{response.body}")
      fail "Error: #{response.body}"
    end
  rescue StandardError => error
    log_error(error)
  end

  def chunkify_and_upload(file_path, folder_id)
    chunk_paths = split_file(file_path)

    chunk_paths.each_with_index do |chunk_path, _index|
      upload_single_file(chunk_path, folder_id)
      File.delete(chunk_path) # Clean up the chunk file after upload
    end
  end

  def split_file(file_path)
    chunk_paths = []
    file_size = File.size(file_path)
    num_chunks = (file_size.to_f / CHUNK_SIZE).ceil

    File.open(file_path, "rb") do |file|
      num_chunks.times do |i|
        chunk_path = "#{file_path}.part#{i}"
        chunk_paths << chunk_path

        File.open(chunk_path, "wb") do |chunk_file|
          chunk_file.write(file.read(CHUNK_SIZE))
        end
      end
    end

    chunk_paths
  end

  def log_error(error)
    Rails.logger.error(error.message)
    Rails.logger.error(error.backtrace.join("\n"))
  end
end
