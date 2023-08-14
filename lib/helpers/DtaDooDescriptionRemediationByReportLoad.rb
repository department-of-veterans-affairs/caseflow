# frozen_string_literal: true

module WarRoom

  # Purpose:
  class DtaDooDescriptionRemediation

    def run_by_report_load(report_load, di_ids = [], env='prod')
      logs = ["DtaDooDescriptionRemediation::Log\n"];
      no_remand_generated = [];
      remand_generated = [];

      # Set the user
      RequestStore[:current_user] = User.system_user

      decision_issues = DecisionIssue.where(id: di_ids)

      higher_levels_reviews = decision_issues.map { |di| di.decision_review if di.decision_review.is_a?(HigherLevelReview) }.compact.uniq

      higher_levels_reviews.each do |hlr|
        decision_issues = decision_issues.select { |di| di.decision_review_id == hlr.id && di.decision_review_type == 'HigherLevelReview' }
        decision_issues.each do |di|
          prev_disp = di.disposition ? di.disposition : "null"
          new_disp = ""
          if di.description.downcase.include?("duty to assist") &&
             !di.disposition.include?("DTA Error")              &&
             !di.disposition.include?("Difference of Opinion")

            new_disp = "DTA Error"
            di.update!(disposition: new_disp)

            log_message = <<-TEXT
              #{Time.zone.now} DtaDooDescriptionRemediation::Log
              HLR ID: #{di.decision_review.id}.  DI ID: #{di.id}
              Previous Disposition: '#{prev_disp}'.
              DI Description: #{di.description}
              Updating Disposition to '#{new_disp}'.
            TEXT
            logs.push(log_message)

          elsif di.description.downcase.include?("difference of opinion") &&
                !di.disposition.include?("Difference of Opinion")         &&
                !di.disposition.include?("DTA Error")

            new_disp = "Difference of Opinion"
            di.update!(disposition: new_disp)

            log_message <<-TEXT
              #{Time.zone.now} DtaDooDescriptionRemediation::Log
              HLR ID: #{di.decision_review.id}.  DI ID: #{di.id}
              Previous Disposition: '#{prev_disp}'.
              DI Description: #{di.description}
              Updating Disposition to '#{new_disp}'.
            TEXT
            logs.push(log_message)
          end
        end

        hlr.create_remand_supplemental_claims!
        log_message = <<-TEXT
          #{Time.zone.now} DtaDooDescriptionRemediation::Log
          Creating Remand Supplemental Claim for
          HLR ID: #{hlr.id}.
        TEXT
        logs.push(log_message)
      end

      logs.push("Remediation Summary Report\n");
      remand_count = 0;
      no_remand_count = 0;

      higher_levels_reviews.each do |hlr|
        supp = SupplementalClaim.find_by(decision_review_remanded_id: hlr.id, decision_review_remanded_type: "HigherLevelReview")
        if supp
          remand_count += 1
          remand_generated.push("Remand Supplemental Claim ID: #{supp.id} was generated for HLR ID: #{hlr.id}.  Claim ID: #{supp&.end_product_establishments&.first&.reference_id}")
        else
          no_remand_count += 1
          no_remand_generated.push("Error: No Remand Supplemental Claim was generated for HLR ID: #{hlr.id}.")
        end
      end

      log_message = <<-TEXT
        Expected Number of Remand Supplemental Claims to be generated: #{hlrs.count}.
        Number of Remand Supplemental Claims created: #{remand_count}.
        Number of Remand Supplemental Claims NOT created: #{no_remand_count}.
      TEXT
      logs.push(log_message)

      logs = logs + remand_generated + no_remand_generated;
      upload_logs_to_aws_s3 logs

    rescue => StandardError => error
      logs.push("DtaDooDescriptionRemediation::Error -- Reference id #{ep_ref}"\
        "Time: #{Time.zone.now}"\
        "#{error.backtrace}")
    end

    private

    def upload_logs_to_aws_s3(logs)
      s3client = Aws::S3::Client.new;
      s3resource = Aws::S3::Resource.new(client: s3client);
      s3bucket = s3resource.bucket("data-remediation-output");
      file_name = "dta-doo-description-remediation-logs/dta-doo-description-remediation-log-#{Time.zone.now}";
      content = logs.join("\n");
      temporary_file = Tempfile.new("dta-log.txt");
      filepath = temporary_file.path;
      temporary_file.write(content);
      temporary_file.flush;
      s3bucket.object(file_name).upload_file(filepath, acl: "private", server_side_encryption: "AES256");
      temporary_file.close!;
    end

  end
end
