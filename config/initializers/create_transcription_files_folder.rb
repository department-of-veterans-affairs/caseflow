require 'fileutils'

FILE_TYPES = %w[mp4 mp3 vtt rtf xls csv zip json].freeze

# Create the tmp folder with subdirectory for each file type to store transcription files
FILE_TYPES.each do |file_type|
  FileUtils::mkdir_p Rails.root + "tmp/transcription_files/#{file_type}"
end
