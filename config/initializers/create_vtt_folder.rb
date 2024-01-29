require 'fileutils'

# Create the tmp folder where vtts are stored
FileUtils::mkdir_p Rails.root + 'tmp/vtts'
