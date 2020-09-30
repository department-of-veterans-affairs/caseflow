# frozen_string_literal: true

# Promulgated ratings are returned from BGS's Rating service, and do not contain information about
# the rating profiles themselves. A second call to BGS's RatingProfile service is used to fetch that data.
# In comparison, Ratings at issue return both the rating and rating profile information from the RatingProfile service

describe PromulgatedRating do
  context ".fetch_timely" do
    let(:receipt_date) { Time.zone.today }

    subject { PromulgatedRating.fetch_timely(participant_id: "DRAYMOND", from_date: receipt_date) }

    let!(:rating) do
      Generators::PromulgatedRating.build(
        participant_id: "DRAYMOND",
        promulgation_date: receipt_date - 371.days
      )
    end

    let!(:untimely_rating) do
      Generators::PromulgatedRating.build(
        participant_id: "DRAYMOND",
        promulgation_date: receipt_date - 373.days
      )
    end

    it "returns rating objects for timely ratings" do
      expect(subject.count).to eq(1)
    end

    context "when multiple timely ratings exist" do
      let!(:another_rating) do
        Generators::PromulgatedRating.build(
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

    context "when BGS returns an error" do
      it "throws NilRatingProfileListError" do
        allow_any_instance_of(Fakes::BGSService).to receive(:fetch_ratings_in_range).and_return(error: "Oops")
        expect do
          PromulgatedRating.fetch_timely(participant_id: "DRAYMOND", from_date: receipt_date)
        end.to raise_error(Rating::NilRatingProfileListError)
      end
    end
  end

  context ".fetch_all" do
    let(:receipt_date) { Time.zone.today - 50.years }

    subject { PromulgatedRating.fetch_all("DRAYMOND") }

    let!(:rating) do
      Generators::PromulgatedRating.build(
        participant_id: "DRAYMOND",
        promulgation_date: receipt_date - 370.days
      )
    end

    let!(:untimely_rating) do
      Generators::PromulgatedRating.build(
        participant_id: "DRAYMOND",
        promulgation_date: receipt_date - 100.years
      )
    end

    it "returns rating objects for all ratings" do
      expect(subject.count).to eq(2)
    end

    context "on NoRatingsExistForVeteran error" do
      subject { PromulgatedRating.fetch_all("FOOBAR") }

      it "returns empty array" do
        expect(subject.count).to eq(0)
      end
    end
  end

  context ".from_bgs_hash" do
    subject { PromulgatedRating.from_bgs_hash(bgs_record) }

    let(:bgs_record) do
      {
        comp_id: {
          prfil_dt: Time.zone.today - 5.days,
          ptcpnt_vet_id: "ZAZA"
        },
        prmlgn_dt: Time.zone.today - 4.days
      }
    end

    it { is_expected.to be_a(PromulgatedRating) }

    it do
      is_expected.to have_attributes(
        participant_id: "ZAZA",
        profile_date: Time.zone.today - 5.days,
        promulgation_date: Time.zone.today - 4.days
      )
    end
  end
end
