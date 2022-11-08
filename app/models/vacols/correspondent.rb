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

  def self.extract(last_extract)
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
      where ( stadtime > ? )
    SQL

    fmtd_query = sanitize_sql_array([query, last_extract])

    connection.exec_query(fmtd_query).to_hash
  end

  # Take in a collection and return a csv friendly format
  def self.as_csv(input)
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
        input.each do |record|
          csv << record.values
        end
    end
  end

  def self.find_veteran(ssn)
    find_veteran_by_ssn(ssn)
  end

  class << self
    private

    def update_veteran_nod_in_vacols(veteran)
      update_type = missing_deceased_ind(veteran[:deceased_ind], veteran[:deceased_time])

      return update_type unless update_type.nil?

      update_type = should_update_veteran?(veteran, find_veteran_by_ssn(veteran[:id]), update_type)

      return update_type if update_type != true

      update_veteran_sfnod(veteran[:id], veteran[:deceased_time], find_veteran_by_ssn(veteran[:id]))
    end

    def missing_deceased_ind(veteran_deceased_ind, veteran_deceased_time)
      if veteran_deceased_ind.nil? || veteran_deceased_ind != "true"
        Rails.logger.info("Veteran deceased indicator is false or null")
        return :missing_deceased_info
      end
      if veteran_deceased_time.nil? || veteran_deceased_time == ""
        Rails.logger.info("No deceased time was provided")
        return :missing_deceased_info
      end
      nil
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

    def should_update_veteran?(veteran, vet_in_vacols, update_type)
      if vet_in_vacols.rows.empty?
        Rails.logger.info("No veteran found with that identifier")
        update_type = :no_veteran
      elsif vet_in_vacols.rows.count > 1
        Rails.logger.info("Multiple veterans found with that identifier")
        update_type = :multiple_veterans
      elsif vet_in_vacols.rows.first[1]&.to_date == veteran[:deceased_time].to_date
        Rails.logger.info("Veteran is already recorded with that deceased time in VACOLS")
        update_type = :already_deceased
      else
        return true
      end

      update_type
    end

    def update_veteran_sfnod(ssn, deceased_time, vet_in_vacols)
      Rails.logger.info("Updating veteran's deceased information")
      current_deceased_time = vet_in_vacols.rows.first[1]

      query = <<-SQL
        update CORRES
        set SFNOD = TO_DATE(?, 'YYYYMMDD')
        where SSN = ?
      SQL

      # execute is used here because it directly modifies the rows and exec_query produces a binding error
      connection.execute(sanitize_sql_array([query, deceased_time, ssn]))
      if current_deceased_time.nil?
        :successful
      else
        :already_deceased_time_changed
      end
    end
  end
end
