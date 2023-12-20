# frozen_string_literal: true

class VACOLS::Correspondent < VACOLS::Record
  require 'csv'
  self.table_name = "corres"
  self.primary_key = "stafkey"

  has_many :cases, foreign_key: :bfcorkey
  attribute :stmdtime, :datetime

  # veteran must be hash containing at least values for { id, deceased_time }
  def self.update_veteran_nod(veteran)
    MetricsService.record("VACOLS: Update veteran NOD:
                          SSN = #{veteran[:veterans_ssn]},
                          PAT = #{veteran[:veterans_pat]}
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
  def self.as_csv(input, col_sep = ",")
    CSV.generate(col_sep: col_sep) do |csv|
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

  class << self
    private

    def find_veteran(stafkey, ssn)
      search1 = find_veteran_by_stafkey(stafkey)
      return search1 if search1.rows.count > 0

      search2 = find_veteran_by_ssn(ssn)
      return search2 if search2.rows.count > 0

      if search1.rows.empty? && search2.rows.empty?
        Rails.logger.info("No veteran found with that identifier")
        :no_veteran
      end
    end

    def update_veteran_nod_in_vacols(veteran)
      update_type = missing_deceased_time(veteran[:deceased_time])
      return update_type unless update_type.nil?

      vet_search_result = find_veteran(veteran[:veterans_pat], veteran[:veterans_ssn])
      return vet_search_result if vet_search_result == :no_veteran

      update_type = should_update_veteran?(veteran, vet_search_result, update_type)
      return update_type if update_type != true

      update_veteran_sfnod(veteran[:deceased_time], vet_search_result)
    end

    def missing_deceased_time(veteran_deceased_time)
      if veteran_deceased_time.nil? || veteran_deceased_time == ""
        Rails.logger.info("No deceased time was provided")
        return :missing_deceased_info
      end
      nil
    end

    def find_veteran_by_stafkey(stafkey)
      query = <<-SQL
        select STAFKEY, SSN, SFNOD
        from CORRES
        where STAFKEY = ?
      SQL

      # exec_query is used so that the return value(s) from the query are directly usable
      connection.exec_query(sanitize_sql_array([query, stafkey]))
    end

    def find_veteran_by_ssn(ssn)
      query = <<-SQL
        select STAFKEY, SSN, SFNOD
        from CORRES
        where SSN = ?
      SQL

      # exec_query is used so that the return value(s) from the query are directly usable
      connection.exec_query(sanitize_sql_array([query, ssn]))
    end

    def should_update_veteran?(veteran, vet_search_result, update_type)
      if vet_search_result.rows.count > 1
        Rails.logger.info("Multiple veterans found with that identifier")
        update_type = :multiple_veterans
      # rows.first gets the array of values for the record, .last is for the sfnod value
      elsif vet_search_result.rows.first&.last&.to_date == veteran[:deceased_time].to_date
        Rails.logger.info("Veteran is already recorded with that deceased time in VACOLS")
        update_type = :already_deceased
      else
        return true
      end

      update_type
    end

    def update_veteran_sfnod(deceased_time, vet_search_result)
      Rails.logger.info("Updating veteran's deceased information")
      current_deceased_time = vet_search_result.rows.first.last

      query = <<-SQL
        update CORRES
        set SFNOD = TO_DATE(?, 'YYYYMMDD'),
            STMDUSER = 'MPIBATCH',
            STMDTIME = SYSDATE
        where STAFKEY = ?
      SQL

      # execute is used here because it directly modifies the rows and exec_query produces a binding error
      connection.execute(sanitize_sql_array([query, deceased_time, vet_search_result.rows.first[0]]))
      if current_deceased_time.nil?
        :successful
      else
        :already_deceased_time_changed
      end
    end
  end
end
