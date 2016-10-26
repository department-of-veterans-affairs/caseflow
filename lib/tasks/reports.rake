namespace :reports do
  desc "Run the frontend seam report"
  task seam: [:environment] do
    Rails.application.eager_load!
    SeamReport.new.run!
  end

  desc "Run the mismatch report"
  task mismatch: [:environment] do
    Rails.application.eager_load!
    MismatchReport.new.run!
  end
end
