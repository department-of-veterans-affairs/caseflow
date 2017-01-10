class Fakes::S3Service
  cattr_accessor :files

  def self.store_file(filename, content, _type = :content)
    self.files ||= {}
    self.files[filename] = content
  end

  def self.fetch_file(filename, dest_filepath)
    File.open(dest_filepath, "wb") do |f|
      f.write(files[filename])
    end
  end
end
