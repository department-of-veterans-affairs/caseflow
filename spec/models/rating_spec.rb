require "rails_helper"

describe Rating do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:rating) do
    Generators::Rating.build(
      issues: issues
    )
  end

  let(:issues) do
    [
      { rba_issue_id: "Issue1", decision_text: "Decision1" },
      { rba_issue_id: "Issue2", decision_text: "Decision2" }
    ]
  end

  context "#issues" do
    subject { rating.issues }

    it "returns the issues" do
      expect(subject.count).to eq(2)
      expect(subject.first).to have_attributes(
        rba_issue_id: "Issue1", decision_text: "Decision1"
      )
      expect(subject.second).to have_attributes(
        rba_issue_id: "Issue2", decision_text: "Decision2"
      )
    end
  end

  context "#ui_hash" do
    subject { rating.ui_hash }

    it do
      is_expected.to match(
        participant_id: rating.participant_id,
        profile_date: rating.profile_date,
        promulgation_date: rating.promulgation_date,
        issues: issues
      )
    end
  end

  context ".from_bgs_hash" do
    subject { Rating.from_bgs_hash(bgs_record) }

    let(:bgs_record) do
      {
        comp_id: {
          prfil_dt: Time.zone.today - 5.days,
          ptcpnt_vet_id: "ZAZA"
        },
        prmlgn_dt: Time.zone.today - 4.days
      }
    end

    it { is_expected.to be_a(Rating) }

    it do
      is_expected.to have_attributes(
        participant_id: "ZAZA",
        profile_date: Time.zone.today - 5.days,
        promulgation_date: Time.zone.today - 4.days
      )
    end
  end

  context ".fetch_timely" do
    subject { Rating.fetch_timely(participant_id: "DRAYMOND") }

    let!(:rating) do
      Generators::Rating.build(
        participant_id: "DRAYMOND",
        promulgation_date: Time.zone.today - 371.days,
        profile_date: Time.zone.today - 370.days
      )
    end

    let!(:untimely_rating) do
      Generators::Rating.build(
        participant_id: "DRAYMOND",
        promulgation_date: Time.zone.today - 373.days,
        profile_date: Time.zone.today - 373.days
      )
    end

    let!(:untimely_rating_in_service_range) do
      Generators::Rating.build(
        promulgation_date: Time.zone.today - 373.days,
        profile_date: Time.zone.today - 371.days
      )
    end

    it "returns rating objects for all timely ratings" do
      expect(subject.count).to eq(1)

      expect(subject.first).to have_attributes(
        participant_id: "DRAYMOND",
        promulgation_date: Time.zone.today - 371.days,
        profile_date: Time.zone.today - 370.days
      )
    end

    context "when multiple timely ratings exist" do
      let!(:another_rating) do
        Generators::Rating.build(
          participant_id: "DRAYMOND",
          promulgation_date: Time.zone.today - 300.days,
          profile_date: Time.zone.today - 300.days
        )
      end

      it "returns rating objects for all timely ratings" do
        expect(subject.count).to eq(2)
      end
    end
  end
end
