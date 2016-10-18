namespace :reports do
  desc "Run the mismatch report"
  task mismatch: [:environment] do
    MismatchReport.new.run!
  end
end
