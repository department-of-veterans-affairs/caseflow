namespace :reports do
  desc "Run the frontend seam report"
  task seam: [:environment] do
    SeamReport.new.run!
  end

  desc "Run the mismatch report"
  task mismatch: [:environment] do
    MismatchReport.new.run!
  end
end
