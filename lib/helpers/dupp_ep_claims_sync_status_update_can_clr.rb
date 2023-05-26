# frozen_string_literal: true

# This .rb file contains the methods to resolve stuck duplicateEP jobs that are tracked in Metabase
# Use the manual remediation on the 20 remaining claims in UAT.
# 'x = WarRoom::DuppEpClaimsSyncStatusUpdateCanClr.new' and ('x.resolve_single_review(***Insert ID***, "hlr")
# for running the remediation for the the hlr **OR** 'x.resolve_single_review(***Insert ID***, "sc")') for a
# SupplimentalClaim.
# To execute the entire array of problem claims with the duplicateEP error. Execute in the rake task method i.e.
# execute 'sudo su -c "source /opt/caseflow-certification/caseflow-certification_env.sh;
# cd /opt/caseflow-certification/src; bundle exec rake reviews:resolve_multiple_reviews'
# Another way to run multiple reviews can be performed by
# 'x = WarRoom::DuppEpClaimsSyncStatusUpdateCanClr.new' & 'x.run'

module WarRoom
  class DuppEpClaimsSyncStatusUpdateCanClr
    def run
      RequestStore[:current_user] = OpenStruct.new(
        ip_address: "127.0.0.1",
        station_id: "283",
        css_id: "CSFLOW",
        regional_office: "DSUSER"
      )

      if retrieve_problem_reviews.count.zero?
        Rails.logger.info("No Supplemental Claims Or Higher Level Reviews with DuplicateEP Error Found")
        return false
      end

      ActiveRecord::Base.transaction do
        resolve_duplicate_end_products(retrieve_problem_reviews)
      end
    end

    # finding reviews that potentially need resolution
    def retrieve_problem_reviews
      find_supplement_claims_with_errors + find_hlrs_with_errors
    end

    def find_supplement_claims_with_errors
      supplemental_claims_with_errors = SupplementalClaim.where("establishment_error ILIKE '%duplicateep%'")
      supplemental_claims_with_errors.select do |supplemental_claim|
        supplemental_claim.veteran.end_products.select do |end_product|
          end_product.claim_type_code.include?("040") && %w[CAN CLR].include?(end_product.status_type_code) &&
            [Time.zone.today, 1.day.ago.to_date].include?(end_product.last_action_date)
        end.empty?
      end
    end

    def find_hlrs_with_errors
      hlrs_with_errors = HigherLevelReview.where("establishment_error ILIKE '%duplicateep%'")
      hlrs_with_errors.select do |hlr|
        hlr.veteran.end_products.select do |end_product|
          end_product.claim_type_code.include?("030") && %w[CAN CLR].include?(end_product.status_type_code) &&
            [Time.zone.today, 1.day.ago.to_date].include?(end_product.last_action_date)
        end.empty?
      end
    end

    def resolve_single_review(review_id, type)
      # retrieve the ClaimReview based on the ID and type passed in
      # storing it as an Array of 1 to be able to re-use resolve_duplicate_end_productss()
      review = if type == "hlr"
                 HigherLevelReview.where(id: review_id)
               else
                 SupplementalClaim.where(id: review_id)
               end

      resolve_duplicate_end_products(review)
    end

    def resolve_duplicate_end_products(reviews)
      reviews.each do |review|
        vet = review.veteran
        verb = "cleared"

        # get the end products from the veteran
        end_products = vet.end_products
        review.end_product_establishments.each do |single_end_product_establishment|
          next if single_end_product_establishment.reference_id.present?

          # Check if active duplicate exists
          next if active_duplicates?(end_products, single_end_product_establishment)

          verb = "established"
          ep2e = single_end_product_establishment.send(:end_product_to_establish)
          epmf = EndProductModifierFinder.new(single_end_product_establishment, vet)
          taken = epmf.send(:taken_modifiers).compact

          # Mark place to start retrying
          epmf.instance_variable_set(:@taken_modifiers, taken.push(ep2e.modifier))
          ep2e.modifier = epmf.find

          single_end_product_establishment.instance_variable_set(:@end_product_to_establish, ep2e)
          single_end_product_establishment.establish!
          single_end_product_establishment.reload
        end

        output_line = "| Veteran participant ID: #{vet.participant_id} | #{review.class.name} | Review ID: #{review.id}"

        call_decision_review_process_job(review, verb, output_line)
      end
    end

    def active_duplicates?(end_products, end_product_establishment)
      end_products.select do |end_product|
        matching_claim_type_code?(end_products, end_product_establishment) &&
          matching_claim_date?(end_products, end_product_establishment) &&
          end_product_establishment_exists?(end_product)
      end
    end

    def matching_claim_type_code?(end_products, end_product_establishment)
      end_products.claim_type_code == end_product_establishment.code
    end

    def matching_claim_date?(end_products, end_product_establishment)
      end_products.claim_date.to_date == end_product_establishment.claim_date
    end

    def end_product_establishment_exists?(end_product)
      EndProductEstablishment.where(reference_id: end_product.claim_id).none?
    end

    def call_decision_review_process_job(review, verb, output_line)
      begin
        DecisionReviewProcessJob.new.perform(review)
      rescue Caseflow::Error::DuplicateEp => error
        output_line = "| DuplicateEp Error from DecisionReviewProcessJob #{output_line} #{error}"
      else
        output_line = "| #{verb} #{output_line}"
      ensure
        output = "#{output_line}\n"
        create_log(output)
      end
    end

    def create_log(output)
      @logs = ["Duplicate EP Error Remediation Log: #{Time.zone.now}", output]
      @logs.push("#{Time.zone.now} DuplicateEP::Log", output)
      content = @logs.join("\n")
      temporary_file = Tempfile.new("cdc-log.txt")
      filepath = temporary_file.path
      temporary_file.write(content)
      temporary_file.flush

      upload_logs_to_s3(filepath)

      temporary_file.close!
    end

    def upload_logs_to_s3(filepath)
      s3client = Aws::S3::Client.new
      s3resource = Aws::S3::Resource.new(client: s3client)
      s3bucket = s3resource.bucket("data-remediation-output")
      file_name = "duplicate-ep-remediation-logs/duplicate-ep-remediation-log-#{Time.zone.now}"

      # Store file to S3 bucket
      s3bucket.object(file_name).upload_file(filepath, acl: "private", server_side_encryption: "AES256")
    end
  end
end
