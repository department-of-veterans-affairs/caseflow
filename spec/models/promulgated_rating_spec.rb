# frozen_string_literal: true

# Promulgated ratings are returned from BGS's Rating service, and do not contain information about
# the rating profiles themselves. A second call to BGS's RatingProfile service is used to fetch that data.
# In comparison, Ratings at issue return both the rating and rating profile information from the RatingProfile service

describe PromulgatedRating do
  let(:receipt_date) { Time.zone.today }
  let!(:rating) do
    Generators::PromulgatedRating.build(
      participant_id: "DRAYMOND",
      promulgation_date: receipt_date - 370.days,
      profile_date: receipt_date - 370.days
    )
  end

  context ".fetch_timely" do
    subject { PromulgatedRating.fetch_timely(participant_id: "DRAYMOND", from_date: receipt_date) }

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
          promulgation_date: receipt_date - 371.days
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

  context "#rating_profile" do
    let(:bgs) { Fakes::BGSService.new }

    before do
      allow(Fakes::BGSService).to receive(:new).and_return(bgs)
    end

    subject { rating.rating_profile }

    context "BGS throws a Share Error on fetch_rating_profile" do
      before do
        allow(bgs).to receive(:fetch_rating_profile)
          .and_raise(BGS::ShareError, "Veteran does not meet the minimum disability requirements")
      end

      context "BGS returns a successful response on fetch_rating_profiles_in_range" do
        before do
          allow(bgs).to receive(:fetch_rating_profiles_in_range).and_call_original
        end

        it "Fetches the rating profile using RatingAtIssue" do
          expect(subject.present?)
          expect { rating.issues }.to_not raise_error
          expect(bgs).to have_received(:fetch_rating_profiles_in_range)
        end
      end

      context "an error is raised on fetch_rating_profiles_in_range" do
        let(:error) { nil }
        let(:message) { "" }

        before do
          allow(bgs).to receive(:fetch_rating_profiles_in_range)
            .and_raise(error, message)
        end

        context "a share error is raised on fetch_rating_profiles_in_range" do
          let(:error) { BGS::ShareError }
          let(:message) { "Veteran does not meet the minimum disability requirements" }

          it "captures the exception and returns an empty object" do
            expect(Raven).to receive(:capture_exception).with error
            expect(subject).to eq({})
          end
        end

        context "a nil rating profile list error is raised on fetch_rating_profiles_in_range" do
          let(:error) { Rating::NilRatingProfileListError }

          it "captures the exception returns an empty object" do
            expect(Raven).to receive(:capture_exception).with error
            expect(subject).to eq({})
          end
        end
      end
    end
  end
end
