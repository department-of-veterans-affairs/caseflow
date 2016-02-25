require 'fileutils'

# Create the tmp folder where pdfs are stored
FileUtils::mkdir_p Rails.root + 'tmp/pdfs'