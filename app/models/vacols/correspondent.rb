# frozen_string_literal: true

class VACOLS::Correspondent < VACOLS::Record
  self.table_name = "corres"
  self.primary_key = "stafkey"

  has_many :cases, foreign_key: :bfcorkey

  # veteran must be hash containing at least values for { id, deceased_ind, deceased_time }
  def self.update_veteran_nod(veteran)
    MetricsService.record("VACOLS: Update veteran NOD:
                          ID = #{veteran[:id]},
                          deceased_ind = #{veteran[:deceased_ind]},
                          deceased_time = #{veteran[:deceased_time]}",
                          name: "VACOLS::Correspondent.update_veteran_nod_in_vacols",
                          service: :vacols) do
      update_veteran_nod_in_vacols(veteran)
    end
  end

  class << self
    private

    def update_veteran_nod_in_vacols(veteran)
      return Rails.logger.info("Veteran deceased indicator is false or null") unless veteran[:deceased_ind]
      return Rails.logger.info("No deceased time was provided") if veteran[:deceased_time].nil?

      return unless should_update_veteran?(veteran, find_veteran_by_ssn(veteran[:id]))

      update_veteran_sfnod(veteran[:id], veteran[:deceased_time])
    end

    def find_veteran_by_ssn(ssn)
      query = <<-SQL
        select SSN, SFNOD
        from CORRES
        where SSN = ?
      SQL

      # exec_query is used so that the return value(s) from the query are directly usable
      connection.exec_query(sanitize_sql_array([query, ssn]))
    end

    def should_update_veteran?(veteran, vet_in_vacols)
      if vet_in_vacols.rows.empty?
        Rails.logger.info("No veteran found with that identifier")
      elsif vet_in_vacols.rows.count > 1
        Rails.logger.info("Multiple veterans found with that identifier")
      elsif vet_in_vacols.rows.first[1]&.to_date == veteran[:deceased_time].to_date
        Rails.logger.info("Veteran is already recorded with that deceased time in VACOLS")
      else
        return true
      end
      false
    end

    def update_veteran_sfnod(ssn, deceased_time)
      Rails.logger.info("Updating veteran's deceased information")

      query = <<-SQL
        update CORRES
        set SFNOD = TO_DATE(?, 'YYYYMMDD')
        where SSN = ?
      SQL

      # execute is used here because it directly modifies the rows and exec_query produces a binding error
      connection.execute(sanitize_sql_array([query, deceased_time, ssn]))
    end
  end
end
