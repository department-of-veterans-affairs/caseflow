require "aws-sdk"

# Thin interface to all things Amazon S3
class S3Service
  def self.store_file(filename, content_or_filepath, type = :content)
    init!

    content = (type == :content) ? content_or_filepath : File.open(content_or_filepath, "rb")

    @bucket.put_object(acl: "private",
                       key: filename,
                       body: content,
                       server_side_encryption: "AES256")
  end

  def self.fetch_file(filename, dest_filepath)
    init!

    @client.get_object(
      response_target: dest_filepath,
      bucket: bucket_name,
      key: filename
    )
  end

  def self.init!
    return if @bucket

    Aws.config.update(region: "us-gov-west-1")

    @client = Aws::S3::Client.new
    @resource = Aws::S3::Resource.new(client: @client)
    @bucket = @resource.bucket(bucket_name)
  end

  def self.bucket_name
    Rails.application.config.s3_bucket_name
  end
end
