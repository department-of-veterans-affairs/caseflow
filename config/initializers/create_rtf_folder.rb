require 'fileutils'

# Create the tmp folder where rtfs are stored
FileUtils::mkdir_p Rails.root + 'tmp/rtfs'
