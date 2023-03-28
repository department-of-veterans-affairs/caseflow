namespace :reviews do
  desc "Resolve multiple reviews"
  task :resolve_multiple_reviews => :environment do |t|

    # finding reviews that potentially need resolution
    RequestStore[:current_user] = OpenStruct.new(
      ip_address: '127.0.0.1',
      station_id: '283',
      css_id: 'CSFLOW',
      regional_office: 'DSUSER'
    )
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

    if problem_reviews.count.zero?
      puts 'No problem Supplemental Claims or Higher Level Reviews found.'
      exit 0
    end

    if problem_reviews.any?
      resolve_duplicate_eps(problem_reviews)
    end
  end

  def resolve_duplicate_eps(problem_reviews)
    s3client=Aws::S3::Client.new;
    s3resource=Aws::S3::Resource.new(client: s3client);
    s3bucket=s3resource.bucket("data-remediation-output");
    file_name = "duplicate-ep-remediation-logs/duplicate-ep-remediation-log-#{Time.zone.now}";

    ActiveRecord::Base.transaction do
      output = ""
      problem_reviews.each do |r|
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
      return output
    end

    @logs = ["Duplicate EP Error Remediation Log: #{Time.zone.now}", output]
    @logs.push("#{Time.zone.now} DuplicateEP::Log", output)
    content=@logs.join("\n");
    temporary_file=Tempfile.new("cdc-log.txt");
    filepath=temporary_file.path;
    temporary_file.write(content);
    temporary_file.flush;
    s3bucket.object(file_name).upload_file(filepath, acl: "private", server_side_encryption: "AES256");
    temporary_file.close!;
  end
end
