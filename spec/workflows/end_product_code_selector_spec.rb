# frozen_string_literal: true

# The EP code table below contains the combination of issue characteristics for each code

# Description of fields, as they are indexed in the array
# 0. EP code
# 1. primary vs. 930 correction
# 2. correction type (set to na if the EP is not for a 930 correction)
# 3. dta vs. original
# 4. benefit type
# 5. issue type
# 6. decision review type

EP_CODES = [
  %w[030HLRNR primary na original compensation nonrating higher_level_review],
  %w[030HLRNRPMC primary na original pension nonrating higher_level_review],
  %w[030HLRR primary na original compensation rating higher_level_review],
  %w[030HLRRPMC primary na original pension rating higher_level_review],
  %w[040SCNR primary na original compensation nonrating supplemental_claim],
  %w[040SCNRPMC primary na original pension nonrating supplemental_claim],
  %w[040SCR primary na original compensation rating supplemental_claim],
  %w[040SCRPMC primary na original pension rating supplemental_claim],
  %w[930AHCNRLPMC 930 local_quality_error original pension nonrating higher_level_review],
  %w[930AHCNRLQE 930 local_quality_error original compensation nonrating higher_level_review],
  %w[930AHCNRNPMC 930 national_quality_error original pension nonrating higher_level_review],
  %w[930AHCNRNQE 930 national_quality_error original compensation nonrating higher_level_review],
  %w[930AHCRLQPMC 930 local_quality_error original pension rating higher_level_review],
  %w[930AHCRNQPMC 930 national_quality_error original pension rating higher_level_review],
  %w[930AHNRCPMC 930 control original pension nonrating higher_level_review],
  %w[930AMAHCRLQE 930 local_quality_error original compensation rating higher_level_review],
  %w[930AMAHCRNQE 930 national_quality_error original compensation rating higher_level_review],
  %w[930AMAHNRC 930 control original compensation nonrating higher_level_review],
  %w[930AMAHRC 930 control original compensation rating higher_level_review],
  %w[930AMAHRCPMC 930 control original pension rating higher_level_review],
  %w[930AMASCRLQE 930 local_quality_error original compensation rating supplemental_claim],
  %w[930AMASCRNQE 930 national_quality_error original compensation rating supplemental_claim],
  %w[930AMASNRC 930 control original compensation nonrating supplemental_claim],
  %w[930AMASRC 930 control original compensation rating supplemental_claim],
  %w[930AMASRCPMC 930 control original pension rating supplemental_claim],
  %w[930ASCNRLPMC 930 local_quality_error original pension nonrating supplemental_claim],
  %w[930ASCNRLQE 930 local_quality_error original compensation nonrating supplemental_claim],
  %w[930ASCNRNPMC 930 national_quality_error original pension nonrating supplemental_claim],
  %w[930ASCNRNQE 930 national_quality_error original compensation nonrating supplemental_claim],
  %w[930ASCRLQPMC 930 local_quality_error original pension rating supplemental_claim],
  %w[930ASCRNQPMC 930 national_quality_error original pension rating supplemental_claim],
  %w[930ASNRCPMC 930 control original pension nonrating supplemental_claim],
  %w[040BDENR primary na dta compensation nonrating appeal],
  %w[040BDENRPMC primary na dta pension nonrating appeal],
  %w[040BDER primary na dta compensation rating appeal],
  %w[040BDERPMC primary na dta pension rating appeal],
  %w[040HDENR primary na dta compensation nonrating higher_level_review],
  %w[040HDENRPMC primary na dta pension nonrating higher_level_review],
  %w[040HDER primary na dta compensation rating higher_level_review],
  %w[040HDERPMC primary na dta pension rating higher_level_review],
  %w[930AMAHDENCL 930 local_quality_error dta compensation nonrating higher_level_review],
  %w[930AMAHDENCN 930 national_quality_error dta compensation nonrating higher_level_review],
  %w[930AMAHDENR 930 control dta compensation nonrating higher_level_review],
  %w[930AMAHDER 930 control dta compensation rating higher_level_review],
  %w[930AMAHDERCL 930 local_quality_error dta compensation rating higher_level_review],
  %w[930AMAHDERCN 930 national_quality_error dta compensation rating higher_level_review],
  %w[930AMARNRC 930 control dta compensation nonrating appeal],
  %w[930AMARRC 930 control dta compensation rating appeal],
  %w[930AMARRCLQE 930 local_quality_error dta compensation rating appeal],
  %w[930AMARRCNQE 930 national_quality_error dta compensation rating appeal],
  %w[930AMARRCPMC 930 control dta pension rating appeal],
  %w[930ARNRCLPMC 930 local_quality_error dta pension nonrating appeal],
  %w[930ARNRCLQE 930 local_quality_error dta compensation nonrating appeal],
  %w[930ARNRCNPMC 930 national_quality_error dta pension nonrating appeal],
  %w[930ARNRCNQE 930 national_quality_error dta compensation nonrating appeal],
  %w[930ARNRCPMC 930 control dta pension nonrating appeal],
  %w[930ARRCLQPMC 930 local_quality_error dta pension rating appeal],
  %w[930ARRCNQPMC 930 national_quality_error dta pension rating appeal],
  %w[930AHDENLPMC 930 local_quality_error dta pension nonrating higher_level_review],
  %w[930AHDENNPMC 930 national_quality_error dta pension nonrating higher_level_review],
  %w[930AHDENRPMC 930 control dta pension nonrating higher_level_review],
  %w[930AHDERPMC 930 control dta pension rating higher_level_review],
  %w[930AHDERLPMC 930 local_quality_error dta pension rating higher_level_review],
  %w[930AHDERNPMC 930 national_quality_error dta pension rating higher_level_review]
].freeze

describe "Request Issue Correction Cleaner", :postgres do
  let(:higher_level_review) { create(:higher_level_review, benefit_type: benefit_type) }
  let(:supplemental_claim) { create(:supplemental_claim, benefit_type: benefit_type, decision_review_remanded: drr) }
  let(:appeal) { create(:appeal) }
  let(:benefit_type) { nil }
  let(:correction_type) { nil }
  let(:decision_review) { nil }
  let(:drr) { nil }
  let(:contested_rating_issue_reference_id) { nil }
  let(:contested_decision_issue) { nil }
  let(:nonrating_issue_category) { nil }
  let(:is_unidentified) { nil }
  let(:request_issue) do
    create(:request_issue,
           nonrating_issue_category: nonrating_issue_category,
           contested_rating_issue_reference_id: contested_rating_issue_reference_id,
           contested_decision_issue: contested_decision_issue,
           decision_review: decision_review,
           benefit_type: benefit_type,
           correction_type: correction_type,
           is_unidentified: is_unidentified)
  end

  context "#call" do
    subject { EndProductCodeSelector.new(request_issue).call }

    context "for an unidentified issue" do
      let(:is_unidentified) { true }
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
          let(:correction_type) { ep_code[2] }
        end

        if ep_code[3] == "dta"
          let(:decision_review) { supplemental_claim }
          let(:drr) { send(ep_code[6]) }
          let(:contested_decision_issue) { create(:decision_issue, :nonrating, disposition: "remanded") }
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
