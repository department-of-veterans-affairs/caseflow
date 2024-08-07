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

  attr_reader :client_secret, :client_id, :enterprise_id, :private_key, :passphrase

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

  def public_folder_details(folder_id)
    get_child_folders(folder_id)
  end

  def get_child_folder_id(parent_folder_id, child_folder_name)
    folders = public_folder_details(parent_folder_id)
    matching_folder = folders.find { |folder| folder["name"] == child_folder_name }
    if matching_folder
      matching_folder["id"]
    else
      fail "Folder '#{child_folder_name}' not found in parent folder '#{parent_folder_id}'"
    end
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
      Rails.logger.info("Uploading single file: #{file_path}")
      upload_single_file(file_path, folder_id)
    else
      Rails.logger.info("Chunkifying and uploading file: #{file_path}")
      chunkify_and_upload(file_path, folder_id)
    end
  end

  def get_child_folders(parent_folder_id)
    url = "#{BASE_URL}/2.0/folders/#{parent_folder_id}/items"
    uri = URI.parse(url)

    request = Net::HTTP::Get.new(uri.request_uri)
    request["Authorization"] = "Bearer #{@access_token}"

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    response = http.request(request)

    if response.code == "200"
      body = JSON.parse(response.body)
      child_folders = body['entries'].select { |item| item['type'] == 'folder' }
      child_folders
    else
      raise "Error: #{response.body}"
    end
  end

  # rubocop:disable Metrics/MethodLength
  def upload_single_file(file_path, folder_id)
    url = "https://upload.box.com/api/2.0/files/content"
    uri = URI.parse(url)

    request = Net::HTTP::Post::Multipart.new(
      uri.path,
      "file" => UploadIO.new(File.new(file_path), "application/zip", File.basename(file_path)),
      "attributes" => {
        name: File.basename(file_path),
        parent: { id: folder_id }
      }.to_json
    )
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
  # rubocop:enable Metrics/MethodLength

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

# ! 255974435715

# 1. Instantiate the service
# service = ExternalApi::VaBoxService.new(
#   client_secret: "sCHkWIqw2H6ewrYjzObSXTtxMDPZpH2o",
#   client_id: "em2hg82aw4cgee9bwjii96humn99n813",
#   enterprise_id: "828720650",
#   private_key: "-----BEGIN ENCRYPTED PRIVATE KEY-----\nMIIFHDBOBgkqhkiG9w0BBQ0wQTApBgkqhkiG9w0BBQwwHAQIoz61tzppMpUCAggA\nMAwGCCqGSIb3DQIJBQAwFAYIKoZIhvcNAwcECMJdArOHrtfGBIIEyMAUJ5NTd6ZS\nvt+hiiQ9FzSCsBsBgBcKaxJvJI+2LYYqiJuZy06NgrSadPTEXruOfAXUfMmIY4vL\nd9RqrizzsOgUPRbG6oAiwuHlCPSeK84mX3PfR4Xglh033HO1yVclcyR/2O6rMS6I\ntkDivRzPIdN/SMKPTP91ZV1k1jQFNkmneW2MyNuBESFSg6aG3Z1fQmJFk7/ACR6n\nzFe8gYjcohK7T/RQhkNDelQir0xHmWIBA55N1+cOWasNUZClrbbj7gobPakTXXin\n3qo/YvE1GYo1sgiucyBx9S4lhsFRmsGeygi5vuukDreOmzCZ5M306oXzKuD7Gj+8\nAGbFs5n+8fRSdb3ZN9EaQF1bDwaZbkMViC+I8c5Ce+7+Q0vB55w47880JZCPTQke\nXOAwGSE6y2ylGl1a26lkNt/4W4dJk6JKF3Mp0MvzTwbAOMEUP5i0UBDWxGEVHf7L\nn6wKpkLLZQnRhSYO24MWuK6n17FLX0eobT7Ih6X1gAgg5BEtsdpMGatrS9uNUb5K\n+GDjGuf134J7wa4tKb+1pE+NTx5C0fRYu6zveEhMCgBOnUUrYVKfnEy/sgcjrOJN\nA8cS34w5ZJ/MqKz0CH8Yd5VnDSHKGxRnumxWwY/eSIvs5yaL0z3aO5qebImzDsOI\niKT6TK+1KXuq5lZyVqATOsMJ6+eLaAHlbhHEGeoRalJXIs2c/7AEoa3EY3nQawsP\nJIvZImffjZM1ESirrnECfq+/QW3fIr3WKXS+yV4xV4/1AVhi4WPvd/xd6KOL/jn3\nuPh4rciaGc0tMODUa36LTKOCUGMVBfVVhtAY/Z2fgwNmXPJXS+Po5W11W1obBu5f\nuOJf2qQ5wOZVK3XFyrXWobmTud7aQDIcMlebfSLyj+BaFsacEWke/nj1BpOygYB7\nY3g827qp0S+4bcDwrwPBQswBBG0bqaUbxXgJc7bfqh9sTAFK7TBOkCgxic17I2d4\ncUMj8C3J4t/IjLgfLRUW7IhddqcctPDEIcpxyqH1L1ZN+UvDb0KC9JnGaBrCotUY\ncsK49cB1AL6VNNf6b08zLJflI3AuQMqjB1kmpa+tlqfGJyc8KuNRFwujdeLEM0aV\n6s3rs7G2GIk9fCPSFBoX3mLBIQvR6fhsXTgAtr4rhKHYuHigMGa2JWHravnyhFUQ\n1+9iAWgNo3esy4CTpYD6+I13fdldBOt4vS+hoepTL+z+xOEMC2JYSDcT9vg5/W25\nma/ku1xGFFLh51tGn4+kdiEF6meYzzrCi1PBs4qv/GMRPwY6theyVsQHu1wEcN7B\n4xlthFMUXdHyvqc6gxmIKthvtCpxCW+5BWJJlIAvqMD/Dpwq2pSmjEJfeJmALSHm\nVS57d4rwGI2gXDwXBqxfWMdh7EGlREobup/ljEQrlbt3TH7yjACnQgGwCnCrLlHl\nTzhVGrONPF1Kagg8oj9SOrjQgIJ7IbjK/QLQEWwNMz3Ywnhmc8ogrG2UuzJLhG3e\n/dLQwmpSnAXCGFPir6ZEz+mdUYHW3g3sYg38U6yetU+RaZ9DWsqVs74w5jS53vG0\nCy/IlVqL4M1wrUVorQyXOux4CI58O9ArbZ/xUEvVloKfD8CzqQdmO9erqyrrDhkL\n04CXKrboQ8djWpNk5MWWuQ==\n-----END ENCRYPTED PRIVATE KEY-----\n",
#   passphrase: "320c004d1e36338160c91daf78695309",
# )

# as_user: "33458195409"

#2. fetching the access token
# service.fetch_access_token

#3. getting the current application user within box.com
# service.get_current_user

#4. Upload file to box.xom
# file_path = '/path/to/your/file'
# folder_id = 'your_folder_id'
# service.upload_file(file_path, folder_id)

# Specify the file path, folder ID, maximum file size, and chunk size
# file_path = "/Users/brandonreed/projects/appeals/caseflow/app/services/external_api/test_folder_4_dummy.zip"
# folder_id = "255984174879" Raven Return
# max_size = 1024 * 1024 * 1024 # 1GB
# chunk_size = 1024 * 1024 # 1MB

# Upload the file
# service.upload_file(file_path, folder_id, max_size, chunk_size)

# service.public_upload_file(file_path, folder_id)


