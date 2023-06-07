# frozen_string_literal: true

module WarRoom
  # Purpose: to find and sync EPs in Caseflow with VBMS
  class ReportLoadEndProductSync

    require 'csv'
    S3_BUCKET_NAME = "appeals-dbas"

    # Currently, out of sync EPs are tracked in OAR report loads that are sent over and then
    # uploaded to the EP Establishment Workaround table
    # This method implements logic to sync EPs by a specfied report load number
    def run_by_report_load(report_load)
      # Set the user
      RequestStore[:current_user] = User.system_user

      # Establish connection
      conn = ActiveRecord::Base.connection

      eps_queried = get_eps(report_load, conn)
      eps_queried.each do |x|
        call_sync_by_report_load(x["reference_id"], report_load, conn)
      end

      # Close the connection
      conn.close
    end

    # The next two methods are part of the APPEALS-22696 initiative to priority sync
    # all EPs in Caseflow with VBMS
    # The following method is priority syncing cleared EPs
    def run_for_cleared_eps(batch_limit, env)
      RequestStore[:current_user] = User.system_user
      conn = ActiveRecord::Base.connection

      @error_log = []
      @run_log = []

      error_ids = get_error_ids(env)

      eps_queried = get_cleared_eps(batch_limit, error_ids, conn)
      eps_queried.each do |x|
        call_priority_sync(x["reference_id"], conn)
      end

      error_csv = build_csv(@error_log)
      run_csv = build_csv(@run_log)
      log_to_s3(error_csv, env, "cleared_ep_error_log")
      log_to_s3(run_csv, env, "cleared_ep_run_log")
      final_metrics

      conn.close
    end

    # Priority sync for cancelled EPs
    def run_for_cancelled_eps(batch_limit, env)
      RequestStore[:current_user] = User.system_user
      conn = ActiveRecord::Base.connection

      @error_log = []
      @run_log = []

      error_ids = get_error_ids(env)

      eps_queried = get_cancelled_eps(batch_limit, error_ids, conn)
      eps_queried.each do |x|
        call_priority_sync(x["reference_id"], conn)
      end

      error_csv = build_csv(@error_log)
      run_csv = build_csv(@run_log)
      log_to_s3(error_csv, env, "cancelled_ep_error_log")
      log_to_s3(run_csv, env, "cancelled_ep_run_log")
      final_metrics

      conn.close
    end


    private

    ######################################################################
    #
    #   The following methods leverage OAR report loads to sync EPs
    #
    ######################################################################

    # Grab EPs from the specified report load
    def get_eps(report_load, conn)
      conn.raw_connection.exec_params("SELECT reference_id FROM ep_establishment_workaround where
                                              report_load = $1", [report_load])
    end

    # Method to sync with VBMS by report load
    def call_sync_by_report_load(ep_ref, rep_load, conn)
      start_time = Time.now.to_f

      begin
        original_ep = EndProductEstablishment.find_by(reference_id: ep_ref)
        sync_before = original_ep.synced_status

        original_ep.sync!

        end_time = Time.now.to_f
        elapsed_time = (end_time - start_time) * 1000
        conn.raw_connection.exec_params("UPDATE ep_establishment_workaround SET synced_status = $1,
                            last_synced_at = $2, sync_duration = $3, prev_sync_status = $4 where reference_id = $5
                            AND report_load = $6", [original_ep.synced_status, Time.zone.now, elapsed_time.to_i,
                            sync_before, ep_ref, rep_load])

      rescue StandardError => error
        end_time = Time.now.to_f
        elapsed_time = (end_time - start_time) * 1000

        conn.raw_connection.exec_params("UPDATE ep_establishment_workaround SET synced_error = $1,
                            synced_status = $2, last_synced_at = $3, sync_duration = $4, prev_sync_status = $5
                            where reference_id = $6 AND report_load = $7", [error.message,
                            original_ep&.synced_status ? original_ep.synced_status : nil, Time.zone.now, elapsed_time.to_i,
                            sync_before, ep_ref, rep_load])
      end
    end


    ####################################################################
    #
    #    The rest of the code is specific to the priority EP sync
    #
    ####################################################################

    # Helper method for get_error_ids to return txt file contents as an array
    def to_array
      body.read.gsub("\r","").split("\n").map{ |obj| obj[1...-1] }
    end

    # Grab txt file of previously errored EP reference ids from s3 and return as an array
    def get_error_ids(env)
      # Set Client Resources for AWS
      Aws.config.update(region: "us-gov-west-1")
      s3client = Aws::S3::Client.new
      key_name = "ep_establishment_workaround/#{env}/ep_priority_sync/error_ids.txt"

      filepath = s3client.get_object(bucket:'appeals-dbas', key:key_name)
      filepath.to_array
    end

    # Grab cleared EPs that are out of sync
    def get_cleared_eps(batch_limit, error_ids, conn)
      error_ids = error_ids.map { |s| "'#{s}'" }.join(', ')

      raw_sql = <<~SQL
        SELECT
          reference_id
        FROM
          end_product_establishments epe
        INNER JOIN
          vbms_ext_claim vec
        ON
          CAST(epe.reference_id AS numeric) = vec."CLAIM_ID"
        WHERE
          vec."LEVEL_STATUS_CODE" = 'CLR'
        AND
          vec."LEVEL_STATUS_CODE" <> epe.synced_status
        AND
          epe.synced_status not in ('CLR', 'CAN')
        AND
          epe.reference_id NOT IN (#{error_ids})
        ORDER BY
          epe.id ASC
        LIMIT
          batch_limit
      SQL

      conn.execute(raw_sql)
    end

    # Grab cancelled EPs that are out of sync
    def get_cancelled_eps(batch_limit, error_ids, conn)
      error_ids = error_ids.map { |s| "'#{s}'" }.join(', ')

      raw_sql = <<~SQL
        SELECT
          reference_id
        FROM
          end_product_establishments epe
        INNER JOIN
          vbms_ext_claim vec
        ON
          CAST(epe.reference_id AS numeric) = vec."CLAIM_ID"
        WHERE
          vec."LEVEL_STATUS_CODE" = 'CAN'
        AND
          vec."LEVEL_STATUS_CODE" <> epe.synced_status
        AND
          epe.synced_status not in ('CLR', 'CAN')
        AND
          epe.reference_id NOT IN (#{error_ids})
        ORDER BY
          epe.id ASC
        LIMIT
          batch_limit
      SQL

      conn.execute(raw_sql)
    end

    # Method to priority sync with VBMS
    # Also adds data to log files
    def call_priority_sync(ep_ref, conn)
      begin
        epe = EndProductEstablishment.find_by(reference_id: ep_ref)
        sync_status_before = epe.synced_status
        epe.sync!

        @run_log << OpenStruct.new(
          reference_id: epe.reference_id,
          last_synced_at: Time.zone.now,
          synced_status: epe.synced_status,
          prev_synced_status: sync_status_before,
          error: nil
        )

      rescue StandardError => error
        @run_log << OpenStruct.new(
          reference_id: epe.reference_id,
          last_synced_at: Time.zone.now,
          synced_status: epe&.synced_status ? epe.synced_status,
          prev_synced_status: sync_status_before,
          error: error.message
        )
        @error_log << OpenStruct.new(
          reference_id: epe.reference_id,
          last_synced_at: Time.zone.now,
          synced_status: epe&.synced_status ? epe.synced_status,
          prev_synced_status: sync_status_before,
          error: error.message
        )
      end
    end

    # Method to build csv file from data collected during the sync
    def build_csv(input_data)
      CSV.generate do |csv|
        csv << %w[
          reference_id
          last_synced_at
          synced_status
          prev_synced_status
          error
        ]
        input_data.each do |data|
            csv << [
              data.reference_id,
              data.last_synced_at,
              data.synced_status,
              data.prev_sync_status,
              data.error
            ].flatten
        end
      end
    end

    # Save Logs to S3 Bucket
    def log_to_s3(log_file, env, filename)
      # filepath_with_bucket = "appeals-dbas/ep_establishment_workaround/#{env}/ep_priority_sync/"
      # S3Service.store_file(filepath_with_bucket + filename + "--#{Time.zone.now}.csv", log_file)

      filepath_no_bucket = "/ep_establishment_workaround/#{env}/ep_priority_sync/"
      S3Service.store_file(S3_BUCKET_NAME + filepath_no_bucket + filename + "--#{Time.zone.now}.csv", log_file)
    end

    # Spit out metrics at the end of the priority sync
    def final_metrics
      Rails.logger.info("\n \n Priority sync finished at #{Time.zone.now} \n \n EPs attempted to sync: #{@run_log.size} \n EPs successfully synced: #{@run_log.size - @error_log.size} \n EPs errored: #{@error_log.size} \n")
    end
  end
end
