module WarRoom
  class DuppEpClaimsSyncStatusUpdateCanClr

    # finding reviews that potentially need resolution
    def retrieve_problem_reviews
      hlrs = HigherLevelReview.where("establishment_error ILIKE '%duplicateep%'")
      problem_hlrs = hlrs.select{ |hlr| hlr.veteran.end_products.select{ |ep| ep.claim_type_code.include?("030") && ["CAN", "CLR"].include?(ep.status_type_code) && [Date.today, 1.day.ago.to_date].include?(ep.last_action_date) }.empty? }

      scs = SupplementalClaim.where("establishment_error ILIKE '%duplicateep%'")
      problem_scs = scs.select{ |sc| sc.veteran.end_products.select{ |ep| ep.claim_type_code.include?("040") && ["CAN", "CLR"].include?(ep.status_type_code) && [Date.today, 1.day.ago.to_date].include?(ep.last_action_date) }.empty? }

      problem_reviews = problem_scs + problem_hlrs
    end

    def process_claim(epe)
      if epe.status_type_code == 'CAN'
        process_cancelled_claim(epe)
      else
        process_cleared_claim(epe)
      end
    end

    def process_cleared_claim(epe)
      epe.update!(synced_status: 'CLR', last_synced_at: Time.zone.now)
      # epe.send(:cancel!)
      epe.reload
    end

    def process_cancelled_claim(epe)
      epe.update!(synced_status: 'CAN', last_synced_at: Time.zone.now)
      epe.send(:cancel!)
      epe.reload
    end

    # go through each problem_review's EPEs and resolve the status
    # that's causing a stuck EP
    def resolve_duplicate_eps(reviews)
      reviews.each do |r|
        r.end_product_establishments.each do |epe|
          process_claim(epe)
        end
      end
    end

    def run()
      RequestStore[:current_user] = OpenStruct.new(
        ip_address: '127.0.0.1',
        station_id: '283',
        css_id: 'CSFLOW',
        regional_office: 'DSUSER'
      )

      problem_reviews = retrieve_problem_reviews

      if problem_reviews.count.zero?
        put 'No problem Supplemental Claims or Higher Level Reviews found. Exiting.\n'
        return false
      end

      # duplicate_ep_problem_claim, err_msg = get_problem_claim(get_UUID)
      # if !duplicate_ep_problem_claim
      #   put err_msg
      #   return 0
      # end

      ActiveRecord::Base.transaction do
        resolve_duplicate_eps(problem_reviews)
      end
    end
  end
end
