# Requires the following environment variables to be set:
# - VACOLS_PASSWORD 
# - VACOLS_USERNAME

namespace :data do
  staging_only_error = "This command only works in the staging environment. Please run with RAILS_ENV='staging'."

  desc "Prepare test data needed to run a smoke test"
  task :prepare do
    raise staging_only_error unless Rails.env.staging?

    test_appeal_vacols_id = '2765748'

    test_appeal = Appeal.find_or_create_by_vacols_id(test_appeal_vacols_id)
    AppealRepository.uncertify(test_appeal)
  end
end