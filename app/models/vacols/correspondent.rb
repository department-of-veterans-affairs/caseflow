# frozen_string_literal: true

class VACOLS::Correspondent < VACOLS::Record
  require 'csv'
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

  def self.extract 
    query = <<-SQL
      select          
        snamel as vet_last_name,
        snamef as vet_first_name,
        snamemi as vet_middle_name,
        sdob as vet_date_of_birth,
        ssn as vet_ssn,
        null as vet_participant_id,
        slogid as vet_file_number,
        sspare1 as appellant_last_name,
        sspare2 as appellant_first_name,
        sspare3 as appellant_middle_name,
        null as appellant_date_of_birth,
        null as appellant_ssn,
        sgender as appellant_gender,
        ''|| saddrst1 || ' ' || saddrst2 || ' ' || saddrcty || ' ' || saddrstt || ' ' || saddrzip || '' as appellant_address,
        ''|| STELW || ' ' || stelh ||'' as appellant_phone,
        null as appellant_email,
        null as appellant_edi_pi,
        null as appellant_corp_PID,
        stafkey as appellant_vacols_internal_id,
        susrtyp as relationship_to_veteran
      from corres
    SQL

    connection.exec_query(query).to_hash
  end

  # Take in a collection and return a csv friendly format
  def self.to_csv(input)
    CSV.generate do |csv|
        csv << %w[
          VET_LAST_NAME 
          VET_FIRST_NAME
          VET_MIDDLE_NAME
          VET_DATE_OF_BIRTH
          VET_SSN
          VET_PARTICIPANT_ID	
          VET_FILE_NUMBER
          APPELLANT_LAST_NAME
          APPELLANT_FIRST_NAME	
          APPELLANT_MIDDLE_NAME	
          APPELLANT_DATE_OF_BIRTH	
          APPELLANT_SSN	APPELLANT_GENDER
          APPELLANT_ADDRESS
          APPELLANT_PHONE
          APPELLANT_EMAIL
          APPELLANT_EDI_PI
          APPELLANT_CORP_PID	
          APPELLANT_VACOLS_INTERNAL_ID
          RELATIONSHIP_TO_VETERAN
        ]
        input.find_each do |record|
          csv << record.values
        end
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
