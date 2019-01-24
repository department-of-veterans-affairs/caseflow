require "rails_helper"

describe Rating do
  before do
    Time.zone = "UTC"
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:participant_id) { 1234 }

  let(:receipt_date) { Time.zone.today }

  let(:promulgation_date) { receipt_date - 30 }
  let(:profile_date) { receipt_date - 40 }
  let(:associated_claims) { [] }

  let(:rating) do
    Generators::Rating.build(
      issues: issues,
      promulgation_date: promulgation_date,
      profile_date: profile_date,
      participant_id: participant_id,
      associated_claims: associated_claims
    )
  end

  def build_issue(num)
    {
      participant_id: participant_id,
      reference_id: "Issue#{num}",
      decision_text: "Decision#{num}",
      promulgation_date: promulgation_date,
      profile_date: profile_date,
      contention_reference_id: nil,
      ramp_claim_id: nil,
      title_of_active_review: nil,
      rba_contentions_data: [{ prfil_dt: profile_date, cntntn_id: nil }]
    }
  end

  let(:issues) do
    [build_issue(1), build_issue(2)]
  end

  context "with disabilities" do
    let(:participant_id) { "disability_id" }
    let(:rating) do
      Generators::Rating.build(
        promulgation_date: promulgation_date,
        profile_date: profile_date,
        participant_id: participant_id,
        associated_claims: associated_claims,
        issues: [
          {
            reference_id: "Issue1",
            decision_text: "Decision1",
            dis_sn: "rating1"
          },
          {
            reference_id: "Issue2",
            decision_text: "Decision2"
          }
        ],
        disabilities: disabilities
      )
    end
    subject { rating.issues }

    context "with multiple disabilities" do
      let(:disabilities) do
        [{
          dis_dt: promulgation_date - 2.days,
          dis_sn: "rating1",
          disability_evaluations: {
            dis_dt: promulgation_date - 2.days,
            dgnstc_tc: "original_code"
          }
        },
         {
           dis_dt: promulgation_date - 1.day,
           dis_sn: "rating1",
           disability_evaluations: {
             dis_dt: promulgation_date - 2.days,
             dgnstc_tc: "later_code"
           }
         }]
      end

      it "overrides disability with earlier date" do
        expect(subject.count).to eq(2)

        expect(subject.first).to have_attributes(
          reference_id: "Issue1", decision_text: "Decision1", disability_code: "later_code"
        )

        expect(subject.second).to have_attributes(
          reference_id: "Issue2", decision_text: "Decision2", disability_code: nil
        )
      end
    end

    context "with one disability" do
      let(:disabilities) do
        {
          dis_dt: promulgation_date - 2.days,
          dis_sn: "rating1",
          disability_evaluations: {
            dis_dt: promulgation_date - 2.days,
            dgnstc_tc: "original_code"
          }
        }
      end

      it "returns issues with ratings" do
        expect(subject.count).to eq(2)

        expect(subject.first).to have_attributes(
          reference_id: "Issue1", decision_text: "Decision1", disability_code: "original_code"
        )

        expect(subject.second).to have_attributes(
          reference_id: "Issue2", decision_text: "Decision2", disability_code: nil
        )
      end
    end

    context "with multiple evaluations" do
      let(:disabilities) do
        {
          dis_dt: promulgation_date - 2.days,
          dis_sn: "rating1",
          disability_evaluations: [{
            dis_dt: promulgation_date - 3.days,
            dgnstc_tc: "original_code"
          }, {
            dis_dt: promulgation_date - 2.days,
            dgnstc_tc: "later_code"
          }]
        }
      end

      it "overrides evaluation with earlier date" do
        expect(subject.count).to eq(2)

        expect(subject.first).to have_attributes(
          reference_id: "Issue1", decision_text: "Decision1", disability_code: "later_code"
        )

        expect(subject.second).to have_attributes(
          reference_id: "Issue2", decision_text: "Decision2", disability_code: nil
        )
      end
    end

    context "with no evaluation" do
      let(:disabilities) do
        {
          dis_dt: promulgation_date - 2.days,
          dis_sn: "rating1"
        }
      end

      it "creates ratings without disability codes" do
        expect(subject.count).to eq(2)
        expect(subject.first).to have_attributes(
          reference_id: "Issue1", decision_text: "Decision1", disability_code: nil
        )

        expect(subject.second).to have_attributes(
          reference_id: "Issue2", decision_text: "Decision2", disability_code: nil
        )
      end
    end
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

  context "#associated_end_products" do
    subject { rating.associated_end_products }

    context "when mutliple associated eps exist" do
      let(:associated_claims) do
        [
          { clm_id: "abc123", bnft_clm_tc: "040SCR" },
          { clm_id: "dcf345", bnft_clm_tc: "030HLRNR" }
        ]
      end
      it do
        expect(subject.first).to have_attributes(claim_id: "abc123", claim_type_code: "040SCR")
        expect(subject.last).to have_attributes(claim_id: "dcf345", claim_type_code: "030HLRNR")
        expect(subject.count).to eq(2)
      end
    end

    context "when one ep exists" do
      let(:associated_claims) do
        [
          { clm_id: "qwe123", bnft_clm_tc: "030HLRR" }
        ]
      end
      it do
        expect(subject.first).to have_attributes(claim_id: "qwe123", claim_type_code: "030HLRR")
        expect(subject.count).to eq(1)
      end
    end

    context "when no eps exist" do
      let(:associated_claims) { nil }
      it do
        is_expected.to be_empty
      end
    end
  end

  context "#serialize" do
    subject { rating.serialize }

    it do
      is_expected.to match(
        participant_id: rating.participant_id,
        profile_date: rating.profile_date,
        promulgation_date: rating.promulgation_date,
        issues: rating.issues.map(&:serialize)
      )
    end

    context "when rating issues is nil" do
      let(:issues) { nil }

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
