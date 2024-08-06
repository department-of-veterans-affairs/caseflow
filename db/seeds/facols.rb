# frozen_string_literal: true

# FACOLS (Fake VACOLS) seeds.
# Called by rake task and as prereq for other Caseflow seeds.

require_relative "../../lib/helpers/vacols_csv_reader"

module Seeds
  class Facols < Base
    def seed!
      local_vacols_seed!
    end

    def local_vacols_seed!
      hearing_date_shift = Time.now.utc.beginning_of_day - Time.utc(2017, 12, 2)

      vacols_models.each do |model|
        if model == VACOLS::CaseHearing
          VacolsCSVReader.new(model, hearing_date_shift).call
        else
          VacolsCSVReader.new(model, date_shift).call
        end
      end

      create_issrefs
    end

    def local_vacols_staff!
      VacolsCSVReader.new(VACOLS::Staff, date_shift).call
    end

    private

    def date_shift
      @date_shift ||= Time.now.utc.beginning_of_day - Time.utc(2017, 12, 10)
    end

    def vacols_models
      [
        VACOLS::Case,
        VACOLS::Folder,
        VACOLS::Representative,
        VACOLS::Correspondent,
        VACOLS::CaseIssue,
        VACOLS::Note,
        VACOLS::CaseHearing,
        VACOLS::Actcode,
        VACOLS::Decass,
        VACOLS::Staff,
        VACOLS::Vftypes,
        VACOLS::Issref,
        VACOLS::TravelBoardSchedule
      ]
    end

    # rubocop:disable Metrics/MethodLength
    def create_issrefs
      # creates VACOLS::Issrefs added later than our sanitized UAT copy
      fiduciary_issue = {
        prog_code: "12",
        prog_desc: "Fiduciary"
      }

      # Issref_dump.csv has 1 Fiduciary issue
      return if VACOLS::Issref.where(**fiduciary_issue).count > 1

      create(
        :issref,
        **fiduciary_issue,
        iss_code: "01",
        iss_desc: "Fiduciary Appointment"
      )
      create(
        :issref,
        **fiduciary_issue,
        iss_code: "02",
        iss_desc: "Hub Manager removal of a fiduciary under 13.500"
      )
      create(
        :issref,
        **fiduciary_issue,
        iss_code: "03",
        iss_desc: "Hub Manager misuse determination under 13.400"
      )
      create(
        :issref,
        **fiduciary_issue,
        iss_code: "04",
        iss_desc: "RO Director decision upon recon of a misuse determ"
      )
      create(
        :issref,
        **fiduciary_issue,
        iss_code: "05",
        iss_desc: "Dir of PFS negligence determination for reissuance"
      )
    end
    # rubocop:enable Metrics/MethodLength
  end
end
