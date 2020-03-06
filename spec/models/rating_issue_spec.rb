# frozen_string_literal: true

describe RatingIssue do
  before do
    Time.zone = "UTC"
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:profile_date) { Time.zone.today - 30 }
  let(:promulgation_date) { Time.zone.today - 30 }

  context ".deserialize" do
    subject { RatingIssue.deserialize(rating_issue.serialize) }

    let(:rating_issue) do
      RatingIssue.new(
        reference_id: "NBA",
        participant_id: "123",
        profile_date: profile_date,
        promulgation_date: promulgation_date,
        decision_text: "This broadcast may not be reproduced",
        diagnostic_code: "1234",
        associated_end_products: [],
        rba_contentions_data: [{}]
      )
    end

    it { is_expected.to be_a(RatingIssue) }

    it do
      is_expected.to have_attributes(
        reference_id: "NBA",
        participant_id: "123",
        profile_date: profile_date,
        promulgation_date: promulgation_date,
        decision_text: "This broadcast may not be reproduced",
        diagnostic_code: "1234",
        rba_contentions_data: [{}]
      )
    end
  end

  context ".from_bgs_hash" do
    subject { RatingIssue.from_bgs_hash(rating, bgs_record) }

    let(:associated_claims) do
      [
        { clm_id: "abc123", bnft_clm_tc: "040SCR" },
        { clm_id: "dcf345", bnft_clm_tc: "154IVMC9PMC" }
      ]
    end

    let!(:rating) do
      Generators::Rating.build(
        participant_id: "123",
        promulgation_date: promulgation_date,
        profile_date: profile_date,
        associated_claims: associated_claims
      )
    end

    let(:bgs_record) do
      {
        rba_issue_id: "NBA",
        decn_txt: "This broadcast may not be reproduced",
        dgnstc_tc: "3001"
      }
    end

    it { is_expected.to be_a(RatingIssue) }

    it do
      is_expected.to have_attributes(
        reference_id: "NBA",
        decision_text: "This broadcast may not be reproduced",
        profile_date: profile_date,
        contention_reference_ids: [],
        diagnostic_code: "3001",
        benefit_type: :pension
      )
    end

    context "when rba_issue_contentions is single" do
      let(:bgs_record) do
        {
          rba_issue_id: "NBA",
          decn_txt: "This broadcast may not be reproduced",
          rba_issue_contentions: { prfil_dt: Time.zone.now, cntntn_id: "foul" }
        }
      end

      it do
        is_expected.to have_attributes(
          reference_id: "NBA",
          decision_text: "This broadcast may not be reproduced",
          profile_date: profile_date,
          contention_reference_ids: ["foul"],
          benefit_type: :pension
        )
      end
    end

    context "when rba_issue_contentions is an array" do
      let(:bgs_record) do
        {
          rba_issue_id: "NBA",
          decn_txt: "This broadcast may not be reproduced",
          rba_issue_contentions: [
            { prfil_dt: Time.zone.now, cntntn_id: "foul" },
            { prfil_dt: Time.zone.now, cntntn_id: "dunk" }
          ]
        }
      end

      it do
        is_expected.to have_attributes(
          reference_id: "NBA",
          decision_text: "This broadcast may not be reproduced",
          profile_date: profile_date,
          contention_reference_ids: %w[foul dunk]
        )
      end
    end
  end
end
