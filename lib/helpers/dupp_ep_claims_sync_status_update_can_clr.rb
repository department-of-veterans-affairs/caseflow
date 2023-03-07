module WarRoom
  class DuppEpClaimsSyncStatusUpdateCanClr

    # finding reviews that potentially need resolution
    def retrieve_problem_reviews
      hlrs = HigherLevelReview.where("establishment_error ILIKE '%duplicateep%'")
      problem_hlrs = hlrs.select{ |hlr|
        hlr.veteran.end_products.select { |ep|
          ep.claim_type_code.include?("030") && ["CAN", "CLR"].include?(ep.status_type_code) &&
           [Date.today, 1.day.ago.to_date].include?(ep.last_action_date)
        }.empty?
      }

      scs = SupplementalClaim.where("establishment_error ILIKE '%duplicateep%'")
      problem_scs = scs.select{ |sc|
        sc.veteran.end_products.select { |ep|
          ep.claim_type_code.include?("040") && ["CAN", "CLR"].include?(ep.status_type_code) &&
          [Date.today, 1.day.ago.to_date].include?(ep.last_action_date)
        }.empty?
      }

      problem_reviews = problem_scs + problem_hlrs
    end

    def resolve_duplicate_eps(reviews)
      output = ""

      reviews.each do |r|
        v = r.veteran
        verb = "cleared"
        r.end_product_establishments.each do |epe|
          next if epe.reference_id.present?

          # Check if active duplicate exists
          dupes = epe.select{ |ep| ep.claim_type_code == epe.code && ep.claim_date.to_date == epe.claim_date && EndProductEstablishment.where(reference_id: ep.claim_id).none? }
          next if dupes.any?

          verb = "established"
          ep2e = epe.send(:end_product_to_establish)
          epmf = EndProductModifierFinder.new(epe, v)
          taken = epmf.send(:taken_modifiers).compact

          # Mark place to start retrying
          epmf.instance_variable_set(:@taken_modifiers, taken.push(ep2e.modifier))
          ep2e.modifier = epmf.find

          epe.instance_variable_set(:@end_product_to_establish, ep2e)
          epe.establish!
          epe.reload
        end

        output_line = "| Veteran participant ID: #{v.participant_id} | #{r.class.name} | Review ID: #{r.id}"

        begin
          DecisionReviewProcessJob.new.perform(r)
        rescue Caseflow::Error::DuplicateEp => error
          output_line = "| DuplicateEp error #{output_line}"
        else
          output_line = "| #{verb} #{output_line}"
        ensure
          output = "#{output_line}\n#{output}"
        end
      end

      puts output
    end

    def resolve_single_review(review_id, type)
      # retrieve the ClaimReview based on the ID and type passed in
      if type == "hlr"
        review = HigherLevelReview.where(id: review_id)
      else
        review = SupplementalClaim.where(id: review_id)
      end

      veteran = review.veteran

      # getting end_product_establishments count
      epe_count = review.end_product_establishments.count

      if epe_count.positive?
        # iterate through the EPE list
        review.end_product_establishments.each do |epe_1|
          # start remediation steps
          # assign the EP to establish
          ep2e_1 = epe_1.send(:end_product_to_establish)
          # assign the EndProductModifierFinder
          epmf_1 = EndProductModifierFinder.new(epe_1, veteran)
          taken_1 = epmf_1.send(:taken_modifiers)
          #Remediation: => []

          # Mark place to start retrying
          epmf_1.instance_variable_set(:@taken_modifiers, taken_1.push(ep2e_1.modifier))
          ep2e_1.modifier = epmf_1.find
          epe_1.instance_variable_set(:@end_product_to_establish, ep2e_1)
          epe_1.establish!
          epe_1.reload
        end

        DecisionReviewProcessJob.new.perform(review)
        review.reload
        review.establishment_error #should now be =>nil
      else
        puts "There are no EndProductEstablishments on this Review"
        return false
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
        puts 'No problem Supplemental Claims or Higher Level Reviews found.'
        return false
      end

      ActiveRecord::Base.transaction do
        resolve_duplicate_eps(problem_reviews)
      end
    end
  end
end
