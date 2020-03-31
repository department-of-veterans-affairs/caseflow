# frozen_string_literal: true

context Api::V3::DecisionReview::HigherLevelReviewIntakeParams, :all_dbs do
  include IntakeHelpers

  let(:hlr_intake_params) { Api::V3::DecisionReview::HigherLevelReviewIntakeParams.new(params) }

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
    {
      receiptDate: formatted_receipt_date,
      informalConference: informal_conference,
      sameOffice: same_office,
      legacyOptInApproved: legacy_opt_in_approved,
      benefitType: benefit_type,
      informalConferenceTimes: informal_conference_times,
      informalConferenceRep: informal_conference_rep,
      veteran: veteran_hash,
      claimant: claimant
    }
  end

  let(:formatted_receipt_date) { receipt_date.strftime("%F") }
  let(:receipt_date) { Time.zone.today - 5.days }
  let(:informal_conference) { true }
  let(:same_office) { false }
  let(:legacy_opt_in_approved) { true }
  let(:benefit_type) { "compensation" }

  let(:informal_conference_times) do
    ["", ""]
  end

  let(:informal_conference_rep) do
    {
      name: rep_name,
      phoneNumber: rep_phone_number,
      phoneNumberCountryCode: rep_phone_number_country_code,
      phoneNumberExt: rep_phone_number_ext
    }
  end

  let(:rep_name) { "Jane Doe" }
  let(:rep_phone_number) { "8001234567" }
  let(:rep_phone_number_country_code) { nil }
  let(:rep_phone_number_ext) { nil }

  let(:veteran_hash) do
    {
      ssn: ssn,
      addressLine1: vet_address_line_1,
      addressLine2: vet_address_line_2,
      city: vet_city,
      stateProvinceCode: vet_state_province_code,
      countryCode: vet_country_code,
      zipPostalCode: vet_zip_postal_code,
      phoneNumber: vet_phone_number,
      phoneNumberCountryCode: vet_phone_number_country_code,
      phoneNumberExt: vet_phone_number_ext,
      emailAddress: vet_email_address
    }
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
  let(:vet_address_line_1) { nil }
  let(:vet_address_line_2) { nil }
  let(:vet_city) { nil }
  let(:vet_state_province_code) { nil }
  let(:vet_country_code) { nil }
  let(:vet_zip_postal_code) { nil }
  let(:vet_phone_number) { nil }
  let(:vet_phone_number_country_code) { nil }
  let(:vet_phone_number_ext) { nil }
  let(:vet_email_address) { nil }

  let(:claimant) do
    {
      participantId: participant_id,
      payeeCode: payee_code,
      addressLine1: claimant_address_line_1,
      addressLine2: claimant_address_line_2,
      city: claimant_city,
      stateProvinceCode: claimant_state_province_code,
      countryCode: claimant_country_code,
      zipPostalCode: claimant_zip_postal_code,
      phoneNumber: claimant_phone_number,
      phoneNumberCountryCode: claimant_phone_number_country_code,
      phoneNumberExt: claimant_phone_number_ext,
      emailAddress: claimant_email_address
    }
  end

  let(:participant_id) { "44" }
  let(:payee_code) { "10" }
  let(:claimant_address_line_1) { nil }
  let(:claimant_address_line_2) { nil }
  let(:claimant_city) { nil }
  let(:claimant_state_province_code) { nil }
  let(:claimant_country_code) { nil }
  let(:claimant_zip_postal_code) { nil }
  let(:claimant_phone_number) { nil }
  let(:claimant_phone_number_country_code) { nil }
  let(:claimant_phone_number_ext) { nil }
  let(:claimant_email_address) { nil }

  let(:included) { [first_contestable_issue] }

  let(:first_contestable_issue) do
    {
      type: first_contestable_issue_type,
      attributes: first_contestable_issue_attributes
    }
  end

  let(:first_contestable_issue_type) { "ContestableIssue" }
  let(:first_contestable_issue_attributes) do
    {
      decisionIssueId: first_contestable_issue_decision_issue_id,
      ratingIssueId: first_contestable_issue_rating_issue_id,
      ratingDecisionIssueId: first_contestable_issue_rating_decision_issue_id
    }
  end

  let(:first_contestable_issue_decision_issue_id) { contestable_issues.first&.decision_issue&.id }
  let(:first_contestable_issue_rating_issue_id) { contestable_issues.first&.rating_issue_reference_id }
  let(:first_contestable_issue_rating_decision_issue_id) { contestable_issues.first&.rating_decision_reference_id }

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

  let(:object) { Api::V3::DecisionReview::HigherLevelReviewIntakeParams::OBJECT }
  let(:bool) { Api::V3::DecisionReview::HigherLevelReviewIntakeParams::BOOL }

  let(:included_with_lots_of_contestable_issues) do
    [
      {
        type: "ContestableIssue",
        attributes: {
          decisionIssueId: 1,
          ratingIssueId: "1",
          ratingDecisionIssueId: "1"
        }
      },
      {
        type: "ContestableIssue",
        attributes: {
          decisionIssueId: 2,
          ratingIssueId: "2",
          ratingDecisionIssueId: "2"
        }
      },
      {
        type: "ContestableIssue",
        attributes: {
          decisionIssueId: 3,
          ratingIssueId: "3",
          ratingDecisionIssueId: "3"
        }
      },
      {
        type: "ContestableIssue",
        attributes: {
          decisionIssueId: 4,
          ratingIssueId: "4",
          ratingDecisionIssueId: "4"
        }
      },
      {
        type: "ContestableIssue",
        attributes: {
          decisionIssueId: 5,
          ratingIssueId: "5",
          ratingDecisionIssueId: "5"
        }
      },
      {
        type: "ContestableIssue",
        attributes: {
          decisionIssueId: 6,
          ratingIssueId: "6",
          ratingDecisionIssueId: "6"
        }
      }
    ]
  end

  context "contestable_issues" do
    it { expect(contestable_issues).not_to be_empty }
  end

  describe ".prepend_path_to_paths" do
    let(:prepend_path) { [:data, :attributes] }
    let(:types_and_paths) do
      [
        [[Hash],   []],
        [[String], [:name]],
        [[Hash],   [:coord]],
        [[Float],  [:coord, :x]],
        [[Float],  [:coord, :y]]
      ]
    end
    subject do
      Api::V3::DecisionReview::HigherLevelReviewIntakeParams.prepend_path_to_paths(
        prepend_path: prepend_path,
        types_and_paths: types_and_paths
      )
    end

    it do
      is_expected.to eq(
        [
          [[Hash],   [:data, :attributes]],
          [[String], [:data, :attributes, :name]],
          [[Hash],   [:data, :attributes, :coord]],
          [[Float],  [:data, :attributes, :coord, :x]],
          [[Float],  [:data, :attributes, :coord, :y]]
        ]
      )
    end

    context "empty prepend path" do
      let(:prepend_path) { [] }
      it { is_expected.to eq types_and_paths }
    end

    context "empty types_and_paths" do
      let(:types_and_paths) { [] }
      it { is_expected.to eq [] }
    end
  end

  describe "#intake_errors" do
    subject { hlr_intake_params.intake_errors }

    it { is_expected.to eq [] }

    context "no params" do
      let(:params) { nil }
      it do
        expect(subject.as_json).to eq(
          [
            Api::V3::DecisionReview::IntakeError.new(
              :malformed_request,
              "payload must be an object"
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
          payee_code: payee_code,
          veteran_is_not_claimant: true,
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
            Api::V3::DecisionReview::ContestableIssueParams.new(
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
                Api::V3::DecisionReview::ContestableIssueParams.new(
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
    subject { hlr_intake_params.shape_error_message }

    it { is_expected.to be nil }

    context "no params" do
      let(:params) { nil }
      it { is_expected.to eq "payload must be an object" }
    end

    context "no data" do
      let(:data) { nil }
      it do
        is_expected.to eq(
          "[\"data\"]" \
            " should be one of #{object.inspect}. Got: #{data.inspect}."
        )
      end
    end

    context "no type" do
      let(:type) { nil }
      it do
        is_expected.to eq(
          "[\"data\"][\"type\"]" \
            " should be \"HigherLevelReview\". Got: #{type.inspect}."
        )
      end
    end

    context "no attributes" do
      let(:attributes) { nil }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"]" \
            " should be one of #{object.inspect}. Got: #{attributes.inspect}."
        )
      end
    end

    context "no receipt date" do
      let(:formatted_receipt_date) { 12 }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"receiptDate\"]" \
            " should be one of [String, nil]. Got: #{formatted_receipt_date.inspect}."
        )
      end
    end

    context "no informal conference" do
      let(:informal_conference) { nil }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"informalConference\"]" \
            " should be one of [true, false]. Got: #{informal_conference.inspect}."
        )
      end
    end

    context "no informal conference times" do
      let(:informal_conference_times) { "dog" }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"informalConferenceTimes\"]" \
            " should be one of [Array, nil]. Got: #{informal_conference_times.inspect}."
        )
      end
    end

    context "invalid informal conference time" do
      let(:informal_conference_times) { [13] }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"informalConferenceTimes\"][0]" \
            " should be one of [String, nil]. Got: #{informal_conference_times[0].inspect}."
        )
      end
    end

    context "invalid informal conference time" do
      let(:informal_conference_times) { [nil, 24] }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"informalConferenceTimes\"][1]" \
            " should be one of [String, nil]. Got: #{informal_conference_times[1].inspect}."
        )
      end
    end

    context "too many informal conference times" do
      let(:informal_conference_times) { [nil, nil, 87] }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"informalConferenceTimes\"][2]" \
            " should be nil. Got: #{informal_conference_times[2].inspect}."
        )
      end
    end

    context "invalid informal conference rep" do
      let(:informal_conference_rep) { 33 }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"informalConferenceRep\"]" \
            " should be one of #{object.inspect[0...-1] + ', nil]'}. Got: #{informal_conference_rep.inspect}."
        )
      end
    end

    context "no rep name" do
      let(:rep_name) { nil }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"informalConferenceRep\"][\"name\"]" \
            " should be a(n) string. Got: #{rep_name.inspect}."
        )
      end

      context "requirement not imposed when informal_conference_rep: nil" do
        let(:informal_conference_rep) { nil }
        it { is_expected.to be nil }
      end
    end

    context "no rep phone number" do
      let(:rep_phone_number) { nil }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"informalConferenceRep\"][\"phoneNumber\"]" \
            " should be one of [String, Integer]. Got: #{rep_phone_number.inspect}."
        )
      end

      context "requirement not imposed when informal_conference_rep: nil" do
        let(:informal_conference_rep) { nil }
        it { is_expected.to be nil }
      end
    end

    context "no rep country code" do
      let(:rep_phone_number_country_code) { [] }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"informalConferenceRep\"][\"phoneNumberCountryCode\"]" \
            " should be one of [String, Integer, nil]. Got: #{rep_phone_number_country_code.inspect}."
        )
      end
    end

    context "no rep phone number extension" do
      let(:rep_phone_number_ext) { true }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"informalConferenceRep\"][\"phoneNumberExt\"]" \
            " should be one of [String, Integer, nil]. Got: #{rep_phone_number_ext.inspect}."
        )
      end
    end

    context "no same office" do
      let(:same_office) { nil }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"sameOffice\"]" \
            " should be one of [true, false]. Got: #{same_office.inspect}."
        )
      end
    end

    context "legacy opt-in non-bool" do
      let(:legacy_opt_in_approved) { nil }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"legacyOptInApproved\"]" \
            " should be one of [true, false]. Got: #{legacy_opt_in_approved.inspect}."
        )
      end
    end

    context "no benefit type" do
      let(:benefit_type) { nil }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"benefitType\"]" \
            " should be a(n) string. Got: #{benefit_type.inspect}."
        )
      end
    end

    context "no veteran" do
      let(:veteran_hash) { nil }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"veteran\"]" \
            " should be one of #{object.inspect}. Got: #{veteran_hash.inspect}."
        )
      end
    end

    context "no file number or ssn" do
      let(:contestable_issues) { [] }
      let(:rating) { nil }
      let(:veteran) { nil }
      let(:ssn) { nil }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"veteran\"][\"ssn\"]" \
            " should be a(n) string. Got: #{ssn.inspect}."
        )
      end
    end

    context "invalid vet address (line 1)" do
      let(:vet_address_line_1) { true }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"veteran\"][\"addressLine1\"]" \
            " should be one of [String, nil]. Got: #{vet_address_line_1.inspect}."
        )
      end
    end

    context "invalid vet address (line 2)" do
      let(:vet_address_line_2) { true }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"veteran\"][\"addressLine2\"]" \
            " should be one of [String, nil]. Got: #{vet_address_line_2.inspect}."
        )
      end
    end

    context "invalid type for vet city " do
      let(:vet_city) { true }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"veteran\"][\"city\"]" \
            " should be one of [String, nil]. Got: #{vet_city.inspect}."
        )
      end
    end

    context "invalid vet state / province code" do
      let(:vet_state_province_code) { true }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"veteran\"][\"stateProvinceCode\"]" \
            " should be one of [String, nil]. Got: #{vet_state_province_code.inspect}."
        )
      end
    end

    context "invalid vet country code" do
      let(:vet_country_code) { true }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"veteran\"][\"countryCode\"]" \
            " should be one of [String, nil]. Got: #{vet_country_code.inspect}."
        )
      end
    end

    context "invalid vet zip / postal code" do
      let(:vet_zip_postal_code) { true }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"veteran\"][\"zipPostalCode\"]" \
            " should be one of [String, nil]. Got: #{vet_zip_postal_code.inspect}."
        )
      end
    end

    context "invalid vet phone number" do
      let(:vet_phone_number) { true }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"veteran\"][\"phoneNumber\"]" \
            " should be one of [String, nil]. Got: #{vet_phone_number.inspect}."
        )
      end
    end

    context "invalid vet phone number country code" do
      let(:vet_phone_number_country_code) { true }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"veteran\"][\"phoneNumberCountryCode\"]" \
            " should be one of [String, nil]. Got: #{vet_phone_number_country_code.inspect}."
        )
      end
    end

    context "invalid vet phone number extension" do
      let(:vet_phone_number_ext) { true }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"veteran\"][\"phoneNumberExt\"]" \
            " should be one of [String, nil]. Got: #{vet_phone_number_ext.inspect}."
        )
      end
    end

    context "invalid type for vet email address" do
      let(:vet_email_address) { true }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"veteran\"][\"emailAddress\"]" \
            " should be one of [String, nil]. Got: #{vet_email_address.inspect}."
        )
      end
    end

    context "invalid type for claimant" do
      let(:claimant) { true }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"claimant\"]" \
            " should be one of #{object.inspect[0...-1] + ', nil]'}. Got: #{claimant.inspect}."
        )
      end
    end

    context "no claimant participant id" do
      let(:participant_id) { nil }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"claimant\"][\"participantId\"]" \
            " should be a(n) string. Got: #{participant_id.inspect}."
        )
      end

      context "requirement not imposed when claimant: nil" do
        let(:claimant) { nil }
        it { is_expected.to be nil }
      end
    end

    context "no claimant payee code" do
      let(:payee_code) { nil }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"claimant\"][\"payeeCode\"]" \
            " should be a(n) string. Got: #{payee_code.inspect}."
        )
      end

      context "requirement not imposed when claimant: nil" do
        let(:claimant) { nil }
        it { is_expected.to be nil }
      end
    end

    context "no claimant address (line 1)" do
      let(:claimant_address_line_1) { true }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"claimant\"][\"addressLine1\"]" \
            " should be one of [String, nil]. Got: #{claimant_address_line_1.inspect}."
        )
      end
    end

    context "no claimant address (line 2)" do
      let(:claimant_address_line_2) { true }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"claimant\"][\"addressLine2\"]" \
            " should be one of [String, nil]. Got: #{claimant_address_line_2.inspect}."
        )
      end
    end

    context "invalid type for claimant city" do
      let(:claimant_city) { true }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"claimant\"][\"city\"]" \
            " should be one of [String, nil]. Got: #{claimant_city.inspect}."
        )
      end
    end

    context "invalid claimant state / province code" do
      let(:claimant_state_province_code) { true }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"claimant\"][\"stateProvinceCode\"]" \
            " should be one of [String, nil]. Got: #{claimant_state_province_code.inspect}."
        )
      end
    end

    context "invalid claimant country code" do
      let(:claimant_country_code) { true }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"claimant\"][\"countryCode\"]" \
            " should be one of [String, nil]. Got: #{claimant_country_code.inspect}."
        )
      end
    end

    context "invalid claimant zip / postal code" do
      let(:claimant_zip_postal_code) { true }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"claimant\"][\"zipPostalCode\"]" \
            " should be one of [String, nil]. Got: #{claimant_zip_postal_code.inspect}."
        )
      end
    end

    context "invalid claimant phone number" do
      let(:claimant_phone_number) { true }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"claimant\"][\"phoneNumber\"]" \
            " should be one of [String, nil]. Got: #{claimant_phone_number.inspect}."
        )
      end
    end

    context "invalid claimant phone number country code" do
      let(:claimant_phone_number_country_code) { true }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"claimant\"][\"phoneNumberCountryCode\"]" \
            " should be one of [String, nil]. Got: #{claimant_phone_number_country_code.inspect}."
        )
      end
    end

    context "invalid claimant phone number extension" do
      let(:claimant_phone_number_ext) { true }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"claimant\"][\"phoneNumberExt\"]" \
            " should be one of [String, nil]. Got: #{claimant_phone_number_ext.inspect}."
        )
      end
    end

    context "invalid type for claimant email address" do
      let(:claimant_email_address) { true }
      it do
        is_expected.to eq(
          "[\"data\"][\"attributes\"][\"claimant\"][\"emailAddress\"]" \
            " should be one of [String, nil]. Got: #{claimant_email_address.inspect}."
        )
      end
    end

    context "included not an array" do
      let(:included) { nil }
      it do
        is_expected.to eq(
          "[\"included\"]" \
            " should be a(n) array. Got: #{included.inspect}."
        )
      end
    end

    context "included element not an object" do
      let(:included) { [nil] }
      it do
        is_expected.to eq(
          "[\"included\"][0]" \
            " should be one of #{object.inspect}. Got: #{included[0].inspect}."
        )
      end
    end

    context "type of contestable issue not \"ContestableIssue\"" do
      let(:first_contestable_issue_type) { nil }
      it do
        is_expected.to eq(
          "[\"included\"][0][\"type\"]" \
            " should be \"ContestableIssue\". Got: #{first_contestable_issue_type.inspect}."
        )
      end
    end

    context "decision issue id wrong type" do
      let(:first_contestable_issue_decision_issue_id) { true }
      it do
        is_expected.to eq(
          "[\"included\"][0][\"attributes\"][\"decisionIssueId\"]" \
            " should be one of [String, Integer, nil]. Got: #{first_contestable_issue_decision_issue_id.inspect}."
        )
      end
    end

    context "rating issue id wrong type" do
      let(:first_contestable_issue_rating_issue_id) { true }
      it do
        is_expected.to eq(
          "[\"included\"][0][\"attributes\"][\"ratingIssueId\"]" \
            " should be one of [String, Integer, nil]. Got: #{first_contestable_issue_rating_issue_id.inspect}."
        )
      end
    end

    context "rating decision issue id wrong type" do
      let(:first_contestable_issue_rating_decision_issue_id) { true }
      it do
        is_expected.to eq(
          "[\"included\"][0][\"attributes\"][\"ratingDecisionIssueId\"]" \
          " should be one of [String, Integer, nil]." \
          " Got: #{first_contestable_issue_rating_decision_issue_id.inspect}."
        )
      end
    end
  end

  describe "#contestable_issues" do
    subject { hlr_intake_params.contestable_issues }

    it { is_expected.not_to be_empty }
    it { expect(subject.first).to be_a Api::V3::DecisionReview::ContestableIssueParams }

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
      let(:first_contestable_issue_rating_decision_issue_id) { nil }

      it { is_expected.not_to be_empty }
    end
  end

  describe "#types_and_paths" do
    subject { hlr_intake_params.types_and_paths }

    let(:expected_array) do
      [
        [object, ["data"]],
        [["HigherLevelReview"], %w[data type]],
        [object,         %w[data attributes]],
        [[String, nil],  %w[data attributes receiptDate]],
        [bool,           %w[data attributes informalConference]],
        [[Array, nil],   %w[data attributes informalConferenceTimes]],
        [[String, nil],  ["data", "attributes", "informalConferenceTimes", 0]],
        [[String, nil],  ["data", "attributes", "informalConferenceTimes", 1]],
        [[nil],          ["data", "attributes", "informalConferenceTimes", 2]],
        [[*object, nil], %w[data attributes informalConferenceRep]],
        [[String],       %w[data attributes informalConferenceRep name]],
        [[String, Integer], %w[data attributes informalConferenceRep phoneNumber]],
        [[String, Integer, nil],  %w[data attributes informalConferenceRep phoneNumberCountryCode]],
        [[String, Integer, nil],  %w[data attributes informalConferenceRep phoneNumberExt]],
        [bool,           %w[data attributes sameOffice]],
        [bool,           %w[data attributes legacyOptInApproved]],
        [[String],       %w[data attributes benefitType]],
        [object,         %w[data attributes veteran]],
        [[String],       %w[data attributes veteran ssn]],
        [[String, nil],  %w[data attributes veteran addressLine1]],
        [[String, nil],  %w[data attributes veteran addressLine2]],
        [[String, nil],  %w[data attributes veteran city]],
        [[String, nil],  %w[data attributes veteran stateProvinceCode]],
        [[String, nil],  %w[data attributes veteran countryCode]],
        [[String, nil],  %w[data attributes veteran zipPostalCode]],
        [[String, nil],  %w[data attributes veteran phoneNumber]],
        [[String, nil],  %w[data attributes veteran phoneNumberCountryCode]],
        [[String, nil],  %w[data attributes veteran phoneNumberExt]],
        [[String, nil],  %w[data attributes veteran emailAddress]],
        [[*object, nil], %w[data attributes claimant]],
        [[String],       %w[data attributes claimant participantId]],
        [[String],       %w[data attributes claimant payeeCode]],
        [[String, nil],  %w[data attributes claimant addressLine1]],
        [[String, nil],  %w[data attributes claimant addressLine2]],
        [[String, nil],  %w[data attributes claimant city]],
        [[String, nil],  %w[data attributes claimant stateProvinceCode]],
        [[String, nil],  %w[data attributes claimant countryCode]],
        [[String, nil],  %w[data attributes claimant zipPostalCode]],
        [[String, nil],  %w[data attributes claimant phoneNumber]],
        [[String, nil],  %w[data attributes claimant phoneNumberCountryCode]],
        [[String, nil],  %w[data attributes claimant phoneNumberExt]],
        [[String, nil],  %w[data attributes claimant emailAddress]],
        [[Array],                ["included"]],
        [object,                 ["included", 0]],
        [["ContestableIssue"],   ["included", 0, "type"]],
        [[String, Integer, nil], ["included", 0, "attributes", "decisionIssueId"]],
        [[String, Integer, nil], ["included", 0, "attributes", "ratingIssueId"]],
        [[String, Integer, nil], ["included", 0, "attributes", "ratingDecisionIssueId"]]
      ]
    end

    it do
      expect(subject.length).to eq(expected_array.length)
      expected_array.each.with_index do |expected, index|
        expect(subject[index]).to eq(expected)
      end
    end

    context "an empty included array is ignored" do
      let(:included) { [] }
      let(:expected_array_without_included) { expected_array[0...-5] }

      it do
        expect(subject.length).to eq(expected_array_without_included.length)
        expected_array_without_included.each.with_index do |expected, index|
          expect(subject[index]).to eq(expected)
        end
      end

      context "no included" do
        let(:included) { nil }

        it do
          expect(subject.length).to eq(expected_array_without_included.length)
          expected_array_without_included.each.with_index do |expected, index|
            expect(subject[index]).to eq(expected)
          end
        end
      end
    end

    context "a more interesting included array" do
      let(:included) { included_with_lots_of_contestable_issues }

      let(:expected_array_with_interesting_included) do
        expected_array[0...-5] +
          [
            [object,                 ["included", 0]],
            [["ContestableIssue"],   ["included", 0, "type"]],
            [[String, Integer, nil], ["included", 0, "attributes", "decisionIssueId"]],
            [[String, Integer, nil], ["included", 0, "attributes", "ratingIssueId"]],
            [[String, Integer, nil], ["included", 0, "attributes", "ratingDecisionIssueId"]],
            [object,                 ["included", 1]],
            [["ContestableIssue"],   ["included", 1, "type"]],
            [[String, Integer, nil], ["included", 1, "attributes", "decisionIssueId"]],
            [[String, Integer, nil], ["included", 1, "attributes", "ratingIssueId"]],
            [[String, Integer, nil], ["included", 1, "attributes", "ratingDecisionIssueId"]],
            [object,                 ["included", 2]],
            [["ContestableIssue"],   ["included", 2, "type"]],
            [[String, Integer, nil], ["included", 2, "attributes", "decisionIssueId"]],
            [[String, Integer, nil], ["included", 2, "attributes", "ratingIssueId"]],
            [[String, Integer, nil], ["included", 2, "attributes", "ratingDecisionIssueId"]],
            [object,                 ["included", 3]],
            [["ContestableIssue"],   ["included", 3, "type"]],
            [[String, Integer, nil], ["included", 3, "attributes", "decisionIssueId"]],
            [[String, Integer, nil], ["included", 3, "attributes", "ratingIssueId"]],
            [[String, Integer, nil], ["included", 3, "attributes", "ratingDecisionIssueId"]],
            [object,                 ["included", 4]],
            [["ContestableIssue"],   ["included", 4, "type"]],
            [[String, Integer, nil], ["included", 4, "attributes", "decisionIssueId"]],
            [[String, Integer, nil], ["included", 4, "attributes", "ratingIssueId"]],
            [[String, Integer, nil], ["included", 4, "attributes", "ratingDecisionIssueId"]],
            [object,                 ["included", 5]],
            [["ContestableIssue"],   ["included", 5, "type"]],
            [[String, Integer, nil], ["included", 5, "attributes", "decisionIssueId"]],
            [[String, Integer, nil], ["included", 5, "attributes", "ratingIssueId"]],
            [[String, Integer, nil], ["included", 5, "attributes", "ratingDecisionIssueId"]]
          ]
      end

      it do
        expect(subject.length).to eq(expected_array_with_interesting_included.length)
        expected_array_with_interesting_included.each.with_index do |expected, index|
          expect(subject[index]).to eq(expected)
        end
      end
    end
  end

  describe "#for_array_at_path_enumerate_types_and_paths" do
    subject do
      hlr_intake_params.for_array_at_path_enumerate_types_and_paths(
        array_path: array_path,
        types_and_paths: types_and_paths
      )
    end
    let(:array_path) { ["included"] }
    let(:types_and_paths) do
      [
        [[Hash],                 []],
        [["ContestableIssue"],   ["type"]],
        [[String, Integer, nil], %w[attributes decisionIssueId]],
        [[String, Integer, nil], %w[attributes ratingIssueId]],
        [[String, Integer, nil], %w[attributes ratingDecisionIssueId]]
      ]
    end

    it do
      is_expected.to eq(
        [
          [[Hash],                 ["included", 0]],
          [["ContestableIssue"],   ["included", 0, "type"]],
          [[String, Integer, nil], ["included", 0, "attributes", "decisionIssueId"]],
          [[String, Integer, nil], ["included", 0, "attributes", "ratingIssueId"]],
          [[String, Integer, nil], ["included", 0, "attributes", "ratingDecisionIssueId"]]
        ]
      )
    end

    context "types shouldn't matter" do
      let(:types_and_paths) do
        [
          [[],     []],
          [{},     ["type"]],
          ["a",    %w[attributes decisionIssueId]],
          [12,     %w[attributes ratingIssueId]],
          [String, %w[attributes ratingDecisionIssueId]]
        ]
      end

      it do
        is_expected.to eq(
          [
            [[],     ["included", 0]],
            [{},     ["included", 0, "type"]],
            ["a",    ["included", 0, "attributes", "decisionIssueId"]],
            [12,     ["included", 0, "attributes", "ratingIssueId"]],
            [String, ["included", 0, "attributes", "ratingDecisionIssueId"]]
          ]
        )
      end
    end

    context "more interesting path" do
      let(:params) do
        { a: [{ b: [{ c: [1, 2, 3, 4, 5, 6, 7] }] }] }
      end
      let(:array_path) { [:a, 0, :b, 0, :c] }
      let(:types_and_paths) do
        [
          [[Integer], []]
        ]
      end

      it do
        is_expected.to eq(
          [
            [[Integer], [:a, 0, :b, 0, :c, 0]],
            [[Integer], [:a, 0, :b, 0, :c, 1]],
            [[Integer], [:a, 0, :b, 0, :c, 2]],
            [[Integer], [:a, 0, :b, 0, :c, 3]],
            [[Integer], [:a, 0, :b, 0, :c, 4]],
            [[Integer], [:a, 0, :b, 0, :c, 5]],
            [[Integer], [:a, 0, :b, 0, :c, 6]]
          ]
        )
      end
    end

    context "another interesting path" do
      let(:params) do
        { a: [{ b: [{ c: [{ x: 8.8, y: 1.2 }, { x: 9, y: 22.9 }, {}] }] }] }
      end
      let(:array_path) { [:a, 0, :b, 0, :c] }
      let(:types_and_paths) do
        [
          [[Hash], []],
          [[Float], [:x]],
          [[Float], [:y]]
        ]
      end

      it do
        is_expected.to eq(
          [
            [[Hash],    [:a, 0, :b, 0, :c, 0]],
            [[Float],   [:a, 0, :b, 0, :c, 0, :x]],
            [[Float],   [:a, 0, :b, 0, :c, 0, :y]],
            [[Hash],    [:a, 0, :b, 0, :c, 1]],
            [[Float],   [:a, 0, :b, 0, :c, 1, :x]],
            [[Float],   [:a, 0, :b, 0, :c, 1, :y]],
            [[Hash],    [:a, 0, :b, 0, :c, 2]],
            [[Float],   [:a, 0, :b, 0, :c, 2, :x]],
            [[Float],   [:a, 0, :b, 0, :c, 2, :y]]
          ]
          # in a real scenario, you could use the
          # resulting array ^^^ and HashPathValidator
          # to catch that the third element is empty
          # (see params)
        )
      end
    end
  end
end
