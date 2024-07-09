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

# def initialized?
  #   @initialized
  # end

 # def get_folder_collaborations(folder_id)
  # url = "#{BASE_URL}/2.0/folders/#{folder_id}/collaborations"
  # uri = URI.parse(url)

  # request = Net::HTTP::Get.new(uri.request_uri)
  # request["Authorization"] = "Bearer #{@access_token}"

  # http = Net::HTTP.new(uri.host, uri.port)
  # http.use_ssl = true

  # response = http.request(request)

  #   if response.code == "200"
  #     body = JSON.parse(response.body)
  #     body['entries'].each do |collaboration|
  #     puts "Collaboration ID: #{collaboration['id']}"
  #     puts "Access level: #{collaboration['accessible_by']['type']}"
  #     puts "Role: #{collaboration['role']}"
  #   end
  #   body
  #   else
  #     raise "Error: #{response.body}"
  #   end
  # end

# def public_folder_details(folder_id)
#     get_folder_collaborations(folder_id)
#   end

  # def public_get_current_user
  #   get_current_user
  # end

  # def get_current_user
  #   uri = URI('https://api.box.com/2.0/users/me')
  #   req = Net::HTTP::Get.new(uri)
  #   req['Authorization'] = "Bearer #{@access_token}"

  #   req_options = {
  #     use_ssl: uri.scheme == 'https'
  #   }

  #   res = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  #     http.request(req)
  #   end

  #   if res.code == "200"
  #     body = JSON.parse(res.body)
  #     puts "Role: #{body['role']}"
  #     puts "Status: #{body['status']}"
  #     body
  #   else
  #     raise "Error: #{res.body}"
  #   end
  # end


# {
#   "boxAppSettings": {
#     "clientID": "em2hg82aw4cgee9bwjii96humn99n813",
#     "clientSecret": "sCHkWIqw2H6ewrYjzObSXTtxMDPZpH2o",
#     "appAuth": {
#       "publicKeyID": "3awcj163",
#       "privateKey": "-----BEGIN ENCRYPTED PRIVATE KEY-----\nMIIFHDBOBgkqhkiG9w0BBQ0wQTApBgkqhkiG9w0BBQwwHAQIoz61tzppMpUCAggA\nMAwGCCqGSIb3DQIJBQAwFAYIKoZIhvcNAwcECMJdArOHrtfGBIIEyMAUJ5NTd6ZS\nvt+hiiQ9FzSCsBsBgBcKaxJvJI+2LYYqiJuZy06NgrSadPTEXruOfAXUfMmIY4vL\nd9RqrizzsOgUPRbG6oAiwuHlCPSeK84mX3PfR4Xglh033HO1yVclcyR/2O6rMS6I\ntkDivRzPIdN/SMKPTP91ZV1k1jQFNkmneW2MyNuBESFSg6aG3Z1fQmJFk7/ACR6n\nzFe8gYjcohK7T/RQhkNDelQir0xHmWIBA55N1+cOWasNUZClrbbj7gobPakTXXin\n3qo/YvE1GYo1sgiucyBx9S4lhsFRmsGeygi5vuukDreOmzCZ5M306oXzKuD7Gj+8\nAGbFs5n+8fRSdb3ZN9EaQF1bDwaZbkMViC+I8c5Ce+7+Q0vB55w47880JZCPTQke\nXOAwGSE6y2ylGl1a26lkNt/4W4dJk6JKF3Mp0MvzTwbAOMEUP5i0UBDWxGEVHf7L\nn6wKpkLLZQnRhSYO24MWuK6n17FLX0eobT7Ih6X1gAgg5BEtsdpMGatrS9uNUb5K\n+GDjGuf134J7wa4tKb+1pE+NTx5C0fRYu6zveEhMCgBOnUUrYVKfnEy/sgcjrOJN\nA8cS34w5ZJ/MqKz0CH8Yd5VnDSHKGxRnumxWwY/eSIvs5yaL0z3aO5qebImzDsOI\niKT6TK+1KXuq5lZyVqATOsMJ6+eLaAHlbhHEGeoRalJXIs2c/7AEoa3EY3nQawsP\nJIvZImffjZM1ESirrnECfq+/QW3fIr3WKXS+yV4xV4/1AVhi4WPvd/xd6KOL/jn3\nuPh4rciaGc0tMODUa36LTKOCUGMVBfVVhtAY/Z2fgwNmXPJXS+Po5W11W1obBu5f\nuOJf2qQ5wOZVK3XFyrXWobmTud7aQDIcMlebfSLyj+BaFsacEWke/nj1BpOygYB7\nY3g827qp0S+4bcDwrwPBQswBBG0bqaUbxXgJc7bfqh9sTAFK7TBOkCgxic17I2d4\ncUMj8C3J4t/IjLgfLRUW7IhddqcctPDEIcpxyqH1L1ZN+UvDb0KC9JnGaBrCotUY\ncsK49cB1AL6VNNf6b08zLJflI3AuQMqjB1kmpa+tlqfGJyc8KuNRFwujdeLEM0aV\n6s3rs7G2GIk9fCPSFBoX3mLBIQvR6fhsXTgAtr4rhKHYuHigMGa2JWHravnyhFUQ\n1+9iAWgNo3esy4CTpYD6+I13fdldBOt4vS+hoepTL+z+xOEMC2JYSDcT9vg5/W25\nma/ku1xGFFLh51tGn4+kdiEF6meYzzrCi1PBs4qv/GMRPwY6theyVsQHu1wEcN7B\n4xlthFMUXdHyvqc6gxmIKthvtCpxCW+5BWJJlIAvqMD/Dpwq2pSmjEJfeJmALSHm\nVS57d4rwGI2gXDwXBqxfWMdh7EGlREobup/ljEQrlbt3TH7yjACnQgGwCnCrLlHl\nTzhVGrONPF1Kagg8oj9SOrjQgIJ7IbjK/QLQEWwNMz3Ywnhmc8ogrG2UuzJLhG3e\n/dLQwmpSnAXCGFPir6ZEz+mdUYHW3g3sYg38U6yetU+RaZ9DWsqVs74w5jS53vG0\nCy/IlVqL4M1wrUVorQyXOux4CI58O9ArbZ/xUEvVloKfD8CzqQdmO9erqyrrDhkL\n04CXKrboQ8djWpNk5MWWuQ==\n-----END ENCRYPTED PRIVATE KEY-----\n",
#       "passphrase": "320c004d1e36338160c91daf78695309"
#     }
#   },
#   "enterpriseID": "828720650"
# }


# 1. Instantiate the service
# service = ExternalApi::VaBoxService.new(config: {
#   client_secret: "sCHkWIqw2H6ewrYjzObSXTtxMDPZpH2o",
#   client_id: "em2hg82aw4cgee9bwjii96humn99n813",
#   enterprise_id: "828720650",
#   private_key: "-----BEGIN ENCRYPTED PRIVATE KEY-----\nMIIFHDBOBgkqhkiG9w0BBQ0wQTApBgkqhkiG9w0BBQwwHAQIoz61tzppMpUCAggA\nMAwGCCqGSIb3DQIJBQAwFAYIKoZIhvcNAwcECMJdArOHrtfGBIIEyMAUJ5NTd6ZS\nvt+hiiQ9FzSCsBsBgBcKaxJvJI+2LYYqiJuZy06NgrSadPTEXruOfAXUfMmIY4vL\nd9RqrizzsOgUPRbG6oAiwuHlCPSeK84mX3PfR4Xglh033HO1yVclcyR/2O6rMS6I\ntkDivRzPIdN/SMKPTP91ZV1k1jQFNkmneW2MyNuBESFSg6aG3Z1fQmJFk7/ACR6n\nzFe8gYjcohK7T/RQhkNDelQir0xHmWIBA55N1+cOWasNUZClrbbj7gobPakTXXin\n3qo/YvE1GYo1sgiucyBx9S4lhsFRmsGeygi5vuukDreOmzCZ5M306oXzKuD7Gj+8\nAGbFs5n+8fRSdb3ZN9EaQF1bDwaZbkMViC+I8c5Ce+7+Q0vB55w47880JZCPTQke\nXOAwGSE6y2ylGl1a26lkNt/4W4dJk6JKF3Mp0MvzTwbAOMEUP5i0UBDWxGEVHf7L\nn6wKpkLLZQnRhSYO24MWuK6n17FLX0eobT7Ih6X1gAgg5BEtsdpMGatrS9uNUb5K\n+GDjGuf134J7wa4tKb+1pE+NTx5C0fRYu6zveEhMCgBOnUUrYVKfnEy/sgcjrOJN\nA8cS34w5ZJ/MqKz0CH8Yd5VnDSHKGxRnumxWwY/eSIvs5yaL0z3aO5qebImzDsOI\niKT6TK+1KXuq5lZyVqATOsMJ6+eLaAHlbhHEGeoRalJXIs2c/7AEoa3EY3nQawsP\nJIvZImffjZM1ESirrnECfq+/QW3fIr3WKXS+yV4xV4/1AVhi4WPvd/xd6KOL/jn3\nuPh4rciaGc0tMODUa36LTKOCUGMVBfVVhtAY/Z2fgwNmXPJXS+Po5W11W1obBu5f\nuOJf2qQ5wOZVK3XFyrXWobmTud7aQDIcMlebfSLyj+BaFsacEWke/nj1BpOygYB7\nY3g827qp0S+4bcDwrwPBQswBBG0bqaUbxXgJc7bfqh9sTAFK7TBOkCgxic17I2d4\ncUMj8C3J4t/IjLgfLRUW7IhddqcctPDEIcpxyqH1L1ZN+UvDb0KC9JnGaBrCotUY\ncsK49cB1AL6VNNf6b08zLJflI3AuQMqjB1kmpa+tlqfGJyc8KuNRFwujdeLEM0aV\n6s3rs7G2GIk9fCPSFBoX3mLBIQvR6fhsXTgAtr4rhKHYuHigMGa2JWHravnyhFUQ\n1+9iAWgNo3esy4CTpYD6+I13fdldBOt4vS+hoepTL+z+xOEMC2JYSDcT9vg5/W25\nma/ku1xGFFLh51tGn4+kdiEF6meYzzrCi1PBs4qv/GMRPwY6theyVsQHu1wEcN7B\n4xlthFMUXdHyvqc6gxmIKthvtCpxCW+5BWJJlIAvqMD/Dpwq2pSmjEJfeJmALSHm\nVS57d4rwGI2gXDwXBqxfWMdh7EGlREobup/ljEQrlbt3TH7yjACnQgGwCnCrLlHl\nTzhVGrONPF1Kagg8oj9SOrjQgIJ7IbjK/QLQEWwNMz3Ywnhmc8ogrG2UuzJLhG3e\n/dLQwmpSnAXCGFPir6ZEz+mdUYHW3g3sYg38U6yetU+RaZ9DWsqVs74w5jS53vG0\nCy/IlVqL4M1wrUVorQyXOux4CI58O9ArbZ/xUEvVloKfD8CzqQdmO9erqyrrDhkL\n04CXKrboQ8djWpNk5MWWuQ==\n-----END ENCRYPTED PRIVATE KEY-----\n",
#   passphrase: "320c004d1e36338160c91daf78695309",
#   as_user: "33458195409"
# })

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
# file_path = "/Users/brandonreed/projects/appeals/caseflow/app/services/external_api/test_folder.zip"
# folder_id = "255984174879" Raven Pickup
# max_size = 1024 * 1024 * 1024 # 1GB
# chunk_size = 1024 * 1024 # 1MB

# Upload the file
# service.upload_file(file_path, folder_id, max_size, chunk_size)

# service.public_upload_file(file_path, folder_id)

# [9] pry(main)> folder_details = service.public_folder_details(folder_id)
# => {"type"=>"folder",
#  "id"=>"255974435715",
#  "sequence_id"=>"1",
#  "etag"=>"1",
#  "name"=>"VBA_BVA",
#  "created_at"=>"2024-03-28T11:45:26-07:00",
#  "modified_at"=>"2024-05-14T11:13:32-07:00",
#  "description"=>"",
#  "size"=>115861,
#  "path_collection"=>
#   {"total_count"=>1,
#    "entries"=>[{"type"=>"folder", "id"=>"0", "sequence_id"=>nil, "etag"=>nil, "name"=>"All Files"}]},
#  "created_by"=>
#   {"type"=>"user",
#    "id"=>"31211694487",
#    "name"=>"Christian Pineiro",
#    "login"=>"boxmoderatesandboxadmin@va.gov"},
#  "modified_by"=>
#   {"type"=>"user",
#    "id"=>"32128616955",
#    "name"=>"Michael Bidwell",
#    "login"=>"Michael.Bidwell@va.gov"},
#  "trashed_at"=>nil,
#  "purged_at"=>nil,
#  "content_created_at"=>"2024-03-28T11:45:26-07:00",
#  "content_modified_at"=>"2024-05-14T11:13:32-07:00",
#  "owned_by"=>
#   {"type"=>"user",
#    "id"=>"31211694487",
#    "name"=>"Christian Pineiro",
#    "login"=>"boxmoderatesandboxadmin@va.gov"},
#  "shared_link"=>nil,
#  "folder_upload_email"=>nil,
#  "parent"=>nil,
#  "item_status"=>"active",
#  "item_collection"=>
#   {"total_count"=>7,
#    "entries"=>
#     [{"type"=>"folder",
#       "id"=>"262846883396",
#       "sequence_id"=>"0",
#       "etag"=>"0",
#       "name"=>"Genesis Pickup"},
#      {"type"=>"folder",
#       "id"=>"262846453574",
#       "sequence_id"=>"0",
#       "etag"=>"0",
#       "name"=>"Genesis Return"},
#      {"type"=>"folder",
#       "id"=>"262848332887",
#       "sequence_id"=>"0",
#       "etag"=>"0",
#       "name"=>"Jamison Pickup"},
#      {"type"=>"folder",
#       "id"=>"262847577584",
#       "sequence_id"=>"1",
#       "etag"=>"1",
#       "name"=>"Jamison Return"},
#      {"type"=>"folder",
#       "id"=>"262847675309",
#       "sequence_id"=>"0",
#       "etag"=>"0",
#       "name"=>"Ravens Pickup"},
#      {"type"=>"folder",
#       "id"=>"255984174879",
#       "sequence_id"=>"1",
#       "etag"=>"1",
#       "name"=>"Ravens Return"},
#      {"type"=>"file",
#       "id"=>"1484930070043",
#       "file_version"=>
#        {"type"=>"file_version",
#         "id"=>"1630028782843",
#         "sha1"=>"b819a8a6beedcd92272126d6ff34fc6f51080f00"},
#       "sequence_id"=>"0",
#       "etag"=>"0",
#       "sha1"=>"b819a8a6beedcd92272126d6ff34fc6f51080f00",
#       "name"=>"TDD Caseflow and VA box.com.docx"}],
#    "offset"=>0,
#    "limit"=>100,
#    "order"=>[{"by"=>"type", "direction"=>"ASC"}, {"by"=>"name", "direction"=>"ASC"}]}}


# User details
# [13] pry(main)> service.public_get_current_user
# Role:
# Status: active
# => {"type"=>"user",
#  "id"=>"33458195409",
#  "name"=>"BVA Hearing Transcripts",
#  "login"=>"AutomationUser_2238660_SeKeLwLFfO@boxdevedition.com",
#  "created_at"=>"2024-04-26T07:00:37-07:00",
#  "modified_at"=>"2024-04-26T07:00:38-07:00",
#  "language"=>"en",
#  "timezone"=>"America/New_York",
#  "space_amount"=>999999999999999,
#  "space_used"=>0,
#  "max_upload_size"=>53687091200,
#  "status"=>"active",
#  "job_title"=>"",
#  "phone"=>"",
#  "address"=>"",
#  "avatar_url"=>"https://moderatesandbox1.app.box.com/api/avatar/large/33458195409",
#  "notification_email"=>nil}

# folder details with permissions
# pry(main)> service.public_folder_details("255974435715")
# Collaboration ID: 52877675715
# Access level: user
# Role: co-owner
# Collaboration ID: 52877195634
# Access level: user
# Role: co-owner
# Collaboration ID: 54619220443
# Access level: user
# Role: editor
# => {"total_count"=>3,
#  "entries"=>
#   [{"type"=>"collaboration",
#     "id"=>"52877675715",
#     "created_by"=>
#      {"type"=>"user",
#       "id"=>"31211694487",
#       "name"=>"Christian Pineiro",
#       "login"=>"boxmoderatesandboxadmin@va.gov"},
#     "created_at"=>"2024-03-28T11:45:26-07:00",
#     "modified_at"=>"2024-03-28T11:45:26-07:00",
#     "expires_at"=>nil,
#     "status"=>"accepted",
#     "accessible_by"=>
#      {"type"=>"user",
#       "id"=>"32128616955",
#       "name"=>"Michael Bidwell",
#       "login"=>"Michael.Bidwell@va.gov"},
#     "invite_email"=>nil,
#     "role"=>"co-owner",
#     "acknowledged_at"=>"2024-03-28T11:45:26-07:00",
#     "item"=>
#      {"type"=>"folder", "id"=>"255974435715", "sequence_id"=>"1", "etag"=>"1", "name"=>"VBA_BVA"},
#     "is_access_only"=>false,
#     "app_item"=>nil},
#    {"type"=>"collaboration",
#     "id"=>"52877195634",
#     "created_by"=>
#      {"type"=>"user",
#       "id"=>"32128616955",
#       "name"=>"Michael Bidwell",
#       "login"=>"Michael.Bidwell@va.gov"},
#     "created_at"=>"2024-03-28T12:42:32-07:00",
#     "modified_at"=>"2024-06-11T11:58:22-07:00",
#     "expires_at"=>nil,
#     "status"=>"accepted",
#     "accessible_by"=>
#      {"type"=>"user", "id"=>"32129514806", "name"=>"Brandon Reed", "login"=>"Brandon.Reed3@va.gov"},
#     "invite_email"=>nil,
#     "role"=>"co-owner",
#     "acknowledged_at"=>"2024-03-28T12:42:32-07:00",
#     "item"=>
#      {"type"=>"folder", "id"=>"255974435715", "sequence_id"=>"1", "etag"=>"1", "name"=>"VBA_BVA"},
#     "is_access_only"=>false,
#     "app_item"=>nil},
#    {"type"=>"collaboration",
#     "id"=>"54619220443",
#     "created_by"=>
#      {"type"=>"user",
#       "id"=>"32128616955",
#       "name"=>"Michael Bidwell",
#       "login"=>"Michael.Bidwell@va.gov"},
#     "created_at"=>"2024-06-12T07:02:55-07:00",
#     "modified_at"=>"2024-06-12T10:41:15-07:00",
#     "expires_at"=>nil,
#     "status"=>"accepted",
#     "accessible_by"=>
#      {"type"=>"user",
#       "id"=>"33458195409",
#       "name"=>"BVA Hearing Transcripts",
#       "login"=>"AutomationUser_2238660_SeKeLwLFfO@boxdevedition.com"},
#     "invite_email"=>nil,
#     "role"=>"editor",
#     "acknowledged_at"=>"2024-06-12T07:02:55-07:00",
#     "item"=>
#      {"type"=>"folder", "id"=>"255974435715", "sequence_id"=>"1", "etag"=>"1", "name"=>"VBA_BVA"},
#     "is_access_only"=>false,
#     "app_item"=>nil}]}

# [4] pry(main)> service.get_child_folders("255974435715")
# => [{"type"=>"folder", "id"=>"262846883396", "sequence_id"=>"0", "etag"=>"0", "name"=>"Genesis Pickup"},
#  {"type"=>"folder", "id"=>"262846453574", "sequence_id"=>"0", "etag"=>"0", "name"=>"Genesis Return"},
#  {"type"=>"folder", "id"=>"262848332887", "sequence_id"=>"0", "etag"=>"0", "name"=>"Jamison Pickup"},
#  {"type"=>"folder", "id"=>"262847577584", "sequence_id"=>"1", "etag"=>"1", "name"=>"Jamison Return"},
#  {"type"=>"folder", "id"=>"262847675309", "sequence_id"=>"0", "etag"=>"0", "name"=>"Ravens Pickup"},
#  {"type"=>"folder", "id"=>"255984174879", "sequence_id"=>"1", "etag"=>"1", "name"=>"Ravens Return"}]

