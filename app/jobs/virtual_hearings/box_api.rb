require 'boxr'
require 'json'

class BoxAPI
  def initialize(access_token)
    @client = Boxr::Client.new(access_token)
  end

  def upload_file(file_path, parent_folder_id)
    file = @client.upload_file(file_path, parent_folder_id)
    file
  end

  def download_file(file_id, download_path)
    @client.download_file(file_id, version: nil, to: download_path)
  end

  def delete_file(file_id)
    @client.delete_file(file_id)
  end

  def list_files(folder_id)
    items = @client.folder_items(folder_id)
    files = items.select { |item| item.type == 'file' }
    files
  end

  def create_folder(name, parent_folder_id)
    folder = @client.create_folder(name, parent_folder_id)
    folder
  end

  def initialized?
    !@client.nil?
  end
end

# Initialize the BoxAPI class with your access token
# box_api = BoxAPI.new('2s79sUnhFW3ATzYg02SeZApN9Zy9q9da')

# if box_api.initialized?
#   puts "Client was successfully initialized."
# else
#   puts "Client was not initialized."
# end

# # Upload a file
# file = box_api.upload_file('/path/to/your/file', '0') # replace with your actual file path and parent folder ID
# puts "Uploaded file: #{file.name}"

# # Download the file
# download_path = '/path/to/download/directory' # replace with your actual download directory
# box_api.download_file(file.id, download_path)
# puts "Downloaded file to: #{download_path}"

# # Delete the file
# box_api.delete_file(file.id)
# puts "Deleted file: #{file.id}"

# # Get list of files
# files = box_api.list_files('0') # replace '0' with your actual folder ID
# files.each { |file| puts "File: #{file.name}" }

# Create a folder
# folder = box_api.create_folder('Dept', '0') # replace 'New Folder' and '0' with your actual folder name and parent folder ID
# puts "Created folder: #{folder.name}"

# Upload a file
# file = box_api.upload_file('/path/to/your/file', '0') # replace with your actual file path and parent folder ID
# puts "Uploaded file: #{file.name}"

# # Download the file
# download_path = '/path/to/download/directory' # replace with your actual download directory
# box_api.download_file(file.id, download_path)
# puts "Downloaded file to: #{download_path}"

# # Delete the file
# box_api.delete_file(file.id)
# puts "Deleted file: #{file.id}"

# # Get list of files
# files = box_api.list_files('0') # replace '0' with your actual folder ID
# files.each { |file| puts "File: #{file.name}" }

# require 'net/http'
# require 'uri'

# # Replace 'YOUR_ACCESS_TOKEN' with your actual access token
# access_token = 'YOUR_ACCESS_TOKEN'

# # Define a helper method to make the API calls
# def call_api(url, method, access_token)
#   uri = URI(url)
#   http = Net::HTTP.new(uri.host, uri.port)
#   http.use_ssl = true

#   request = case method
#             when :get
#               Net::HTTP::Get.new(uri.request_uri)
#             when :post
#               Net::HTTP::Post.new(uri.request_uri)
#             when :put
#               Net::HTTP::Put.new(uri.request_uri)
#             when :delete
#               Net::HTTP::Delete.new(uri.request_uri)
#             when :options
#               Net::HTTP::Options.new(uri.request_uri)
#             end

#   request['Authorization'] = "Bearer #{access_token}"
#   response = http.request(request)

#   puts "Response: #{response.code} #{response.message}"
#   puts "Body: #{response.body}"
# end

# # Test the API calls
# call_api('https://api.box.com/2.0/files/12345/content', :get, access_token)
# call_api('https://api.box.com/2.0/files/12345/versions', :get, access_token)
# call_api('https://api.box.com/2.0/files/12345/versions/456456', :get, access_token)
# call_api('https://api.box.com/2.0/folders/0/items', :get, access_token)
# call_api('https://api.box.com/2.0/files/content', :options, access_token)
# call_api('https://api.box.com/2.0/files/12345/versions/456456', :delete, access_token)
# call_api('https://api.box.com/2.0/files/12345', :delete, access_token)

