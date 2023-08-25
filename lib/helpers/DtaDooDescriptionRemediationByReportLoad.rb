# frozen_string_literal: true

module WarRoom
  # Purpose: This remediation is intended to resolve an ongoing issue where a user in VBMS
  # will inadvertantly set the disposition on a contention incorecctly when dealing with
  # DTA Errors and Difference of Opinion.
  class DtaDooDescriptionRemediationByReportLoad
    S3_FILE_NAME = "dta-doo-description-remediation-logs"
    S3_ACL = "private"
    S3_ENCRYPTION = "AES256"
    S3_BUCKET = "data-remediation-output"

    def run_by_report_load(report_load)
      logs = ["DtaDooDescriptionRemediation::Log\n"]
      no_remand_generated = []
      remand_generated = []

      # Set the user
      RequestStore[:current_user] = User.system_user

      di_ids = get_decision_issue_ids(report_load).map(&:decision_issue_ids)
      decision_issues = DecisionIssue.where(id: di_ids)

      higher_levels_reviews = decision_issues.where(type: HigherLevelReview).map(&:decision_review).compact.uniq

      higher_levels_reviews.each do |hlr|
        decision_issues = decision_issues.select do |di|
          di.decision_review_id == hlr.id && di.decision_review_type == 'HigherLevelReview'
        end

        decision_issues.each do |di|
          next if di.disposition.include?("Difference of Opinion")
          next if di.disposition.include?("DTA Error")

          new_disp = if di.description.downcase.include?("duty to assist")
                       "DTA Error"
                     elsif di.description.downcase.include?("difference of opinion")
                       "Difference of Opinion"
                     else
                       next
                     end

          logs.push <<-TEXT
            #{Time.zone.now} DtaDooDescriptionRemediation::Log
            HLR ID: #{di.decision_review.id}.  DI ID: #{di.id}
            Previous Disposition: '#{di.disposition}'.
            DI Description: #{di.description}
            Updating Disposition to '#{new_disp}'.
          TEXT

          di.update!(disposition: new_disp)
        end

        hlr.create_remand_supplemental_claims!
        logs.push <<-TEXT
          #{Time.zone.now} DtaDooDescriptionRemediation::Log
          Creating Remand Supplemental Claim for
          HLR ID: #{hlr.id}.
        TEXT
      end

      logs.push("Remediation Summary Report\n");
      remand_count = 0
      no_remand_count = 0

      higher_levels_reviews.each do |hlr|
        supp = SupplementalClaim.find_by(decision_review_remanded_id: hlr.id,
                                         decision_review_remanded_type: "HigherLevelReview")
        if supp
          remand_count += 1
          remand_generated.push("Remand Supplemental Claim ID: #{supp.id} was generated for HLR ID: #{hlr.id}.
                                Claim ID: #{supp&.end_product_establishments&.first&.reference_id}")
        else
          no_remand_count += 1
          no_remand_generated.push("Error: No Remand Supplemental Claim was generated for HLR ID: #{hlr.id}.")
        end
      end

      logs.push <<-TEXT
        Expected Number of Remand Supplemental Claims to be generated: #{hlrs.count}.
        Number of Remand Supplemental Claims created: #{remand_count}.
        Number of Remand Supplemental Claims NOT created: #{no_remand_count}.
      TEXT

      logs = logs + remand_generated + no_remand_generated
    rescue StandardError => error
      logs.push("DtaDooDescriptionRemediation::Error -- #{error.message}"\
        "Time: #{Time.zone.now}"\
        "#{error.backtrace}")
    ensure
      upload_logs_to_aws_s3 logs
      logs
    end

    private

    def upload_logs_to_aws_s3(logs)
      s3client = Aws::S3::Client.new
      s3resource = Aws::S3::Resource.new(client: s3client)
      s3bucket = s3resource.bucket(S3_BUCKET)
      content = logs.join("\n")
      temporary_file = Tempfile.new("dta-log.txt")
      filepath = temporary_file.path
      temporary_file.write(content)
      temporary_file.flush
      s3bucket.object("#{S3_FILE_NAME}-#{Time.zone.now}")
        .upload_file(filepath, acl: S3_ACL, server_side_encryption: S3_ENCRYPTION)
      temporary_file.close!
    end

    # Grab qualifying descision issue IDs so we know what to remediate
    def get_decision_issue_ids(rep_load)
      # Establish connection
      conn = ActiveRecord::Base.connection

      raw_sql = <<~SQL
        WITH oar_epe_ids as (
          SELECT DISTINCT epe.id as epe_id
          FROM end_product_establishments epe
          WHERE epe.reference_id in (SELECT DISTINCT reference_id
                                   FROM ep_establishment_workaround
                                   WHERE report_load = #{rep_load}
                                   )
        ),
        di_id_list as (
          SELECT DISTINCT di.id as decision_issue_ids
          FROM end_product_establishments epe
          JOIN request_issues ri
            ON epe.id = ri.end_product_establishment_id
          JOIN request_decision_issues rdi
            ON ri.id = rdi.request_issue_id
          JOIN decision_issues di
            ON rdi.decision_issue_id = di.id
          JOIN higher_level_reviews hlr
            ON epe.source_type = 'HigherLevelReview' AND epe.source_id = hlr.id
          WHERE epe.id IN (SELECT epe_id FROM oar_epe_ids)
            AND (di.description ilike'%duty to assist%' OR di.description ilike '%Difference of Opinion%')
            AND di.disposition not like '%DTA Error%'
            AND di.disposition not like '%Difference of Opinion%'
            AND epe.source_type = 'HigherLevelReview'
            AND epe.synced_status = 'CLR'
        ),
        hlr_id_list as (
          SELECT DISTINCT hlr.id as hlr_ids
          FROM end_product_establishments epe
          JOIN request_issues ri
            ON epe.id = ri.end_product_establishment_id
          JOIN request_decision_issues rdi
            ON ri.id = rdi.request_issue_id
          JOIN decision_issues di
            ON rdi.decision_issue_id = di.id
          JOIN higher_level_reviews hlr
            ON epe.source_type = 'HigherLevelReview' AND epe.source_id = hlr.id
          WHERE epe.id IN (SELECT epe_id FROM oar_epe_ids)
            AND (di.description ilike'%duty to assist%' OR di.description ilike '%Difference of Opinion%')
            AND di.disposition not like '%DTA Error%'
            AND di.disposition not like '%Difference of Opinion%'
            AND epe.source_type = 'HigherLevelReview'
        ),
        remanded_hlr_ids as(
          SELECT supplemental_claims.decision_review_remanded_id as hlr_ids_with_remand
          FROM supplemental_claims
          WHERE supplemental_claims.decision_review_remanded_id in (SELECT hlr_ids FROM hlr_id_list)
        )
        SELECT DISTINCT di.id as decision_issue_ids, di.description, di.disposition, epe.id as epe_id, hlr.id as higher_level_review_id
        FROM end_product_establishments epe
        JOIN request_issues ri
          ON epe.id = ri.end_product_establishment_id
        JOIN request_decision_issues rdi
          ON ri.id = rdi.request_issue_id
        JOIN decision_issues di
          ON rdi.decision_issue_id = di.id
        JOIN higher_level_reviews hlr
          ON epe.source_type = 'HigherLevelReview' AND epe.source_id = hlr.id
        WHERE epe.id IN (SELECT epe_id FROM oar_epe_ids)
          AND (di.description ilike'%duty to assist%' OR di.description ilike '%Difference of Opinion%')
          AND di.disposition not like '%DTA Error%'
          AND di.disposition not like '%Difference of Opinion%'
          AND epe.source_type = 'HigherLevelReview'
          AND hlr.id not in (SELECT hlr_ids_with_remand FROM remanded_hlr_ids)
      SQL

      response = conn.execute(raw_sql)

      # Close the connection
      conn.close

      response
    end
  end
end
