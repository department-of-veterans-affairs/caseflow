module WarRoom
  class ReportLoadEndProductSync
    def run_by_report_load(report_load)
      RequestStore[:current_user] = User.system_user

      conn = ActiveRecord::Base.connection

      eps_queried = get_eps(report_load, conn)
      eps_queried.each do |x|
        call_sync(x["reference_id"], report_load, conn)
      end

      # close the connection
      conn.close
    end

    private

    def get_eps(report_load, conn)
      conn.raw_connection.exec_params("SELECT reference_id FROM ep_establishment_workaround where
                                                report_load = $1", [report_load])
    end

    def call_sync(ep_ref, rep_load, conn)
      start_time = Time.now.to_f

      begin
        original_ep = EndProductEstablishment.find_by(reference_id: ep_ref)
        sync_before = original_ep.synced_status

        original_ep.sync!

        end_time = Time.now.to_f
        elapsed_time = (end_time-start_time)*1000
        conn.raw_connection.exec_params("UPDATE ep_establishment_workaround SET synced_status = $1,
                          last_synced_at = $2, sync_duration = $3, prev_sync_status = $4 where reference_id = $5
                          AND report_load = $6", [original_ep.synced_status, Time.zone.now, elapsed_time.to_i,
                          sync_before, ep_ref, rep_load])

      rescue StandardError => error
        end_time = Time.now.to_f
        elapsed_time = (end_time-start_time)*1000

        conn.raw_connection.exec_params("UPDATE ep_establishment_workaround SET synced_error = $1,
                          synced_status = $2, last_synced_at = $3, sync_duration = $4, prev_sync_status = $5
                          where reference_id = $6 AND report_load = $7", [error.message,
                          original_ep&.synced_status ? original_ep.synced_status : nil, Time.zone.now, elapsed_time.to_i,
                          sync_before, ep_ref, rep_load])
      end
    end
  end
end
