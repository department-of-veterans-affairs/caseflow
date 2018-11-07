require "rails_helper"

describe Rating do
  before do
    Time.zone = "UTC"
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:participant_id) { 1234 }

  let(:receipt_date) { Time.zone.today }

  let(:promulgation_date) { receipt_date - 30 }

  let(:rating) do
    Generators::Rating.build(
      issues: issues,
      promulgation_date: promulgation_date,
      participant_id: participant_id
    )
  end

  def build_issue(num)
    {
      participant_id: participant_id,
      reference_id: "Issue#{num}",
      decision_text: "Decision#{num}",
      promulgation_date: promulgation_date,
      contention_reference_id: nil,
      title_of_active_review: nil,
      source_higher_level_review: nil
    }
  end

  let(:issues) do
    [build_issue(1), build_issue(2)]
  end

  context "#issues" do
    subject { rating.issues }

    it "returns the issues" do
      expect(subject.count).to eq(2)
      expect(subject.first).to have_attributes(
        reference_id: "Issue1", decision_text: "Decision1"
      )
      expect(subject.second).to have_attributes(
        reference_id: "Issue2", decision_text: "Decision2"
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
        issues: issues.each { |issue| issue[:profile_date] = rating.profile_date }
      )
    end

    context "when rating issues is nil" do
      let(:issues) { :no_issues }

      it "should have no issues" do
        is_expected.to match(
          participant_id: rating.participant_id,
          profile_date: rating.profile_date,
          promulgation_date: rating.promulgation_date,
          issues: []
        )
      end
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
    let(:receipt_date) { Time.zone.today }

    subject { Rating.fetch_timely(participant_id: "DRAYMOND", from_date: receipt_date) }

    let!(:rating) do
      Generators::Rating.build(
        participant_id: "DRAYMOND",
        promulgation_date: receipt_date - 371.days
      )
    end

    let!(:untimely_rating) do
      Generators::Rating.build(
        participant_id: "DRAYMOND",
        promulgation_date: receipt_date - 373.days
      )
    end

    it "returns rating objects for timely ratings" do
      expect(subject.count).to eq(1)
    end

    context "when multiple timely ratings exist" do
      let!(:another_rating) do
        Generators::Rating.build(
          participant_id: "DRAYMOND",
          promulgation_date: receipt_date - 370.days
        )
      end

      it "returns rating objects sorted desc by promulgation_date for all timely ratings" do
        expect(subject.count).to eq(2)

        expect(subject.first).to have_attributes(
          participant_id: "DRAYMOND",
          promulgation_date: receipt_date - 370.days
        )

        expect(subject.last).to have_attributes(
          participant_id: "DRAYMOND",
          promulgation_date: receipt_date - 371.days
        )
      end
    end

    context "when a rating is locked" do
      it "throws NilRatingProfileListError" do
        allow_any_instance_of(Fakes::BGSService).to receive(:fetch_ratings_in_range).and_return(error: "Oops")
        expect do
          Rating.fetch_timely(participant_id: "DRAYMOND", from_date: receipt_date)
        end.to raise_error(Rating::NilRatingProfileListError)
      end
    end
  end

  context ".fetch_all" do
    let(:receipt_date) { Time.zone.today - 50.years }

    subject { Rating.fetch_all("DRAYMOND") }

    let!(:rating) do
      Generators::Rating.build(
        participant_id: "DRAYMOND",
        promulgation_date: receipt_date - 370.days
      )
    end

    let!(:untimely_rating) do
      Generators::Rating.build(
        participant_id: "DRAYMOND",
        promulgation_date: receipt_date - 100.years
      )
    end

    it "returns rating objects for all ratings" do
      expect(subject.count).to eq(2)
    end
  end
end
