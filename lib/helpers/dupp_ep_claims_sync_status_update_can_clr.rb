# This .rb file contains the methods to resolve stuck duplicateEP jobs that are tracked in Metabase
# Use the manual remediation on the 20 remaining claims in UAT.
# 'x= WarRoom::DuppEpClaimsSyncStatusUpdateCanClr.new' and ('x.resolve_single_review(***Insert ID***, "hlr")
# for running the remediation for the the hlr **OR** 'x.resolve_single_review(***Insert ID***, "sc")') for a
# SupplimentalClaim.
# To execute the entire array of problem claims with the duplicateEP error. Execute in the rake task method i.e.
# execute 'sudo su -c "source /opt/caseflow-certification/caseflow-certification_env.sh; cd /opt/caseflow-certification/src; bundle exec rake reviews:resolve_multiple_reviews[type]',
# where type is either hlr or sc to cancel all problem claims.

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
        # get the end products from the veteran
        eps = v.end_products
        r.end_product_establishments.each do |epe|
          next if epe.reference_id.present?

          # Check if active duplicate exists
          dupes = eps.select{ |ep| ep.claim_type_code == epe.code && ep.claim_date.to_date == epe.claim_date && EndProductEstablishment.where(reference_id: ep.claim_id).none? }
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
      # storing it as an Array of 1 to be able to re-use resolve_duplicate_eps()
      if type == "hlr"
        review = HigherLevelReview.where(id: review_id)
      else
        review = SupplementalClaim.where(id: review_id)
      end

      resolve_duplicate_eps(review)
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
