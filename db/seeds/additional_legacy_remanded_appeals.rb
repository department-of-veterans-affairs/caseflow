# frozen_string_literal: true

module Seeds
  class AdditionalLegacyRemandedAppeals < Base


    def initialize
      @legacy_appeals = []
      initial_file_number_and_participant_id
    end

    def seed!

      create_legacy_appeals_decision_ready_hr
    end

    private

    def initial_file_number_and_participant_id
      @file_number ||= 100_000_000
      @participant_id ||= 500_000_000
      # n is (@file_number + 1) because @file_number is incremented before using it in factories in calling methods
      while Veteran.find_by(file_number: format("%<n>09d", n: @file_number + 1))
        @file_number += 2000
        @participant_id += 2000
      end
    end

    def create_veteran(options = {})
      @file_number += 1
      @participant_id += 1
      params = {
        file_number: format("%<n>09d", n: @file_number),
        participant_id: format("%<n>09d", n: @participant_id)
      }
      create(:veteran, params.merge(options))
    end


    def legacy_decision_reason_remand_list
      [
        "AA",
        "AB",
        "AC",
        "BA",
        "BB",
        "BC",
        "BD",
        "BE",
        "BF",
        "BG",
        "BH",
        "BI",
        "DA",
        "DB",
        "DI",
        "DD",
        "DE",
        "EA",
        "EB",
        "EC",
        "ED",
        "EE",
        "EG",
        "EH",
        "EI",
        "EK",
      ]
    end

    def create_legacy_appeals_decision_ready_hr
      judge = User.find_by_css_id("BVAAABSHIRE")
      attorney = User.find_by_css_id("BVASCASPER1")
      Timecop.travel(57.days.ago)

        3.times do
          la = LegacyAppeal.new()
          created_at = la.vacols_case_review&.created_at

          next unless la.location_code == judge.vacols_uniq_id && created_at.present?

          task_id = "#{la.vacols_id}-#{VacolsHelper.day_only_str(created_at)}"

          create(
            :attorney_case_review,
            appeal: la,
            reviewing_judge: judge,
            attorney: attorney,
            task_id: task_id,
            note: Faker::Lorem.sentence
          )
         end
        end
      Timecop.return
    end
  end
