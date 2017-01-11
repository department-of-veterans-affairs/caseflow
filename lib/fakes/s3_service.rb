class Fakes::S3Service
  cattr_accessor :files

  def self.store_file(filename, path, _type = :content)
    self.files ||= {}
    tmp = Tempfile.new(filename)
    copy_file_contents(path, tmp)
    self.files[filename] = tmp.path
  end

  def self.fetch_file(filename, dest_filepath)
    copy_file_contents(files[filename], dest_filepath)
  end

  def self.copy_file_contents(source_filepath, dest_filepath)
    File.open(source_filepath, "rb") do |input_stream|
      File.open(dest_filepath, "wb") do |output_stream|
        IO.copy_stream(input_stream, output_stream)
      end
    end
  end
end
