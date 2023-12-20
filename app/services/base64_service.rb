# frozen_string_literal: true

class Base64Service
  def self.to_file(base64_string, file_name)
    start_regex = /(?<=;base64,).*/
    regex_result = start_regex.match(base64_string)
    decoded_base64_content = Base64.decode64(regex_result.to_s)
    tempfile = Tempfile.new(file_name, encoding: "ISO-8859-1")
    tempfile.write(decoded_base64_content.force_encoding("ISO-8859-1"))
    tempfile.rewind
    ActionDispatch::Http::UploadedFile.new(
      tempfile: tempfile,
      filename: file_name,
      original_filename: file_name
    )
  end
end
