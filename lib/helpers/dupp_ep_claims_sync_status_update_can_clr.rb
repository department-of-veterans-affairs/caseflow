# frozen_string_literal: true

# This .rb file contains the methods to resolve stuck duplicateEP jobs that are tracked in Metabase
# Use the manual remediation on the 20 remaining claims in UAT.
# 'WarRoom::DuppEpClaimsSyncStatusUpdateCanClr.new.resolve_single_review(***Insert ID***, "hlr")
# for running the remediation for the the hlr **OR**
# 'WarRoom::DuppEpClaimsSyncStatusUpdateCanClr.new.resolve_single_review(***Insert ID***, "sc")') for a
# SupplimentalClaim.
# To fix multiple reviews, run
# 'WarRoom::DuppEpClaimsSyncStatusUpdateCanClr.new.resolve_dup_ep'

module WarRoom
  class DuppEpClaimsSyncStatusUpdateCanClr
    def initialize
      @logs = ["VBMS::DuplicateEP Remediation Log"]
    end

    def resolve_dup_ep
      if retrieve_problem_reviews.count.zero?
        Rails.logger.info("No Supplemental Claims Or Higher Level Reviews with DuplicateEP Error Found")
        return false
      end

      ActiveRecord::Base.transaction do
        starting_record_count = retrieve_problem_reviews.count
        @logs.push("#{Time.zone.now} DuplicateEP::Log Job Started.")
        @logs.push("#{Time.zone.now} DuplicateEP::Log\n"\
          " Records with errors: #{starting_record_count}.")

        resolve_duplicate_end_products(retrieve_problem_reviews, starting_record_count)
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

      resolve_duplicate_end_products(review, review.count)
    end

    def resolve_duplicate_end_products(reviews, starting_record_count)
      index = 0
      records_with_errors = starting_record_count

      while index < records_with_errors

        reviews.each do |review|
          vet = review.veteran
          verb = "start"

          # get the end products from the veteran
          end_products = vet.end_products
          review.end_product_establishments.each do |single_end_product_establishment|
            next if single_end_product_establishment.reference_id.present?

            # Check if active duplicate exists
            next if active_duplicates(end_products, single_end_product_establishment).present?

            verb = "established"
            ep2e = single_end_product_establishment.send(:end_product_to_establish)
            epmf = EndProductModifierFinder.new(single_end_product_establishment, vet)
            taken = epmf.send(:taken_modifiers).compact

            @logs.push("#{Time.zone.now} DuplicateEP::Log"\
              " Veteran participant ID: #{vet.participant_id}."\
              " Review: #{review.class.name}.  EPE ID: #{single_end_product_establishment.id}."\
              " EP status: #{single_end_product_establishment.status_type_code}."\
              " Status: Starting retry.")

            # Mark place to start retrying
            epmf.instance_variable_set(:@taken_modifiers, taken.push(ep2e.modifier))
            ep2e.modifier = epmf.find
            single_end_product_establishment.instance_variable_set(:@end_product_to_establish, ep2e)
            single_end_product_establishment.establish!

            @logs.push("#{Time.zone.now} DuplicateEP::Log"\
              " Veteran participant ID: #{vet.participant_id}.  Review: #{review.class.name}."\
              " EPE ID: #{single_end_product_establishment.id}."\
              " Resolved records: #{index}."\
              " Records with errors: #{records_with_errors}."\
              " Status: Complete.")
          end

          index += 1
          records_with_errors -= 1

          @logs.push("#{Time.zone.now} DuplicateEP::Log"\
            " Veteran participant ID: #{vet.participant_id}.  Review: #{review.class.name}."\
            " Resolved records: #{index}."\
            " Records with errors: #{records_with_errors}."\
            " Status: Complete.")
          call_decision_review_process_job(review, vet)
        end
      end

      @logs.push("#{Time.zone.now} DuplicateEP::Log")
      @logs.push("#{Time.zone.now} Job completed.")
    end

    def active_duplicates(end_products, end_product_establishment)
      end_products.select do |end_product|
        matching_claim_type_code?(end_product, end_product_establishment) &&
          matching_claim_date?(end_product, end_product_establishment) &&
          end_product_establishment_exists?(end_product)
      end
    end

    def matching_claim_type_code?(end_product, end_product_establishment)
      end_product.claim_type_code == end_product_establishment.code
    end

    def matching_claim_date?(end_product, end_product_establishment)
      end_product.claim_date == end_product_establishment.claim_date
    end

    def end_product_establishment_exists?(end_product)
      EndProductEstablishment.where(reference_id: end_product.claim_id).none?
    end

    def call_decision_review_process_job(review, vet)
      begin
        DecisionReviewProcessJob.new.perform(review)
      rescue Caseflow::Error::DuplicateEp => error
        @logs.push(" #{Time.zone.now} | Veteran participant ID: #{vet.participant_id}"\
          " | Review: #{review.class.name} | Review ID: #{review.id} | status: Failed | Error: #{error}")
      else
        create_log
      end
    end

    def create_log
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
