# frozen_string_literal: true

module WarRoom

  # Purpose: to find Higher Level Reviews with Duty to Assist (DTA) or Difference of Opinion (DOO)
  # decision issues and remand them to generate Supplemental Claims
  class RemandDtaOrDooHigherLevelReview

    # Currently, HLRs missing SCs are tracked in OAR report loads that are sent over and then
    # uploaded to the EP Establishment Workaround table
    # This method implements logic to remand SCs for a specified report load number
    def run_by_report_load(report_load, env='prod')
      # Set the user
      RequestStore[:current_user] = User.system_user

      @logs = ["\nReport Load #{report_load}: Remand DTA or DOO Higher Level Review Log"]

      # Establish connection
      conn = ActiveRecord::Base.connection

      hlrs_queried = get_hlrs(report_load, conn)
      hlrs_queried.each do |x|
        call_remand(x["reference_id"], conn)
      end

      store_logs_in_s3_bucket(report_load, env)

      # Close the connection
      conn.close
    end

    private

    # Grab qualifying HLRs from the specified report load
    def get_hlrs(rep_load, conn)
      raw_sql = <<~SQL
          WITH oar_list as (SELECT epw."reference_id"        AS "reference_id",
                                  epw."veteran_file_number" AS "veteran_file_number",
                                  epw."synced_status"       AS "synced_status",
                                  epw."report_load"         AS "report_load",
                                  epe."source_id"           AS "source_id",
                                  epe."source_type"         AS "source_type"
                          FROM "public"."ep_establishment_workaround" epw
                                  LEFT JOIN "public"."end_product_establishments" epe
                                              ON epw."reference_id" = epe."reference_id"
                          WHERE epe.source_type = 'HigherLevelReview' AND report_load = '#{rep_load}'),
              no_ep_list as (SELECT distinct oar_list.*
                          FROM oar_list
                                      LEFT JOIN "public"."request_issues" ri
                                              ON (oar_list."source_id" = ri."decision_review_id"
                                                  AND oar_list."source_type" = ri."decision_review_type")
                                      LEFT JOIN "public"."request_decision_issues" rdi
                                              ON ri."id" = rdi."request_issue_id"
                                      LEFT JOIN "public"."decision_issues" di
                                              ON rdi."decision_issue_id" = di."id"
                                      LEFT JOIN "public"."supplemental_claims" sc
                                              ON (oar_list."source_id" = sc."decision_review_remanded_id"
                                                  AND oar_list."source_type" = sc."decision_review_remanded_type")
                                      LEFT JOIN "public"."end_product_establishments" epe
                                              ON sc."id" = epe."source_id" AND epe."source_type" = 'SupplementalClaim'
                          WHERE oar_list."synced_status" = 'CLR'
                              AND (di."disposition" = 'Difference of Opinion'
                              OR di."disposition" = 'DTA Error'
                              OR di."disposition" = 'DTA Error - Exam/MO'
                              OR di."disposition" = 'DTA Error - Fed Recs'
                              OR di."disposition" = 'DTA Error - Other Recs'
                              OR di."disposition" = 'DTA Error - PMRs')
                              AND (sc."decision_review_remanded_id" IS NULL
                              OR epe."source_id" IS NULL)),
              no_040_ep as (SELECT *
                          FROM oar_list
                          intersect
                          SELECT *
                          FROM no_ep_list),
              no_040_sync as (SELECT distinct reference_id,
                          COUNT(no_040_ep.reference_id) FILTER (WHERE report_load = '#{rep_load}') OVER (PARTITION BY no_040_ep.reference_id) as decision_issue_count,
                          COUNT(no_040_ep.reference_id) FILTER (WHERE report_load = '#{rep_load}' AND (decision_sync_processed_at IS NOT NULL OR closed_at IS NOT NULL)) OVER (PARTITION BY no_040_ep.reference_id) as synced_count
                          FROM no_040_ep
                              LEFT JOIN "public"."request_issues" ri
                                      ON (no_040_ep."source_id" = ri."decision_review_id"
                                                  AND no_040_ep."source_type" = ri."decision_review_type")),
              histogram_raw_data as (select no_040_ep.*, decision_issue_count, synced_count,
                                          extc."CLAIM_ID"                                                      as vbms_claim_id,
                                          extc."LIFECYCLE_STATUS_CHANGE_DATE"                                  as vbms_closed_at,
                                          DATE_PART('day', CURRENT_DATE - extc."LIFECYCLE_STATUS_CHANGE_DATE") as age_days
                                  FROM no_040_ep
                                  INNER JOIN no_040_sync ON no_040_ep.reference_id = no_040_sync.reference_id
                                              left join vbms_ext_claim extc
                                                      on extc."CLAIM_ID" = no_040_ep.reference_id::numeric)
          SELECT reference_id
          FROM histogram_raw_data
          WHERE decision_issue_count = synced_count
      SQL

      conn.execute(raw_sql)
    end

    # Method to sync with VBMS
    def call_remand(ep_ref, conn)
      begin
        epe = EndProductEstablishment.find_by(reference_id: ep_ref)
        epe.source.create_remand_supplemental_claims!

      rescue StandardError => error
        @logs.push("RemandDtaOrDooHigherLevelReview::Error -- Reference id #{ep_ref}"\
          "Time: #{Time.zone.now}"\
          "#{error.backtrace}")
      end
    end

    # Save Logs to S3 Bucket
    def store_logs_in_s3_bucket(report_load, env)
      # Set Client Resources for AWS
      Aws.config.update(region: "us-gov-west-1")
      s3client = Aws::S3::Client.new
      s3resource = Aws::S3::Resource.new(client: s3client)
      s3bucket = s3resource.bucket("appeals-dbas")

      # Path to folder and file name
      file_name = "ep_establishment_workaround/#{env}/remand_hlr_logs/remand_dta_or_doo_hlr_report_load_#{report_load}-#{Time.zone.now}"

      # Store contents of logs array in a temporary file
      content = @logs.join("\n")
      temporary_file = Tempfile.new("remand_hlr_log.txt")
      filepath = temporary_file.path
      temporary_file.write(content)
      temporary_file.flush

      # Store File in S3 bucket
      s3bucket.object(file_name).upload_file(filepath, acl: "private", server_side_encryption: "AES256")

      # Delete Temporary File
      temporary_file.close!
    end
  end
end
