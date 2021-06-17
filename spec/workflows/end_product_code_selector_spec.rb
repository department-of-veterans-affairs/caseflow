# frozen_string_literal: true

# The EP code table below contains the combination of issue characteristics for each code

# Description of fields, as they are indexed in the array
# 0. EP code
# 1. primary vs. 930 correction
# 2. correction type (set to na if the EP is not for a 930 correction)
# 3. remand vs. original
# 4. difference_of_opinion vs. duty_to_assist (set to na if EP is not a remand)
# 5. benefit type
# 6. issue type
# 7. decision review type

EP_CODES = [
  %w[030HLRNR primary na original na compensation nonrating higher_level_review],
  %w[030HLRNRPMC primary na original na pension nonrating higher_level_review],
  %w[030HLRR primary na original na compensation rating higher_level_review],
  %w[030HLRRPMC primary na original na pension rating higher_level_review],
  %w[040SCNR primary na original na compensation nonrating supplemental_claim],
  %w[040SCNRPMC primary na original na pension nonrating supplemental_claim],
  %w[040SCR primary na original na compensation rating supplemental_claim],
  %w[040SCRPMC primary na original na pension rating supplemental_claim],
  %w[930AHCNRLPMC 930 local_quality_error original na pension nonrating higher_level_review],
  %w[930AHCNRLQE 930 local_quality_error original na compensation nonrating higher_level_review],
  %w[930AHCNRNPMC 930 national_quality_error original na pension nonrating higher_level_review],
  %w[930AHCNRNQE 930 national_quality_error original na compensation nonrating higher_level_review],
  %w[930AHCRLQPMC 930 local_quality_error original na pension rating higher_level_review],
  %w[930AHCRNQPMC 930 national_quality_error original na pension rating higher_level_review],
  %w[930AHNRCPMC 930 control original na pension nonrating higher_level_review],
  %w[930AMAHCRLQE 930 local_quality_error original na compensation rating higher_level_review],
  %w[930AMAHCRNQE 930 national_quality_error original na compensation rating higher_level_review],
  %w[930AMAHNRC 930 control original na compensation nonrating higher_level_review],
  %w[930AMAHRC 930 control original na compensation rating higher_level_review],
  %w[930AMAHRCPMC 930 control original na pension rating higher_level_review],
  %w[930AMASCRLQE 930 local_quality_error original na compensation rating supplemental_claim],
  %w[930AMASCRNQE 930 national_quality_error original na compensation rating supplemental_claim],
  %w[930AMASNRC 930 control original na compensation nonrating supplemental_claim],
  %w[930AMASRC 930 control original na compensation rating supplemental_claim],
  %w[930AMASRCPMC 930 control original na pension rating supplemental_claim],
  %w[930ASCNRLPMC 930 local_quality_error original na pension nonrating supplemental_claim],
  %w[930ASCNRLQE 930 local_quality_error original na compensation nonrating supplemental_claim],
  %w[930ASCNRNPMC 930 national_quality_error original na pension nonrating supplemental_claim],
  %w[930ASCNRNQE 930 national_quality_error original na compensation nonrating supplemental_claim],
  %w[930ASCRLQPMC 930 local_quality_error original na pension rating supplemental_claim],
  %w[930ASCRNQPMC 930 national_quality_error original na pension rating supplemental_claim],
  %w[930ASNRCPMC 930 control original na pension nonrating supplemental_claim],
  %w[040BDENR primary na remand duty_to_assist compensation nonrating appeal],
  %w[040BDENRPMC primary na remand duty_to_assist pension nonrating appeal],
  %w[040BDER primary na remand duty_to_assist compensation rating appeal],
  %w[040BDERPMC primary na remand duty_to_assist pension rating appeal],
  %w[040HDENR primary na remand duty_to_assist compensation nonrating higher_level_review],
  %w[040HDENRPMC primary na remand duty_to_assist pension nonrating higher_level_review],
  %w[040HDER primary na remand duty_to_assist compensation rating higher_level_review],
  %w[040HDERPMC primary na remand duty_to_assist pension rating higher_level_review],
  %w[040AMADONR primary na remand difference_of_opinion compensation nonrating higher_level_review],
  %w[040ADONRPMC primary na remand difference_of_opinion pension nonrating higher_level_review],
  %w[040AMADOR primary na remand difference_of_opinion compensation rating higher_level_review],
  %w[040ADORPMC primary na remand difference_of_opinion pension rating higher_level_review],
  %w[930AMAHDENCL 930 local_quality_error remand duty_to_assist compensation nonrating higher_level_review],
  %w[930AMAHDENCN 930 national_quality_error remand duty_to_assist compensation nonrating higher_level_review],
  %w[930AMAHDENR 930 control remand duty_to_assist compensation nonrating higher_level_review],
  %w[930AMAHDER 930 control remand duty_to_assist compensation rating higher_level_review],
  %w[930AMAHDERCL 930 local_quality_error remand duty_to_assist compensation rating higher_level_review],
  %w[930AMAHDERCN 930 national_quality_error remand duty_to_assist compensation rating higher_level_review],
  %w[930AMARNRC 930 control remand duty_to_assist compensation nonrating appeal],
  %w[930AMARRC 930 control remand duty_to_assist compensation rating appeal],
  %w[930AMARRCLQE 930 local_quality_error remand duty_to_assist compensation rating appeal],
  %w[930AMARRCNQE 930 national_quality_error remand duty_to_assist compensation rating appeal],
  %w[930AMARRCPMC 930 control remand duty_to_assist pension rating appeal],
  %w[930ARNRCLPMC 930 local_quality_error remand duty_to_assist pension nonrating appeal],
  %w[930ARNRCLQE 930 local_quality_error remand duty_to_assist compensation nonrating appeal],
  %w[930ARNRCNPMC 930 national_quality_error remand duty_to_assist pension nonrating appeal],
  %w[930ARNRCNQE 930 national_quality_error remand duty_to_assist compensation nonrating appeal],
  %w[930ARNRCPMC 930 control remand duty_to_assist pension nonrating appeal],
  %w[930ARRCLQPMC 930 local_quality_error remand duty_to_assist pension rating appeal],
  %w[930ARRCNQPMC 930 national_quality_error remand duty_to_assist pension rating appeal],
  %w[930AHDENLPMC 930 local_quality_error remand duty_to_assist pension nonrating higher_level_review],
  %w[930AHDENNPMC 930 national_quality_error remand duty_to_assist pension nonrating higher_level_review],
  %w[930AHDENRPMC 930 control remand duty_to_assist pension nonrating higher_level_review],
  %w[930AHDERPMC 930 control remand duty_to_assist pension rating higher_level_review],
  %w[930AHDERLPMC 930 local_quality_error remand duty_to_assist pension rating higher_level_review],
  %w[930AHDERNPMC 930 national_quality_error remand duty_to_assist pension rating higher_level_review],
  %w[930AMADONR 930 local_quality_error remand difference_of_opinion compensation nonrating higher_level_review],
  %w[930AMADONR 930 national_quality_error remand difference_of_opinion compensation nonrating higher_level_review],
  %w[930AMADONR 930 control remand difference_of_opinion compensation nonrating higher_level_review],
  %w[930AMADOR 930 control remand difference_of_opinion compensation rating higher_level_review],
  %w[930AMADOR 930 local_quality_error remand difference_of_opinion compensation rating higher_level_review],
  %w[930AMADOR 930 national_quality_error remand difference_of_opinion compensation rating higher_level_review],
  %w[930DONRPMC 930 local_quality_error remand difference_of_opinion pension nonrating higher_level_review],
  %w[930DONRPMC 930 national_quality_error remand difference_of_opinion pension nonrating higher_level_review],
  %w[930DONRPMC 930 control remand difference_of_opinion pension nonrating higher_level_review],
  %w[930DORPMC 930 control remand difference_of_opinion pension rating higher_level_review],
  %w[930DORPMC 930 local_quality_error remand difference_of_opinion pension rating higher_level_review],
  %w[930DORPMC 930 national_quality_error remand difference_of_opinion pension rating higher_level_review],
  %w[030HLRFID primary na original na fiduciary nonrating higher_level_review],
  %w[040SCRFID primary na original na fiduciary nonrating supplemental_claim]
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

    context "040SCRGTY EP Code supplemental_claim" do
      before { FeatureToggle.enable!(:itf_supplemental_claims) }
      after { FeatureToggle.disable!(:itf_supplemental_claims) }

      let(:benefit_type) { "compensation" }
      let(:receipt_date) { Time.zone.today - 1.year }
      let(:decision_review) { supplemental_claim }
      let(:decision_date) { "2018-10-1" }
      let!(:supplemental_claim) do
        create(:supplemental_claim,
               benefit_type: benefit_type,
               receipt_date: receipt_date)
      end

      let(:request_issue) do
        create(
          :request_issue,
          :rating,
          contested_rating_issue_reference_id: "def456",
          decision_review: decision_review,
          benefit_type: decision_review.benefit_type,
          contested_issue_description: "PTSD denied",
          decision_date: decision_date
        )
      end

      it "returns a itf_rating EP code" do
        expect(subject).to eq("040SCRGTY")
      end
    end

    EP_CODES.each do |ep_code|
      context "given attributes for EP code #{ep_code}" do
        subject { EndProductCodeSelector.new(request_issue).call }

        if ep_code[1] == "930"
          let(:correction_type) { ep_code[2] }
        end

        if ep_code[3] == "remand"
          let(:decision_review) { supplemental_claim }
          let(:drr) { send(ep_code[7]) }

          disposition = (ep_code[4] == "duty_to_assist") ? "remanded" : "Difference of Opinion"
          let(:contested_decision_issue) { create(:decision_issue, :nonrating, disposition: disposition) }
        else
          let(:decision_review) { send(ep_code[7]) }
        end

        let(:benefit_type) { ep_code[5] }

        if ep_code[6] == "rating"
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
