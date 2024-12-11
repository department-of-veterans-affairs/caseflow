# frozen_string_literal: true

# to update ama remand reasons code for existing records in db
# run "bundle exec rake ama_remand_reasons:update_code"

namespace :ama_remand_reasons do
  desc "Update ama remand reasons code for existing records in db"
  task update_code: :environment do
    puts "Started ama remand reason code update #{Time.current}"
    RemandReason.where(code: "error").in_batches do |batch|
      batch.update_all(code: "error_satisfying_regulatory_or_statutory_duty")
    end
    puts "Completed ama remand reason code update #{Time.current}"
  end
end
