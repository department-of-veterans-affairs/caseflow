# frozen_string_literal: true

class VACOLS::Correspondent < VACOLS::Record
  self.table_name = "corres"
  self.primary_key = "stafkey"

  has_many :cases, foreign_key: :bfcorkey

  def self.test_call_please_ignore
    Rails.logger.info("Test call please ignore")
    true
  end

  def self.update_veteran_nod(veteran)
    MetricsService.record("VACOLS: update_veteran_nod_in_vacols",
                          name: "update_veteran_nod_in_vacols",
                          service: :vacols) do
      update_veteran_nod_in_vacols(veteran)
    end
  end

  class << self
    private

    # vet_updates must be hash containing at least values for { id, deceased_time }
    def update_veteran_nod_in_vacols(veteran)
      return Rails.logger.info("Veteran deceased indicator is false or null") unless veteran[:deceased_ind]
      return Rails.logger.info("No deceased time was provided") if veteran[:deceased_time].nil?

      return unless should_update_veteran?(veteran, find_veteran_by_ssn(veteran[:id]))

      Rails.logger.info("Updating veteran deceased information")
      update_veteran_sfnod(veteran[:id], veteran[:deceased_time])
    end

    def find_veteran_by_ssn(ssn)
      query = <<-SQL
        select SSN, SFNOD
        from CORRES
        where SSN = ?
      SQL

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
      query = <<-SQL
        update CORRES
        set SFNOD = TO_DATE(?, 'YYYYMMDD')
        where SSN = ?
      SQL

      connection.execute(sanitize_sql_array([query, deceased_time, ssn]))
    end
  end
end
