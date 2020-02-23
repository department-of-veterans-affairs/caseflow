# frozen_string_literal: true

class VacolsLocationBatchUpdater
  include ActiveRecord::Sanitization::ClassMethods

  def initialize(location:, vacols_ids:, user_id:)
    @location = location
    @vacols_ids = vacols_ids
    @user_id = (user_id.presence || "DSUSER").upcase
  end

  # rubocop:disable Metrics/MethodLength
  def call
    conn = connection

    MetricsService.record("VACOLS: batch_update_vacols_location",
                          service: :vacols,
                          name: "batch_update_vacols_location") do
      conn.transaction do
        conn.execute(sanitize_sql_array([<<-SQL, location, vacols_ids]))
          update BRIEFF
          set BFDLOCIN = SYSDATE,
              BFCURLOC = ?,
              BFDLOOUT = SYSDATE,
              BFORGTIC = NULL
          where BFKEY in (?)
        SQL

        conn.execute(sanitize_sql_array([<<-SQL, user_id, vacols_ids]))
          update PRIORLOC
          set LOCDIN = SYSDATE,
              LOCSTRCV = ?,
              LOCEXCEP = 'Y'
          where LOCKEY in (?) and LOCDIN is null
        SQL

        insert_strs = vacols_ids.map do |vacols_id|
          sanitize_sql_array(
            [
              "into PRIORLOC (LOCDOUT, LOCDTO, LOCSTTO, LOCSTOUT, LOCKEY) values (SYSDATE, SYSDATE, ?, ?, ?)",
              location,
              user_id,
              vacols_id
            ]
          )
        end

        insert_str_sql = insert_strs.join(" ")
        conn.execute("insert all #{insert_str_sql} select 1 from dual")
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  private

  attr_reader :location, :vacols_ids, :user_id

  def connection
    VACOLS::Case.connection
  end
end
