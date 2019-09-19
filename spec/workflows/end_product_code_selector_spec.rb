# frozen_string_literal: true

require "rails_helper"

EP_CODES = [
  ["030HLRNR", "primary", nil, "original", "compensation", "nonrating", "higher_level_review"],
  ["030HLRNRPMC", "primary", nil, "original", "pension", "nonrating", "higher_level_review"],
  ["030HLRR", "primary", nil, "original", "compensation", "rating", "higher_level_review"],
  ["030HLRRPMC", "primary", nil, "original", "pension", "rating", "higher_level_review"],
  ["040SCNR", "primary", nil, "original", "compensation", "nonrating", "supplemental_claim"],
  ["040SCNRPMC", "primary", nil, "original", "pension", "nonrating", "supplemental_claim"],
  ["040SCR", "primary", nil, "original", "compensation", "rating", "supplemental_claim"],
  ["040SCRPMC", "primary", nil, "original", "pension", "rating", "supplemental_claim"],
  ["930AHCNRLPMC", "930", "local_quality_error", "original", "pension", "nonrating", "higher_level_review"],
  ["930AHCNRLQE", "930", "local_quality_error", "original", "compensation", "nonrating", "higher_level_review"],
  ["930AHCNRNPMC", "930", "national_quality_error", "original", "pension", "nonrating", "higher_level_review"],
  ["930AHCNRNQE", "930", "national_quality_error", "original", "compensation", "nonrating", "higher_level_review"],
  ["930AHCRLQPMC", "930", "local_quality_error", "original", "pension", "rating", "higher_level_review"],
  ["930AHCRNQPMC", "930", "national_quality_error", "original", "pension", "rating", "higher_level_review"],
  ["930AHNRCPMC", "930", "control", "original", "pension", "nonrating", "higher_level_review"],
  ["930AMAHCRLQE", "930", "local_quality_error", "original", "compensation", "rating", "higher_level_review"],
  ["930AMAHCRNQE", "930", "national_quality_error", "original", "compensation", "rating", "higher_level_review"],
  ["930AMAHNRC", "930", "control", "original", "compensation", "nonrating", "higher_level_review"],
  ["930AMAHRC", "930", "control", "original", "compensation", "rating", "higher_level_review"],
  ["930AMAHRCPMC", "930", "control", "original", "pension", "rating", "higher_level_review"],
  ["930AMASCRLQE", "930", "local_quality_error", "original", "compensation", "rating", "supplemental_claim"],
  ["930AMASCRNQE", "930", "national_quality_error", "original", "compensation", "rating", "supplemental_claim"],
  ["930AMASNRC", "930", "control", "original", "compensation", "nonrating", "supplemental_claim"],
  ["930AMASRC", "930", "control", "original", "compensation", "rating", "supplemental_claim"],
  ["930AMASRCPMC", "930", "control", "original", "pension", "rating", "supplemental_claim"],
  ["930ASCNRLPMC", "930", "local_quality_error", "original", "pension", "nonrating", "supplemental_claim"],
  ["930ASCNRLQE", "930", "local_quality_error", "original", "compensation", "nonrating", "supplemental_claim"],
  ["930ASCNRNPMC", "930", "national_quality_error", "original", "pension", "nonrating", "supplemental_claim"],
  ["930ASCNRNQE", "930", "national_quality_error", "original", "compensation", "nonrating", "supplemental_claim"],
  ["930ASCRLQPMC", "930", "local_quality_error", "original", "pension", "rating", "supplemental_claim"],
  ["930ASCRNQPMC", "930", "national_quality_error", "original", "pension", "rating", "supplemental_claim"],
  ["930ASNRCPMC", "930", "control", "original", "pension", "nonrating", "supplemental_claim"],
  ["040BDENR", "primary", nil, "dta", "compensation", "nonrating", "appeal"],
  ["040BDENRPMC", "primary", nil, "dta", "pension", "nonrating", "appeal"],
  ["040BDER", "primary", nil, "dta", "compensation", "rating", "appeal"],
  ["040BDERPMC", "primary", nil, "dta", "pension", "rating", "appeal"],
  ["040HDENR", "primary", nil, "dta", "compensation", "nonrating", "higher_level_review"],
  ["040HDENRPMC", "primary", nil, "dta", "pension", "nonrating", "higher_level_review"],
  ["040HDER", "primary", nil, "dta", "compensation", "rating", "higher_level_review"],
  ["040HDERPMC", "primary", nil, "dta", "pension", "rating", "higher_level_review"],
  ["930AMAHDENCL", "930", "local_quality_error", "dta", "compensation", "nonrating", "higher_level_review"],
  ["930AMAHDENCN", "930", "national_quality_error", "dta", "compensation", "nonrating", "higher_level_review"],
  ["930AMAHDENR", "930", "control", "dta", "compensation", "nonrating", "higher_level_review"],
  ["930AMAHDER", "930", "control", "dta", "compensation", "rating", "higher_level_review"],
  ["930AMAHDERCL", "930", "local_quality_error", "dta", "compensation", "rating", "higher_level_review"],
  ["930AMAHDERCN", "930", "national_quality_error", "dta", "compensation", "rating", "higher_level_review"],
  ["930AMARNRC", "930", "control", "dta", "compensation", "nonrating", "appeal"],
  ["930AMARRC", "930", "control", "dta", "compensation", "rating", "appeal"],
  ["930AMARRCLQE", "930", "local_quality_error", "dta", "compensation", "rating", "appeal"],
  ["930AMARRCNQE", "930", "national_quality_error", "dta", "compensation", "rating", "appeal"],
  ["930AMARRCPMC", "930", "control", "dta", "pension", "rating", "appeal"],
  ["930ARNRCLPMC", "930", "local_quality_error", "dta", "pension", "nonrating", "appeal"],
  ["930ARNRCLQE", "930", "local_quality_error", "dta", "compensation", "nonrating", "appeal"],
  ["930ARNRCNPMC", "930", "national_quality_error", "dta", "pension", "nonrating", "appeal"],
  ["930ARNRCNQE", "930", "national_quality_error", "dta", "compensation", "nonrating", "appeal"],
  ["930ARNRCPMC", "930", "control", "dta", "pension", "nonrating", "appeal"],
  ["930ARRCLQPMC", "930", "local_quality_error", "dta", "pension", "rating", "appeal"],
  ["930ARRCNQPMC", "930", "national_quality_error", "dta", "pension", "rating", "appeal"]
].freeze

describe "Request Issue Correction Cleaner" do
  let(:higher_level_review) { create(:higher_level_review, benefit_type: benefit_type) }
  let(:supplemental_claim) { create(:supplemental_claim, benefit_type: benefit_type, decision_review_remanded: drr) }
  let(:appeal) { create(:appeal) }
  let(:benefit_type) { nil }
  let(:correction_type) { nil }
  let(:decision_review) { nil }
  let(:drr) { nil }
  let(:contested_rating_issue_reference_id) { nil }
  let(:nonrating_issue_category) { nil }
  let(:is_unidentified) { nil }
  let(:request_issue) do
    create(:request_issue,
      nonrating_issue_category: nonrating_issue_category,
      contested_rating_issue_reference_id: contested_rating_issue_reference_id,
      decision_review: decision_review,
      benefit_type: benefit_type,
      correction_type: correction_type,
      is_unidentified: is_unidentified
    )
  end

  context "#call" do
    subject { EndProductCodeSelector.new(request_issue).call }

    context "for an unidentified issue" do
      let(:is_unidentified) { TRUE }
      let(:decision_review) { higher_level_review }
      let(:benefit_type) { "compensation" }

      it "returns a rating EP code" do
        expect(subject).to eq("030HLRR")
      end
    end

    EP_CODES.each do |ep_code|
      context "given attributes for EP code #{ep_code}" do
        subject { EndProductCodeSelector.new(request_issue).call }

        if ep_code[1] == "930"
          let(:correction_type) { ep_code[2]}
        end

        if ep_code[3] == "dta"
          let(:decision_review) { supplemental_claim }
          let(:drr) { send(ep_code[6]) }
        else
          let(:decision_review) { send(ep_code[6]) }
        end

        let(:benefit_type) { ep_code[4] }

        if ep_code[5] == "rating"
          let(:contested_rating_issue_reference_id) { "1" }
        else
          let(:nonrating_issue_category) { "Apportionment" }
        end

        it "correctly returns EP code" do
          expect(subject).to eq(ep_code[0])
        end
      end
    end
  end
end
