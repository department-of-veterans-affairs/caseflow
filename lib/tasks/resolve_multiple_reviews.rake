namespace :reviews do
  desc 'Resolve multiple reviews'
  task :resolve_multiple_reviews, [:review_ids, :type] => :environment do |task, args|
    review_ids = args[:review_ids].split(',').map(&:to_i)
    type = args[:type]

    begin
      ActiveRecord::Base.transaction do
        RequestStore[:current_user] = OpenStruct.new(
          ip_address: '127.0.0.1',
          station_id: '283',
          css_id: 'CSFLOW',
          regional_office: 'DSUSER'
        )

        problem_reviews = WarRoom::DuppEpClaimsSyncStatusUpdateCanClr.new.retrieve_problem_reviews

        if type == 'hlr'
          reviews = HigherLevelReview.where(id: problem_reviews.pluck(:id))
        else
          reviews = SupplementalClaim.where(id: problem_reviews.pluck(:id))
        end

        WarRoom::DuppEpClaimsSyncStatusUpdateCanClr.new.resolve_multiple_reviews(problem_reviews, type)
      end
    rescue => e
      puts "An error occurred while resolving multiple reviews: #{e.message}"
      ActiveRecord::Base.rollback_transaction
    end
  end
end
