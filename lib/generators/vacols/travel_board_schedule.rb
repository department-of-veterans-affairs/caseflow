# frozen_string_literal: true

class Generators::Vacols::TravelBoardSchedule
  class << self
    # rubocop:disable Metrics/MethodLength
    def travel_board_sched_attrs
      {
        tbyear: "2017",
        tbtrip: 1,
        tbleg: 1,
        tbro: "RO17",
        tbstdate: "2017-01-30 00:00:00",
        tbenddate: "2017-02-03 00:00:00",
        tbmem1: "955",
        tbmem2: nil,
        tbmem3: nil,
        tbmem4: nil,
        tbaty1: nil,
        tbaty2: nil,
        tbaty3: nil,
        tbaty4: nil,
        tbadduser: "AABSHIRE",
        tbaddtime: "2016-09-21 00:00:00 UTC",
        tbmoduser: "SAABSHIRE",
        tbmodtime: "2016-09-21 00:00:00 UTC",
        tbbvapoc: nil,
        tbropoc: nil
      }
    end
    # rubocop:enable Metrics/MethodLength

    def create(attrs = [{}])
      if attrs.is_a?(Array)
        attrs = attrs.map { |hearing| travel_board_sched_attrs.merge!(hearing) }
        attrs.collect { |attr| VACOLS::TravelBoardSchedule.create!(attr) }
      else
        merged_attrs = travel_board_sched_attrs.merge(attrs)
        VACOLS::TravelBoardSchedule.create!(merged_attrs)
      end
    end
  end
end
