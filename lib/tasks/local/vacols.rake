# frozen_string_literal: true

require "csv"
require "rainbow"
require_relative "../../helpers/vacols_csv_reader"
require_relative "../../../db/seeds/base"
require_relative "../../../db/seeds/facols"

namespace :local do
  namespace :vacols do
    desc "A rake task to be used in CI to ensure the DB is ready"
    task wait_for_connection: :environment do
      puts "Pinging FACOLS until it responds."

      facols_is_ready = false

      180.times do
        begin
          if VACOLS::Case.count == 0 &&
             VACOLS::CaseHearing.select("HEARING_VENUE(vdkey)").where(folder_nr: "1").count == 0
            puts "FACOLS is ready."
            facols_is_ready = true
            break
          end
        rescue StandardError => error
          puts error
          sleep 1
        end
      end

      unless facols_is_ready
        fail "Gave up waiting for FACOLS to get ready"
      end
    end

    desc "Seeds local VACOLS"
    task seed: :environment do
      Seeds::Facols.new.local_vacols_seed!
    end

    # Do not check in the result of running this without talking with Chris. We need to certify that there
    # is no PII in the results.
    desc "Dumps data from UAT VACOLS - must run with RAILS_ENV=ssh_forwarding"
    task dump_data: :environment do
      puts "Getting data from VACOLS, sanitizing it, and dumping it to local files."

      case_descriptors = []
      CSV.foreach(Rails.root.join("docker-bin/oracle_libs", "cases.csv"), headers: true) do |row|
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

    def bgs_record_from_case(cases, case_descriptors)
      CSV.open(Rails.root.join("docker-bin/oracle_libs", "bgs_setup.csv"), "wb") do |csv|
        csv << %w[vbms_id bgs_key]
        cases.each_with_index do |c, i|
          csv << [c.bfcorlid, case_descriptors[i]["bgs_key"]]
        end
      end
    end

    def vbms_record_from_case(cases, case_descriptors)
      CSV.open(Rails.root.join("docker-bin/oracle_libs", "vbms_setup.csv"), "wb") do |csv|
        csv << %w[vbms_id documents]
        cases.each_with_index do |c, i|
          csv << [c.bfcorlid, case_descriptors[i]["vbms_key"]]
        end
      end
    end

    def write_csv(klass, rows, sanitizer)
      CSV.open(Rails.root.join("docker-bin/oracle_libs", klass.name + "_dump.csv"), "wb") do |csv|
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
