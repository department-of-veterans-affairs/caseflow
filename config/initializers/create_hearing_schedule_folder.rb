require 'fileutils'

# Create the tmp folder where spreadsheets are stored
FileUtils::mkdir_p Rails.root + 'tmp/hearing_schedule/spreadsheets'