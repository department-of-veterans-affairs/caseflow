# frozen_string_literal: true

namespace :reviews do
  desc "Resolve multiple reviews"
  task resolve_multiple_reviews: :environment do |_t|
    # finding reviews that potentially need resolution
    RequestStore[:current_user] = OpenStruct.new(
      ip_address: "127.0.0.1",
      station_id: "283",
      css_id: "CSFLOW",
      regional_office: "DSUSER"
    )
    hlrs = HigherLevelReview.where("establishment_error ILIKE '%duplicateep%'")
    problem_hlrs = hlrs.select do |hlr|
      hlr.veteran.end_products.select do |ep|
        ep.claim_type_code.include?("030") && %w[CAN CLR].include?(ep.status_type_code) &&
          [Time.zone.today, 1.day.ago.to_date].include?(ep.last_action_date)
      end.empty?
    end

    scs = SupplementalClaim.where("establishment_error ILIKE '%duplicateep%'")
    problem_scs = scs.select do |sc|
      sc.veteran.end_products.select do |ep|
        ep.claim_type_code.include?("040") && %w[CAN CLR].include?(ep.status_type_code) &&
          [Time.zone.today, 1.day.ago.to_date].include?(ep.last_action_date)
      end.empty?
    end

    problem_reviews = problem_scs + problem_hlrs

    if problem_reviews.count.zero?
      Rails.logger.info("No Supplemental Claims Or Higher Level Reviews with DuplicateEP Error Found")
      exit 0
    end

    if problem_reviews.any?
      resolve_duplicate_eps(problem_reviews)
    end
  end

  def resolve_duplicate_eps(problem_reviews)
    ActiveRecord::Base.transaction do
      problem_reviews.each do |review|
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
          epmf = EndProductModifierFinder.new(single_end_product_establishment, v)
          taken = epmf.send(:taken_modifiers).compact

          # Mark place to start retrying
          epmf.instance_variable_set(:@taken_modifiers, taken.push(ep2e.modifier))
          ep2e.modifier = epmf.find

          single_end_product_establishment.instance_variable_set(:@end_product_to_establish, ep2e)
          single_end_product_establishment.establish!
          single_end_product_establishment.reload
        end

        output_line = "| Veteran participant ID: #{v.participant_id} | #{r.class.name} | Review ID: #{r.id}"

        call_decision_review_process_job(review, verb, output_line)
      end
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
