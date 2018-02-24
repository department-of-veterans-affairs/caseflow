require "csv"

namespace :local_vacols do
  desc "Starts and sets up a dockerized local VACOLS"
  task setup: :environment do
    Dir.chdir(Rails.root.join("vacols")) do
      puts "Removing existing volumes"
      `docker-compose down -v`
      puts "Starting database, and logging to #{Rails.root.join('tmp', 'vacols.log')}"
      `docker-compose up &> '../tmp/vacols.log' &`

      # Loop until setup is complete. At most 10 minutes
      puts "Waiting for the database to be ready"
      setup_complete = false
      600.times do
        if `grep -q 'Done ! The database is ready for use' ../tmp/vacols.log; echo $?` == "0\n"
          setup_complete = true
          break
        end
        sleep 1
      end

      if setup_complete
        puts "Updating schema"
        schema_complete = false
        120.times do
          output = `docker exec --tty -i VACOLS_DB bash -c \
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
  end

  desc "Starts up existing database"
  task start: :environment do
    Dir.chdir(Rails.root.join("vacols")) do
      `docker-compose up &> '../tmp/vacols.log' &`
    end
  end

  desc "Stops a running database"
  task stop: :environment do
    Dir.chdir(Rails.root.join("vacols")) do
      `docker-compose down`
    end
  end

  desc "Outputs logs from database"
  task logs: :environment do
    Dir.chdir(Rails.root.join("vacols")) do
      puts `cat '../tmp/vacols.log'`
    end
  end

  desc "Seeds local VACOLS"
  task seed: :environment do
    date_shift = Time.now.utc - Time.utc(2017, 11, 1)

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
    puts "Do not check in the result of running this without talking with Chris. We need to certify that there " \
      "is no PII in the results."

    case_descriptors = []
    CSV.foreach(Rails.root.join("vacols", "cases.csv"), headers: true) do |row|
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

    vbms_record_from_case(cases, case_descriptors)

    write_csv(VACOLS::Case, cases)
    write_csv(VACOLS::Folder, cases.map(&:folder))
    write_csv(VACOLS::Representative, cases.map(&:representative))
    write_csv(VACOLS::Correspondent, cases.map(&:correspondent))
    write_csv(VACOLS::CaseIssue, cases.map(&:case_issues))
    write_csv(VACOLS::Note, cases.map(& :notes))
    write_csv(VACOLS::CaseHearing, cases.map(&:case_hearings))
    write_csv(VACOLS::Decass, cases.map(&:decass))

    staff = VACOLS::Staff.all.map do |s|
      s[:sdomainid] = "READER" if s[:stafkey] == "ZZHU"
      s[:sdomainid] = "HEARING PREP" if s[:stafkey] == "PSORISIO"
      s
    end
    write_csv(VACOLS::Staff, staff)

    write_csv(VACOLS::Vftypes, VACOLS::Vftypes.all)
    write_csv(VACOLS::Issref, VACOLS::Issref.all)
    write_csv(VACOLS::TravelBoardSchedule, VACOLS::TravelBoardSchedule.where("tbyear > 2016"))
  end

  private

  def vbms_record_from_case(cases, case_descriptors)
    CSV.open(Rails.root.join("vacols", "vbms_setup.csv"), "wb") do |csv|
      csv << %w[vbms_id documents]
      cases.each_with_index do |c, i|
        csv << [c.bfcorlid, case_descriptors[i]["vbms_id"]]
      end
    end
  end

  def read_csv(klass, date_shift)
    items = []
    klass.delete_all
    CSV.foreach(Rails.root.join("vacols", klass.name + "_dump.csv"), headers: true) do |row|
      h = row.to_h
      items << klass.new(row.to_h) if klass.primary_key.nil? || !h[klass.primary_key].nil?
    end
    klass.columns_hash.each do |k, v|
      next if v.type != :datetime

      items.map! do |item|
        item[k] = item[k] + date_shift if item[k]
        item
      end
    end

    klass.import(items)
  end

  def write_csv(klass, rows)
    CSV.open(Rails.root.join("vacols", klass.name + "_dump.csv"), "wb") do |csv|
      names = klass.attribute_names
      csv << names
      rows.flatten.each do |row|
        next if row.nil?
        attributes = row.attributes.select { |k, _v| names.include?(k) }
        csv << attributes.values
      end
    end
  end
end
