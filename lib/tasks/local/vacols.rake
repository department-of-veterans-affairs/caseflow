# frozen_string_literal: true

require "csv"
require "rainbow"

namespace :local do
  namespace :vacols do
    desc "A rake task to be used in CI to ensure the DB is ready"
    task wait_for_connection: :environment do
      puts "Pinging FACOLS until it responds."

      facols_is_ready = false

      # rubocop:disable Lint/HandleExceptions
      180.times do
        begin
          if VACOLS::Case.count == 0 &&
             VACOLS::CaseHearing.select("VACOLS.HEARING_VENUE(vdkey)").where(folder_nr: "1").count == 0
            puts "FACOLS is ready."
            facols_is_ready = true
            break
          end
        rescue StandardError
        end

        sleep 1
      end
      # rubocop:enable Lint/HandleExceptions

      unless facols_is_ready
        fail "Gave up waiting for FACOLS to get ready and we won't leave alone"
      end
    end

    # rubocop:disable Metrics/MethodLength
    def setup_facols(suffix)
      puts "Stopping vacols-db-#{suffix} and removing existing volumes"
      `docker-compose stop vacols-db-#{suffix}`
      `docker-compose rm -f -v vacols-db-#{suffix}`
      puts "Starting database, and logging to #{Rails.root.join('tmp', 'vacols.log')}"
      `docker-compose up vacols-db-#{suffix} &> './tmp/vacols.log' &`

      # Loop until setup is complete. At most 10 minutes
      puts "Waiting for the database to be ready"
      setup_complete = false
      600.times do
        if `grep -q 'Done ! The database is ready for use' ./tmp/vacols.log; echo $?` == "0\n"
          setup_complete = true
          break
        end
        sleep 1
      end

      if setup_complete
        puts "Updating schema"
        oracle_wait_time = 180
        schema_complete = false
        oracle_wait_time.times do
          output = `docker exec --tty -i VACOLS_DB-#{suffix} bash -c \
          "source /home/oracle/.bashrc; sqlplus /nolog @/ORCL/setup_vacols.sql"`
          if !output.include?("SP2-0640: Not connected")
            schema_complete = true
            break
          end
          sleep 1
        end

        if schema_complete
          puts "Schema loaded"
        else
          puts "Schema load failed -- you may need to increase Oracle wait time from #{oracle_wait_time} seconds"
        end
      else
        puts "Failed to setup database"
      end
    end
    # rubocop:enable Metrics/MethodLength

    desc "Starts and sets up a dockerized local VACOLS"
    task setup: :environment do
      setup_facols(Rails.env)
    end

    desc "Seeds local VACOLS"
    task seed: :environment do
      date_shift = Time.now.utc.beginning_of_day - Time.utc(2017, 12, 10)
      hearing_date_shift = Time.now.utc.beginning_of_day - Time.utc(2017, 7, 25)

      read_csv(VACOLS::Case, date_shift)
      read_csv(VACOLS::Folder, date_shift)
      read_csv(VACOLS::Representative, date_shift)
      read_csv(VACOLS::Correspondent, date_shift)
      read_csv(VACOLS::CaseIssue, date_shift)
      read_csv(VACOLS::Note, date_shift)
      read_csv(VACOLS::CaseHearing, hearing_date_shift)
      read_csv(VACOLS::Actcode, date_shift)
      read_csv(VACOLS::Decass, date_shift)
      read_csv(VACOLS::Staff, date_shift)
      read_csv(VACOLS::Vftypes, date_shift)
      read_csv(VACOLS::Issref, date_shift)
      read_csv(VACOLS::TravelBoardSchedule, date_shift)

      create_issrefs
    end

    # Do not check in the result of running this without talking with Chris. We need to certify that there
    # is no PII in the results.
    desc "Dumps data from UAT VACOLS - must run with RAILS_ENV=ssh_forwarding"
    task dump_data: :environment do
      puts "Getting data from VACOLS, sanitizing it, and dumping it to local files."

      case_descriptors = []
      CSV.foreach(Rails.root.join("local/vacols", "cases.csv"), headers: true) do |row|
        case_descriptors << row.to_h
      end

      ids = case_descriptors.map do |c|
        c["vacols_id"]
      end

      cases = VACOLS::Case.includes(
        :folder,
        :vacols_representatives,
        :correspondent,
        :case_issues,
        :notes,
        :case_hearings,
        :decass
      ).find(ids)

      sanitizer = Helpers::Sanitizers.new

      VACOLS::Staff.all.each_with_index do |staff, row_index|
        sanitizer.generate_staff_mapping(staff, row_index)
      end

      write_csv(VACOLS::Staff, VACOLS::Staff.all, sanitizer)

      # In order to add a new table, you'll also need to add a sanitize and white_list method
      # to the Helpers::Sanitizers class.
      write_csv(VACOLS::Case, cases, sanitizer)
      write_csv(VACOLS::Folder, cases.map(&:folder), sanitizer)
      write_csv(VACOLS::Representative, cases.map(&:vacols_representatives), sanitizer)
      write_csv(VACOLS::Correspondent, cases.map(&:correspondent), sanitizer)
      write_csv(VACOLS::CaseIssue, cases.map(&:case_issues), sanitizer)
      write_csv(VACOLS::Note, cases.map(&:notes), sanitizer)
      write_csv(VACOLS::CaseHearing, cases.map(&:case_hearings), sanitizer)
      write_csv(VACOLS::Decass, cases.map(&:decass), sanitizer)

      # We do not dump all of the vftypes table since there are some rows that seem not relevant to our work and
      # may contain things we should not check in. Instead we're scoping it to Diagnostic Codes (DG), and remand
      # reasons (RR, R5, and IIRC).
      write_csv(
        VACOLS::Vftypes,
        VACOLS::Vftypes.where("ftkey LIKE ? OR ftkey LIKE ? OR ftkey LIKE ? OR ftkey LIKE ?",
                              "DG%", "RR%", "R5%", "IIRC%"),
        sanitizer
      )
      write_csv(VACOLS::Issref, VACOLS::Issref.all, sanitizer)
      write_csv(
        VACOLS::TravelBoardSchedule,
        VACOLS::TravelBoardSchedule.where("tbyear > 2016"),
        sanitizer
      )
      write_csv(VACOLS::Actcode, VACOLS::Actcode.all, sanitizer)

      # This must be run after the write_csv line for VACOLS::Case so that the VBMS ids get sanitized.
      vbms_record_from_case(cases, case_descriptors)
      bgs_record_from_case(cases, case_descriptors)
      sanitizer.errors.each do |error|
        puts Rainbow(error).red
      end
    end

    private

    # rubocop:disable Metrics/MethodLength
    def create_issrefs
      # creates VACOLS::Issrefs added later than our sanitized UAT copy
      fiduciary_issue = {
        prog_code: "12",
        prog_desc: "Fiduciary"
      }

      # Issref_dump.csv has 1 Fiduciary issue
      return if VACOLS::Issref.where(**fiduciary_issue).count > 1

      FactoryBot.create(
        :issref,
        **fiduciary_issue,
        iss_code: "01",
        iss_desc: "Fiduciary Appointment"
      )
      FactoryBot.create(
        :issref,
        **fiduciary_issue,
        iss_code: "02",
        iss_desc: "Hub Manager removal of a fiduciary under 13.500"
      )
      FactoryBot.create(
        :issref,
        **fiduciary_issue,
        iss_code: "03",
        iss_desc: "Hub Manager misuse determination under 13.400"
      )
      FactoryBot.create(
        :issref,
        **fiduciary_issue,
        iss_code: "04",
        iss_desc: "RO Director decision upon recon of a misuse determ"
      )
      FactoryBot.create(
        :issref,
        **fiduciary_issue,
        iss_code: "05",
        iss_desc: "Dir of PFS negligence determination for reissuance"
      )
    end
    # rubocop:enable Metrics/MethodLength

    def bgs_record_from_case(cases, case_descriptors)
      CSV.open(Rails.root.join("local/vacols", "bgs_setup.csv"), "wb") do |csv|
        csv << %w[vbms_id bgs_key]
        cases.each_with_index do |c, i|
          csv << [c.bfcorlid, case_descriptors[i]["bgs_key"]]
        end
      end
    end

    def vbms_record_from_case(cases, case_descriptors)
      CSV.open(Rails.root.join("local/vacols", "vbms_setup.csv"), "wb") do |csv|
        csv << %w[vbms_id documents]
        cases.each_with_index do |c, i|
          csv << [c.bfcorlid, case_descriptors[i]["vbms_key"]]
        end
      end
    end

    def dateshift_field(items, date_shift, key)
      items.map! do |item|
        item[key] = item[key] + date_shift.seconds if item[key]
        item
      end
    end

    def truncate_string(items, sql_type, key)
      max_index = /\((\d*)\)/.match(sql_type)[1].to_i - 1
      items.map! do |item|
        item[key] = item[key][0..max_index] if item[key]
        item
      end
    end

    def read_csv(klass, date_shift = nil)
      items = []
      klass.delete_all
      CSV.foreach(Rails.root.join("local/vacols", klass.name + "_dump.csv"), headers: true) do |row|
        h = row.to_h
        items << klass.new(row.to_h) if klass.primary_key.nil? || !h[klass.primary_key].nil?
      end

      klass.columns_hash.each do |k, v|
        if date_shift && v.type == :date
          dateshift_field(items, date_shift, k)
        elsif v.type == :string
          truncate_string(items, v.sql_type, k)
        end
      end

      klass.import(items)
    end

    def write_csv(klass, rows, sanitizer)
      CSV.open(Rails.root.join("local/vacols", klass.name + "_dump.csv"), "wb") do |csv|
        names = klass.attribute_names
        csv << names
        rows.to_a.flatten.select { |e| e }.sort.each do |row|
          next if row.nil?

          sanitizer.sanitize(klass, row)
          attributes = row.attributes.select { |k, _v| names.include?(k) }
          csv << attributes.values
        end
      end
    end
  end
end
