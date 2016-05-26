require "optparse"

namespace :reports do
  desc "Run the mismatch report"
  task run: :environment do
    MismatchReport.new.run!
  end
end
