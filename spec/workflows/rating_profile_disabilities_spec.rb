# frozen_string_literal: true

describe RatingProfileDisabilities do
  let(:date) { DateTime.parse("2020/05/01") }

  let(:disabilities) do
    [
      {
        dis_sn: "dis_sn433",
        dis_dt: date - 7.days,
        disability_evaluation: []
      },
      {
        dis_sn: "dis_sn88",
        dis_dt: date - 7.days,
        disability_evaluation: []
      },
      {
        dis_sn: "dis_sn88",
        dis_dt: date - 6.days,
        disability_evaluations: [
          { # least recent
            dgnstc_tc: "dgnstc_tc7",
            prcnt_no: 20,
            conv_begin_dt: date - 9.days,
            begin_dt: date - 8.days,
            dis_dt: date - 1.day
          },
          { # no dt
            dgnstc_tc: "dgnstc_tc2",
            prcnt_no: 50
          },
          {
            dgnstc_tc: "dgnstc_tc9",
            prcnt_no: 65,
            conv_begin_dt: date - 3.days,
            begin_dt: date - 13.days,
            dis_dt: date - 14.days
          },
          { # most recent (no dgnstc_tc or prcnt_no)
            conv_begin_dt: date - 1.day,
            begin_dt: date - 19.days,
            dis_dt: date - 20.days
          },
          { # most recent /with/ prcnt_no
            dgnstc_tc: "dgnstc_tc52",
            prcnt_no: 33,
            conv_begin_dt: date - 2.days,
            begin_dt: date - 9.days,
            dis_dt: date - 11.days
          }
        ]
      }
    ]
  end

  describe ".map_disabilities_by_dis_sn" do
    subject { described_class.map_disabilities_by_dis_sn(disabilities) }
    it("maps by dis_sn") do
      is_expected.to eq("dis_sn433" => disabilities[0..0], "dis_sn88" => disabilities[1..2])
    end
  end

  describe "#most_recent" do
    subject { described_class.new(disabilities).most_recent }
    it("returns the most recent disability hash for each dis_sn") do
      is_expected.to eq("dis_sn433" => disabilities[0], "dis_sn88" => disabilities[2])
    end
  end
end
