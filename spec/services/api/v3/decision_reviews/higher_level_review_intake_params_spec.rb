# frozen_string_literal: true

context Api::V3::DecisionReviews::HigherLevelReviewIntakeParams, :all_dbs do
  include IntakeHelpers

  let(:hlr_intake_params) { Api::V3::DecisionReviews::HigherLevelReviewIntakeParams.new(params) }

  let(:params) do
    ActionController::Parameters.new(
      data: data,
      included: included
    )
  end

  let(:data) do
    {
      type: type,
      attributes: attributes
    }
  end

  let(:type) { "HigherLevelReview" }

  let(:attributes) do
    attrs = {
      receiptDate: formatted_receipt_date,
      informalConference: informal_conference,
      sameOffice: same_office,
      legacyOptInApproved: legacy_opt_in_approved,
      benefitType: benefit_type,
      informalConferenceTimes: informal_conference_times,
      veteran: veteran_hash
    }

    attrs[:informalConferenceRep] = informal_conference_rep if informal_conference_rep
    attrs[:claimant] = claimant if claimant
    attrs
  end

  let(:formatted_receipt_date) { receipt_date.strftime("%F") }
  let(:receipt_date) { Time.zone.today - 5.days }
  let(:informal_conference) { true }
  let(:same_office) { false }
  let(:legacy_opt_in_approved) { true }
  let(:benefit_type) { "compensation" }

  let(:informal_conference_times) do
    ["800-1000 ET", "1000-1230 ET"]
  end

  let(:informal_conference_rep) do
    attrs = {
      name: rep_name,
      phoneNumber: rep_phone_number
    }

    attrs[:phoneNumberCountryCode] = rep_phone_number_country_code if rep_phone_number_country_code
    attrs[:phoneNumberExt] = rep_phone_number_ext if rep_phone_number_ext
    attrs
  end

  let(:rep_name) { "Jane Doe" }
  let(:rep_phone_number) { "8001234567" }
  let(:rep_phone_number_country_code) { nil }
  let(:rep_phone_number_ext) { nil }

  let(:veteran_hash) do
    { ssn: ssn }
  end
  let(:veteran) do
    create(:veteran,
           ssn: ssn,
           first_name: first_name,
           last_name: last_name)
  end
  let(:ssn) { "642055050" }
  let(:first_name) { "Jane" }
  let(:last_name) { "Doe" }

  let(:claimant) do
    {
      participantId: participant_id,
      payeeCode: payee_code
    }
  end

  let(:participant_id) { "44" }
  let(:payee_code) { "10" }

  let(:included) { [first_contestable_issue] }

  let(:first_contestable_issue) do
    {
      type: first_contestable_issue_type,
      attributes: first_contestable_issue_attributes
    }
  end

  let(:first_contestable_issue_type) { "ContestableIssue" }
  let(:first_contestable_issue_attributes) do
    attrs = {
      issue: "Broken elbow",
      decisionDate: "2019-12-24"
    }

    attrs[:decisionIssueId] = first_contestable_issue_decision_issue_id if first_contestable_issue_decision_issue_id
    attrs[:ratingIssueReferenceId] = first_contestable_issue_rating_issue_id if first_contestable_issue_rating_issue_id
    attrs[:ratingDecisionReferenceId] = first_c_issue_rating_decision_issue_id if first_c_issue_rating_decision_issue_id
    attrs
  end

  let(:first_contestable_issue_decision_issue_id) { contestable_issues.first&.decision_issue&.id }
  let(:first_contestable_issue_rating_issue_id) { contestable_issues.first&.rating_issue_reference_id }
  let(:first_c_issue_rating_decision_issue_id) { contestable_issues.first&.rating_decision_reference_id }

  let(:promulgation_date) { receipt_date - 10.days }
  let(:profile_date) { (receipt_date - 8.days).to_datetime }
  let!(:rating) { generate_rating(veteran, promulgation_date, profile_date) }

  let(:contestable_issues) do
    ContestableIssueGenerator.new(
      HigherLevelReview.new(
        veteran_file_number: veteran.file_number,
        receipt_date: receipt_date,
        benefit_type: benefit_type
      )
    ).contestable_issues
  end

  let(:included_with_lots_of_contestable_issues) do
    [
      {
        type: "ContestableIssue",
        attributes: {
          decisionIssueId: 1,
          ratingIssueReferenceId: "1",
          ratingDecisionReferenceId: "1"
        }
      },
      {
        type: "ContestableIssue",
        attributes: {
          decisionIssueId: 2,
          ratingIssueReferenceId: "2",
          ratingDecisionReferenceId: "2"
        }
      },
      {
        type: "ContestableIssue",
        attributes: {
          decisionIssueId: 3,
          ratingIssueReferenceId: "3",
          ratingDecisionReferenceId: "3"
        }
      },
      {
        type: "ContestableIssue",
        attributes: {
          decisionIssueId: 4,
          ratingIssueReferenceId: "4",
          ratingDecisionReferenceId: "4"
        }
      },
      {
        type: "ContestableIssue",
        attributes: {
          decisionIssueId: 5,
          ratingIssueReferenceId: "5",
          ratingDecisionReferenceId: "5"
        }
      },
      {
        type: "ContestableIssue",
        attributes: {
          decisionIssueId: 6,
          ratingIssueReferenceId: "6",
          ratingDecisionReferenceId: "6"
        }
      }
    ]
  end

  context "contestable_issues" do
    it { expect(contestable_issues).not_to be_empty }
  end

  describe "#intake_errors" do
    subject { hlr_intake_params.intake_errors }

    it { is_expected.to eq [] }

    context "no params" do
      let(:params) { nil }
      it do
        expect(subject.as_json).to eq(
          [
            Api::V3::DecisionReviews::IntakeError.new(
              :malformed_request,
              [{ detail: "payload must be an object" }]
            ).as_json
          ]
        )
      end
    end
  end

  describe "#intake_errors?" do
    subject { hlr_intake_params.intake_errors? }

    it { is_expected.to be false }

    context "no params" do
      let(:params) { nil }
      it { is_expected.to be true }
    end
  end

  describe "#review_params" do
    subject { hlr_intake_params.review_params.as_json }

    it do
      is_expected.to eq(
        {
          receipt_date: receipt_date,
          informal_conference: informal_conference,
          same_office: same_office,
          benefit_type: benefit_type,
          claimant: participant_id,
          claimant_type: "dependent",
          payee_code: payee_code,
          legacy_opt_in_approved: legacy_opt_in_approved
        }.as_json
      )
    end
  end

  describe "#complete_params" do
    subject { hlr_intake_params.complete_params.as_json }

    it do
      is_expected.to eq(
        {
          request_issues: [
            Api::V3::DecisionReviews::ContestableIssueParams.new(
              decision_review_class: HigherLevelReview,
              veteran: veteran,
              receipt_date: receipt_date,
              benefit_type: benefit_type,
              params: ActionController::Parameters.new(first_contestable_issue)
            ).intakes_controller_params
          ]
        }.as_json
      )
    end

    context "lots of contestable issues" do
      let(:included) { included_with_lots_of_contestable_issues }

      it do
        expect(hlr_intake_params.intake_errors?).to be true
        is_expected.to eq(
          {
            request_issues: (
              included_with_lots_of_contestable_issues.map do |contestable_issue|
                Api::V3::DecisionReviews::ContestableIssueParams.new(
                  decision_review_class: HigherLevelReview,
                  veteran: veteran,
                  receipt_date: receipt_date,
                  benefit_type: benefit_type,
                  params: ActionController::Parameters.new(contestable_issue)
                ).intakes_controller_params
              end
            )
          }.as_json
        )
      end
    end
  end

  describe "#veteran" do
    subject { hlr_intake_params.veteran }
    let(:veteran) { create(:veteran) }

    context "use ssn" do
      let(:ssn) { veteran.ssn }

      it { is_expected.to eq veteran }
    end
  end

  describe "#attributes" do
    subject { hlr_intake_params.attributes }

    it { expect(subject.as_json).to eq attributes.as_json }
  end

  describe "#attributes?" do
    subject { hlr_intake_params.attributes? }

    it { is_expected.to be true }

    context "no attributes" do
      let(:attributes) { true }

      it { is_expected.to be false }
    end

    context "no data" do
      let(:data) { nil }

      it { is_expected.to be false }
    end

    context "no params" do
      let(:params) { 1 }

      it { is_expected.to be false }
    end
  end

  describe "#params?" do
    subject { hlr_intake_params.params? }

    it { is_expected.to be true }

    context "no params" do
      let(:params) { nil }

      it { is_expected.to be false }
    end

    context "non hash" do
      let(:params) { true }

      it { is_expected.to be false }
    end
  end

  describe "#claimant_object_present?" do
    subject { hlr_intake_params.claimant_object_present? }

    it { is_expected.to be true }

    context "no claimant" do
      let(:claimant) { nil }

      it { is_expected.to be false }
    end
  end

  describe "#veteran_is_not_the_claimant?" do
    subject { hlr_intake_params.veteran_is_not_the_claimant? }

    it { is_expected.to be true }

    context "no claimant" do
      let(:claimant) { nil }

      it { is_expected.to be false }
    end

    context "no params (non-object)" do
      let(:params) { 1 }

      it { is_expected.to be false }
    end
  end

  describe "#claimant_who_is_not_the_veteran" do
    subject { hlr_intake_params.claimant_who_is_not_the_veteran.as_json }

    it { is_expected.to eq claimant.as_json }

    context "no claimant" do
      let(:claimant) { nil }

      it { is_expected.to eq({}) }
    end
  end

  describe "#informal_conference_rep?" do
    subject { hlr_intake_params.informal_conference_rep? }

    it { is_expected.to be true }

    context "no rep" do
      let(:informal_conference_rep) { nil }

      it { is_expected.to be false }
    end

    context "no params (non-object)" do
      let(:params) { 1 }

      it { is_expected.to be false }
    end
  end

  describe "#receipt_date" do
    subject { hlr_intake_params.receipt_date }

    it { is_expected.to eq formatted_receipt_date }

    context "no receipt date" do
      let(:formatted_receipt_date) { nil }

      it("returns today") { is_expected.to eq Time.zone.now.strftime("%F") }
    end
  end

  describe "#included" do
    subject { hlr_intake_params.included.as_json }

    it { is_expected.to eq included.as_json }

    context "no included" do
      let(:included) { nil }

      it { is_expected.to eq [] }
    end
  end

  describe "#benefit_type_valid?" do
    subject { hlr_intake_params.benefit_type_valid? }

    it { is_expected.to be true }

    context "invalid benefit type" do
      let(:benefit_type) { "qwerty" }

      it { is_expected.to be false }
    end

    context "unsupported benefit type" do
      let(:benefit_type) { "pension" }

      it { is_expected.to be false }
    end
  end

  describe "#shape_valid?" do
    subject { hlr_intake_params.shape_valid? }

    it { is_expected.to be true }

    context "invalid shape" do
      let(:params) { nil }
      it { is_expected.to be false }
    end
  end

  describe "#shape_error_message" do
    subject do
      errors = hlr_intake_params.shape_error_message
      errors[0][:detail] if errors.present?
    end

    it { is_expected.to be nil }

    context "no params" do
      let(:params) { nil }
      it { is_expected.to eq "payload must be an object" }
    end

    context "no data" do
      let(:data) { nil }
      it do
        is_expected.to include("The property /data did not match the following requirements")
      end
    end

    context "no type" do
      let(:type) { nil }
      it do
        is_expected.to eq(
          "The property /data/type did not match the following requirements " \
            "{\"type\"=>\"string\", \"enum\"=>[\"HigherLevelReview\"]}"
        )
      end
    end

    context "no attributes" do
      let(:attributes) { nil }
      it do
        is_expected.to include("The property /data/attributes did not match the following requirements")
      end
    end

    context "no receipt date" do
      let(:formatted_receipt_date) { 12 }
      it do
        is_expected.to eq(
          "The property /data/attributes/receiptDate did not match the following requirements" \
        " {\"type\"=>\"string\", \"pattern\"=>\"^[0-9]{4}-[0-9]{2}-[0-9]{2}$\"}"
        )
      end
    end

    context "no informal conference" do
      let(:informal_conference) { nil }
      it do
        is_expected.to eq(
          "The property /data/attributes/informalConference did not match the following requirements" \
" {\"type\"=>\"boolean\"}"
        )
      end
    end

    context "no informal conference times" do
      let(:informal_conference_times) { "dog" }
      it do
        is_expected.to include("The property /data/attributes/informalConferenceTimes did not match" \
" the following requirements")
      end
    end

    context "invalid informal conference time" do
      let(:informal_conference_times) { [13] }
      it do
        is_expected.to include("The property /data/attributes/informalConferenceTimes/0 did not match" \
" the following requirements")
      end
    end

    context "invalid informal conference time" do
      let(:informal_conference_times) { [nil, 24] }
      it do
        is_expected.to include("The property /data/attributes/informalConferenceTimes/0 did not match" \
" the following requirements")
      end
    end

    context "too many informal conference times" do
      let(:informal_conference_times) { [nil, nil, 87] }
      it do
        is_expected.to include("The property /data/attributes/informalConferenceTimes did not match" \
" the following requirements")
      end
    end

    context "invalid informal conference rep" do
      let(:informal_conference_rep) { 33 }

      it do
        is_expected.to include("The property /data/attributes/informalConferenceRep did not match" \
" the following requirements")
      end
    end

    describe "informal_conference_rep" do
      let(:informal_conference_rep) { nil }

      context "when informal_conference is true" do
        let(:informal_conference) { true }

        it "should return errors for informal_conference_rep" do
          is_expected.to include("The property /data/attributes did not contain the required key informalConferenceRep")
        end
      end

      context "when informal_conference is false" do
        let(:informal_conference) { false }

        it "should not return any errors for informal_conference_rep" do
          is_expected.to eq(nil)
        end
      end
    end

    context "no rep name" do
      let(:rep_name) { nil }
      it do
        is_expected.to include("The property /data/attributes/informalConferenceRep/name did not match the following" \
" requirements")
      end

      context "requirement not imposed when informal_conference: nil" do
        let(:informal_conference_rep) { nil }
        let(:informal_conference) { false }

        it { is_expected.to be nil }
      end
    end

    context "no rep phone number" do
      let(:rep_phone_number) { nil }
      it do
        is_expected.to include("The property /data/attributes/informalConferenceRep/phoneNumber did not match the "\
"following requirements")
      end

      context "requirement not imposed when informal_conference_rep: nil" do
        let(:informal_conference_rep) { nil }
        let(:informal_conference) { false }

        it { is_expected.to be nil }
      end
    end

    context "no rep country code" do
      let(:rep_phone_number_country_code) { [] }
      it do
        is_expected.to include("The property /data/attributes/informalConferenceRep/phoneNumberCountryCode did not" \
" match the following requirements")
      end
    end

    context "no rep phone number extension" do
      let(:rep_phone_number_ext) { true }
      it do
        is_expected.to include("The property /data/attributes/informalConferenceRep/phoneNumberExt did not" \
" match the following requirements")
      end
    end

    context "no same office" do
      let(:same_office) { nil }
      it do
        is_expected.to eq(
          "The property /data/attributes/sameOffice did not match the following requirements {\"type\"=>\"boolean\"}"
        )
      end
    end

    context "legacy opt-in non-bool" do
      let(:legacy_opt_in_approved) { nil }
      it do
        is_expected.to eq(
          "The property /data/attributes/legacyOptInApproved did not match the following requirements" \
" {\"type\"=>\"boolean\"}"
        )
      end
    end

    context "no benefit type" do
      let(:benefit_type) { nil }
      it do
        is_expected.to include("The property /data/attributes/benefitType did not match the following requirements")
      end
    end

    context "no veteran" do
      let(:veteran_hash) { nil }
      it do
        is_expected.to include("The property /data/attributes/veteran did not match the following requirements")
      end
    end

    context "no file number or ssn" do
      let(:contestable_issues) { [] }
      let(:rating) { nil }
      let(:veteran) { nil }
      let(:ssn) { nil }
      it do
        is_expected.to eq(
          "The property /data/attributes/veteran/ssn did not match the following requirements" \
" {\"type\"=>\"string\", \"pattern\"=>\"^[0-9]{9}$\"}"
        )
      end
    end

    context "invalid type for claimant" do
      let(:claimant) { true }
      it do
        is_expected.to include("The property /data/attributes/claimant did not match the following requirements")
      end
    end

    context "no claimant participant id" do
      let(:participant_id) { nil }
      it do
        is_expected.to include("The property /data/attributes/claimant/participantId did not match the following" \
" requirements")
      end

      context "requirement not imposed when claimant: nil" do
        let(:claimant) { nil }
        it { is_expected.to be nil }
      end
    end

    context "no claimant payee code" do
      let(:payee_code) { nil }
      it do
        is_expected.to include("The property /data/attributes/claimant/payeeCode did not match the following" \
" requirements")
      end

      context "requirement not imposed when claimant: nil" do
        let(:claimant) { nil }
        it { is_expected.to be nil }
      end
    end

    context "included not an array" do
      let(:included) { nil }
      it do
        is_expected.to include("The property /included did not match the following requirements")
      end
    end

    context "included element not an object" do
      let(:included) { [nil] }
      it do
        is_expected.to include("The property /included/0 did not match the following requirements")
      end
    end

    context "type of contestable issue not \"ContestableIssue\"" do
      let(:first_contestable_issue_type) { nil }
      it do
        is_expected.to eq(
          "The property /included/0/type did not match the following requirements {\"type\"=>\"string\"," \
" \"enum\"=>[\"ContestableIssue\"]}"
        )
      end
    end

    context "decision issue id wrong type" do
      let(:first_contestable_issue_decision_issue_id) { true }
      it do
        is_expected.to eq("The property /included/0/attributes/decisionIssueId did not match the following " \
"requirements {\"type\"=>\"integer\"}")
      end
    end

    context "rating issue id wrong type" do
      let(:first_contestable_issue_rating_issue_id) { true }
      it do
        is_expected.to eq(
          "The property /included/0/attributes/ratingIssueReferenceId did not match the following requirements" \
" {\"type\"=>\"string\"}"
        )
      end
    end

    context "rating decision issue id wrong type" do
      let(:first_c_issue_rating_decision_issue_id) { true }
      it do
        is_expected.to eq(
          "The property /included/0/attributes/ratingDecisionReferenceId did not match the following requirements" \
" {\"type\"=>\"string\"}"
        )
      end
    end
  end

  describe "#contestable_issues" do
    subject { hlr_intake_params.contestable_issues }

    it { is_expected.not_to be_empty }
    it { expect(subject.first).to be_a Api::V3::DecisionReviews::ContestableIssueParams }

    context "no contestable issues" do
      let(:included) { [] }

      it { is_expected.to be_empty }
    end
  end

  describe "#contestable_issue_intake_errors" do
    subject { hlr_intake_params.contestable_issue_intake_errors }

    it { is_expected.to eq [] }

    context "no IDs" do
      let(:first_contestable_issue_decision_issue_id) { nil }
      let(:first_contestable_issue_rating_issue_id) { nil }
      let(:first_c_issue_rating_decision_issue_id) { nil }

      it { is_expected.not_to be_empty }
    end
  end
end
