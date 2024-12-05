# frozen_string_literal: true

# Job that runs full suite of optional seeds to fully populate caseflow for further testing purposes
class FullSuiteSeedJob < CaseflowJob
  # For time_ago_in_words()
  include ActionView::Helpers::DateHelper
  include RunAsyncable

  require Rails.root.join("db/seeds/optional.rb")
  Dir[Rails.root.join("db/seeds/*.rb")].sort.each { |f| require f }

  queue_with_priority :low_priority
  application_attr :queue

  def perform
    run_full_suite_seeds
    Rails.logger.info("##### OPTIONAL SEEDS COMPLETED on #{Time.zone.now} ####")
  rescue StandardError => error
    log_error(error)
  end

  def run_full_suite_seeds
    # Ensure that the database cleaner is set up correctly
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.cleaning do
      # Call the seed process
      Seeds::Optional.new.seed!
    end
  end
end
