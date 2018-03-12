require "csv"

namespace :local do
  namespace :vacols do
    desc "Starts and sets up a dockerized local VACOLS"
    task setup: :environment do
      puts "Updating schema"
      schema_complete = false
      120.times do
        output = `docker exec --tty -i VACOLS_DB bash -c \
        "source /home/oracle/.bashrc; sqlplus /nolog @/ORCL/setup_vacols.sql"`
        if output.empty?
          # the docker container is likely not running
          break
        elsif !output.include?("SP2-0640: Not connected")
          schema_complete = true
          break
        end
        sleep 1
      end

      if schema_complete
        puts "Schema loaded"
      else
        puts "Schema loading failed.  Please make sure your VACOLS container is running. Try running:\n\n$ docker-compose ps\n$ docker-compose up -d"
      end
    end

    desc "Seeds local VACOLS"
    task seed: :environment do
      date_shift = Time.now.utc.beginning_of_day - Time.utc(2017, 11, 1)

      read_csv(VACOLS::Case, date_shift)
      read_csv(VACOLS::Folder, date_shift)
      read_csv(VACOLS::Representative, date_shift)
      read_csv(VACOLS::Correspondent, date_shift)
      read_csv(VACOLS::CaseIssue, date_shift)
      read_csv(VACOLS::Note, date_shift)
      read_csv(VACOLS::CaseHearing, date_shift)
      read_csv(VACOLS::Decass, date_shift)
      read_csv(VACOLS::Staff, date_shift)
      read_csv(VACOLS::Vftypes, date_shift)
      read_csv(VACOLS::Issref, date_shift)
      read_csv(VACOLS::TravelBoardSchedule, date_shift)
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

      # In order to add a new table, you'll also need to add a sanitize and white_list method
      # to the Helpers::Sanitizers class.
      write_csv(VACOLS::Case, cases)
      write_csv(VACOLS::Folder, cases.map(&:folder))
      write_csv(VACOLS::Representative, cases.map(&:representative))
      write_csv(VACOLS::Correspondent, cases.map(&:correspondent))
      write_csv(VACOLS::CaseIssue, cases.map(&:case_issues))
      write_csv(VACOLS::Note, cases.map(&:notes))
      write_csv(VACOLS::CaseHearing, cases.map(&:case_hearings))
      write_csv(VACOLS::Decass, cases.map(&:decass))
      write_csv(VACOLS::Staff, VACOLS::Staff.all)
      write_csv(VACOLS::Vftypes, VACOLS::Vftypes.all)
      write_csv(VACOLS::Issref, VACOLS::Issref.all)
      write_csv(
        VACOLS::TravelBoardSchedule,
        VACOLS::TravelBoardSchedule.where("tbyear > 2016")
      )

      # This must be run after the write_csv line for VACOLS::Case so that the VBMS ids get sanitized.
      vbms_record_from_case(cases, case_descriptors)
    end

    private

    def vbms_record_from_case(cases, case_descriptors)
      CSV.open(Rails.root.join("local/vacols", "vbms_setup.csv"), "wb") do |csv|
        csv << %w[vbms_id documents]
        cases.each_with_index do |c, i|
          csv << [c.bfcorlid, case_descriptors[i]["vbms_id"]]
        end
      end
    end

    def dateshift_field(items, date_shift, k)
      items.map! do |item|
        item[k] = item[k] + date_shift if item[k]
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
        if v.type == :datetime
          dateshift_field(items, date_shift, k)
        elsif v.type == :string
          truncate_string(items, v.sql_type, k)
        end
      end

      klass.import(items)
    end

    def write_csv(klass, rows)
      CSV.open(Rails.root.join("local/vacols", klass.name + "_dump.csv"), "wb") do |csv|
        names = klass.attribute_names
        csv << names
        rows.flatten.each do |row|
          next if row.nil?
          Helpers::Sanitizers.sanitize(klass, row)
          attributes = row.attributes.select { |k, _v| names.include?(k) }
          csv << attributes.values
        end
      end
    end
  end
end
