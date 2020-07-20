# frozen_string_literal: true

describe RatingProfileDisability do
  let(:date) { DateTime.parse("2020/05/01") }

  let(:disability_hash) do
    {
      dis_sn: "dis_sn89",
      dis_dt: date - 6.days,
      disability_evaluations: [
        { # least recent
          dgnstc_tc: "dgnstc_tc71",
          prcnt_no: 20,
          conv_begin_dt: date - 9.days,
          begin_dt: date - 8.days,
          dis_dt: date - 1.day
        },
        { # no dt
          dgnstc_tc: "dgnstc_tc21",
          prcnt_no: 50
        },
        {
          dgnstc_tc: "dgnstc_tc91",
          prcnt_no: 65,
          conv_begin_dt: date - 3.days,
          begin_dt: date - 13.days,
          dis_dt: date - 14.days
        },
        { # most recent
          dgnstc_tc: "dgnstc_tc521",
          prcnt_no: 33,
          conv_begin_dt: date - 2.days,
          begin_dt: date - 9.days,
          dis_dt: date - 11.days
        }
      ]
    }
  end

  describe "#evaluations" do
    subject { described_class.new(disability_hash).evaluations }
    it("returns the evaluations array") { is_expected.to eq disability_hash[:disability_evaluations] }
  end

  describe "#most_recent_evaluation" do
    subject { described_class.new(disability_hash).most_recent_evaluation }
    it("returns the most recent evaluation") { is_expected.to eq disability_hash[:disability_evaluations][3] }
  end
end
