require "csv"
require "rainbow"

namespace :local do
  namespace :vacols do
    desc "A rake task to be used in CI to ensure the DB is ready"
    task wait_for_connection: :environment do
      puts "Pinging FACOLS until it responds."

      # rubocop:disable Lint/HandleExceptions
      300.times do
        begin
          if VACOLS::Case.count == 0
            puts "FACOLS is ready."
            break
          end
        rescue StandardError
        end

        sleep 1
      end
      # rubocop:enable Lint/HandleExceptions
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
        schema_complete = false
        120.times do
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
          puts "Schema load failed"
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
      travel_board_date_shift = Time.now.utc.beginning_of_day - Time.utc(2018, 03, 20)
      
      read_csv(VACOLS::Case, date_shift)
      read_csv(VACOLS::Folder, date_shift)
      read_csv(VACOLS::Representative, date_shift)
      read_csv(VACOLS::Correspondent, date_shift)
      read_csv(VACOLS::CaseIssue, date_shift)
      read_csv(VACOLS::Note, date_shift)
      read_csv(VACOLS::CaseHearing, hearing_date_shift)
      read_csv(VACOLS::Decass, date_shift)
      read_csv(VACOLS::Staff, date_shift)
      read_csv(VACOLS::Vftypes, date_shift)
      read_csv(VACOLS::Issref, date_shift)
      read_csv(VACOLS::TravelBoardSchedule, date_shift)

      css_ids = VACOLS::Staff.where.not(sdomainid: nil).map do |s|
        User.find_or_create_by(
          css_id: s.sdomainid
        ) do |user|
          user.station_id = "101"
          user.full_name = "#{s.snamef} #{s.snamel}"
        end.css_id
      end
      Functions.grant!("System Admin", users: css_ids)
      setup_dispatch
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
        :representative,
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
      write_csv(VACOLS::Representative, cases.map(&:representative), sanitizer)
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

      # This must be run after the write_csv line for VACOLS::Case so that the VBMS ids get sanitized.
      vbms_record_from_case(cases, case_descriptors)
      bgs_record_from_case(cases, case_descriptors)
      sanitizer.errors.each do |error|
        puts Rainbow(error).red
      end
    end

    private

    def setup_dispatch
      CreateEstablishClaimTasksJob.perform_now
      Timecop.freeze(Date.yesterday) do
        # Tasks prepared on today's date will not be picked up
        Dispatch::Task.all.each(&:prepare!)
        # Appeal decisions (decision dates) for partial grants have to be within 3 days
        CSV.foreach(Rails.root.join("local/vacols", "cases.csv"), headers: true) do |row|
          row_hash = row.to_h
          if %w[amc_full_grants remands_ready_for_claims_establishment].include?(row_hash["vbms_key"])
            VACOLS::Case.where(bfkey: row_hash["vacols_id"]).first.update(bfddec: Time.zone.today)
          end
        end
      end
    rescue AASM::InvalidTransition
      Rails.logger.info("Taks prepare job skipped - tasks were already prepared...")
    end

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

    def dateshift_field(items, date_shift, k)
      items.map! do |item|
        item[k] = item[k] + date_shift.seconds if item[k]
        item
      end
    end

    def truncate_string(items, sql_type, k)
      max_index = /\((\d*)\)/.match(sql_type)[1].to_i - 1
      items.map! do |item|
        item[k] = item[k][0..max_index] if item[k]
        item
      end
    end

    def read_csv(klass, date_shift)
      items = []
      klass.delete_all
      CSV.foreach(Rails.root.join("local/vacols", klass.name + "_dump.csv"), headers: true) do |row|
        h = row.to_h
        items << klass.new(row.to_h) if klass.primary_key.nil? || !h[klass.primary_key].nil?
      end

      klass.columns_hash.each do |k, v|
        if v.type == :date
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
