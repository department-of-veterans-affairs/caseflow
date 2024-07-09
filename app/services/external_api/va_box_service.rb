require 'net/http'
require 'json'
require 'jwt'
require 'openssl'
require 'securerandom'
require 'net/http/post/multipart'
require 'mime/types'

class ExternalApi::VaBoxService
  BASE_URL = "https://api.box.com"
  FILES_URI = "#{BASE_URL}/2.0/files"

  def initialize(config:)
    @config = config
  end

  def initialized?
    @initialized
  end

  def fetch_access_token
    response = fetch_jwt_access_token
    @access_token = response['access_token']

    if response['expires_in'] <= Time.now.to_i
      # Fetch a new JWT access token
      response = fetch_jwt_access_token
      @access_token = response['access_token']
    end
  end

  def public_upload_file(file_path, folder_id)
    upload_file(file_path, folder_id)
  end

  def public_get_current_user
    get_current_user
  end

  def public_folder_details(folder_id)
    get_folder_collaborations(folder_id)
  end


  def get_current_user
    uri = URI('https://api.box.com/2.0/users/me')
    req = Net::HTTP::Get.new(uri)
    req['Authorization'] = "Bearer #{@access_token}"

    req_options = {
      use_ssl: uri.scheme == 'https'
    }

    res = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(req)
    end

    if res.code == "200"
      body = JSON.parse(res.body)
      puts "Role: #{body['role']}"
      puts "Status: #{body['status']}"
      body
    else
      raise "Error: #{res.body}"
    end
  end

  def fetch_jwt_access_token
    url = "#{BASE_URL}/oauth2/token"
    payload = {
      iss: @config[:client_id],
      sub: @config[:enterprise_id],
      box_sub_type: 'enterprise',
      aud: url,
      jti: SecureRandom.uuid,
      exp: (Time.now.utc + 60).to_i
    }

    key_content = @config[:private_key]
    passphrase = @config[:passphrase]
    rsa_private = OpenSSL::PKey::RSA.new(key_content, passphrase)
    token = JWT.encode(payload, rsa_private, 'RS256')

    body = {
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: token,
      client_id: @config[:client_id],
      client_secret: @config[:client_secret]
    }

    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri, { 'Content-Type' => 'application/json' })
    request.body = body.to_json

    response = http.request(request)

    if response.code == "200"
      body = JSON.parse(response.body)
      body
    else
      raise "Error: #{response.body}"
    end
  end

  def upload_file(file_path, folder_id)
    url = "https://upload.box.com/api/2.0/files/content"
    uri = URI.parse(url)

    request = Net::HTTP::Post::Multipart.new(uri.path,
      "file" => UploadIO.new(File.new(file_path), "application/zip", File.basename(file_path)),
      "attributes" => { name: File.basename(file_path), parent: { id: folder_id } }.to_json
    )
    request["Authorization"] = "Bearer #{@access_token}"
    request["As-User"] = @config[:as_user] if @config[:as_user]

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    response = http.request(request)

    if response.code == "201"
      body = JSON.parse(response.body)
      body
    else
      puts "As-User: #{@config[:as_user]}"
      puts "Response code: #{response.code}"
      puts "Response body: #{response.body}"
      raise "Error: #{response.body}"
    end
  end

  def get_folder_collaborations(folder_id)
  url = "#{BASE_URL}/2.0/folders/#{folder_id}/collaborations"
  uri = URI.parse(url)

  request = Net::HTTP::Get.new(uri.request_uri)
  request["Authorization"] = "Bearer #{@access_token}"

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  response = http.request(request)

    if response.code == "200"
      body = JSON.parse(response.body)
      body['entries'].each do |collaboration|
      puts "Collaboration ID: #{collaboration['id']}"
      puts "Access level: #{collaboration['accessible_by']['type']}"
      puts "Role: #{collaboration['role']}"
    end
    body
    else
      raise "Error: #{response.body}"
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

end


