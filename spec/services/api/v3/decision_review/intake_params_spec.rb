# frozen_string_literal: true

context Api::V3::DecisionReview::IntakeParams do
  let(:intake_params) { Api::V3::DecisionReview::IntakeParams.new(params) }

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
      receiptDate: receipt_date,
      informalConference: informal_conference,
      sameOffice: same_office,
      legacyOptInApproved: legacy_opt_in_approved,
      benefitType: benefit_type,
      informalConferenceTimes: informal_conference_times,
      informalConferenceRep: informal_conference_rep,
      veteran: veteran,
      claimant: claimant
    }
  end

  let(:receipt_date) { (Time.zone.today - 5.days).strftime("%F") }
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

  let(:rep_name) { nil }
  let(:rep_phone_number) { nil }
  let(:rep_phone_number_country_code) { nil }
  let(:rep_phone_number_ext) { nil }

  let(:veteran) do
    {
      fileNumberOrSsn: file_number_or_ssn,
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

  let(:file_number_or_ssn) { "64205050" }
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

  let(:participant_id) { 44 }
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

  let(:included) do
    [
      {
        type: first_contestable_issue_type,
        attributes: first_contestable_issue_attributes
      }
    ]
  end

  let(:first_contestable_issue_type) { "ContestableIssue" }
  let(:first_contestable_issue_attributes) do
    {
      decisionIssueId: first_contestable_issue_decision_issue_id,
      ratingIssueId: first_contestable_issue_rating_issue_id,
      ratingDecisionIssueId: first_contestable_issue_rating_decision_issue_id,
      legacyAppealIssues: first_contestable_issue_legacy_appeal_issues
    }
  end

  let(:first_contestable_issue_decision_issue_id) { 232 }
  let(:first_contestable_issue_rating_issue_id) { nil }
  let(:first_contestable_issue_rating_decision_issue_id) { nil }

  let(:first_contestable_issue_legacy_appeal_issues) do
    [
      {
        legacyAppealId: first_legacy_appeal_id,
        legacyAppealIssueId: first_legacy_appeal_issue_id
      }
    ]
  end

  let(:first_legacy_appeal_id) { nil }
  let(:first_legacy_appeal_issue_id) { nil }

  context ".errors" do
    subject { intake_params.errors }
    it { is_expected.to eq [] }
  end

  #     context "invalid minimum required shape: type" do
  #       let(:params) { { data: { type: "Possum", attributes: {}, relationships: relationships } } }
  #       it "should have code :malformed_request" do
  #         expect(subject.errors.length).to eq(1)
  #         expect(subject.errors[0].code).to eq(:malformed_request)
  #       end
  #     end
  #
  #     context "valid minimum required shape" do
  #       let(:params) do
  #         {
  #           data: {
  #             type: "HigherLevelReview",
  #             attributes: { benefitType: "compensation" },
  #             relationships: relationships
  #           }
  #         }
  #       end
  #       it "should have no errors" do
  #         expect(subject.errors.length).to eq(0)
  #       end
  #     end
  #
  #     context "invalid minimum required shape: veteran type" do
  #       let(:params) do
  #         {
  #           data: {
  #             type: "HigherLevelReview",
  #             attributes: {},
  #             relationships: {
  #               veteran: {
  #                 data: {
  #                   type: "Veretan",
  #                   id: "something"
  #                 }
  #               }
  #             }
  #           }
  #         }
  #       end
  #       it "should have code :malformed_request" do
  #         expect(subject.errors.length).to eq(1)
  #         expect(subject.errors[0].code).to eq(:malformed_request)
  #       end
  #     end
  #
  #     context "valid minimum required shape" do
  #       let(:params) do
  #         {
  #           data: {
  #             type: "HigherLevelReview",
  #             attributes: { benefitType: "compensation" },
  #             relationships: {
  #               veteran: {
  #                 data: {
  #                   type: "Veteran",
  #                   id: "something"
  #                 }
  #               }
  #             }
  #           }
  #         }
  #       end
  #       it "should have no errors" do
  #         expect(subject.errors.length).to eq(0)
  #       end
  #     end
  #
  #     context "invalid minimum required shape: no veteran id" do
  #       let(:params) do
  #         {
  #           data: {
  #             type: "HigherLevelReview",
  #             attributes: {},
  #             relationships: {
  #               veteran: {
  #                 data: {
  #                   type: "Veretan",
  #                   id: " "
  #                 }
  #               }
  #             }
  #           }
  #         }
  #       end
  #       it "should have code :malformed_request" do
  #         expect(subject.errors.length).to eq(1)
  #         expect(subject.errors[0].code).to eq(:malformed_request)
  #       end
  #     end
  #
  #     context "bad request issue" do
  #       let(:included) do
  #         [
  #           {
  #             type: "RequestIssue",
  #             attributes: {}
  #           }
  #         ]
  #       end
  #       it "should have code :request_issue_cannot_be_empty" do
  #         expect(subject.errors.length).to eq(1)
  #         expect(subject.errors[0].code).to eq(:request_issue_cannot_be_empty)
  #       end
  #     end
  #
  #     context "invalid benefit type" do
  #       let(:benefit_type) { "super powers" }
  #       it "should have code :invalid_benefit_type" do
  #         expect(subject.errors.length).to eq(1)
  #         expect(subject.errors[0].code).to eq(:invalid_benefit_type)
  #       end
  #     end
  #   end

  # context ".veteran_file_number" do
  #   it "should return the veteran_file_number given" do
  #     expect(subject.veteran_file_number).to eq(veteran_file_number)
  #   end
  # end

  # context ".review_params" do
  #   it "should return a properly shape IntakesController-style params object" do
  #     expect(subject.review_params).to be_a(ActionController::Parameters)
  #     expect(subject.review_params.as_json).to eq(
  #       {
  #         receipt_date: attributes[:receiptDate],
  #         informal_conference: attributes[:informalConference],
  #         same_office: attributes[:sameOffice],
  #         benefit_type: attributes[:benefitType],
  #         claimant: claimant[:data][:id],
  #         payee_code: claimant[:data][:meta][:payeeCode],
  #         veteran_is_not_claimant: true,
  #         legacy_opt_in_approved: legacy_opt_in_approved
  #       }.as_json
  #     )
  #   end

  #   context do
  #     let(:receipt_date) { nil }
  #     it "should return today's date if no receiptDate was provided" do
  #       expect(subject.review_params[:receipt_date]).to eq(Time.now.in_time_zone.strftime("%F"))
  #     end
  #   end

  #   context do
  #     let(:claimant) { nil }
  #     it "should return a properly shape IntakesController-style params object" do
  #       expect(subject.errors).to eq([])
  #       expect(subject.review_params[:claimant]).to eq(nil)
  #       expect(subject.review_params[:payee_code]).to eq(nil)
  #       expect(subject.review_params[:veteran_is_not_claimant]).to eq(false)
  #     end
  #   end

  #   # tweaked for happy path (always returns true)
  #   context do
  #     let(:legacy_opt_in_approved) { false }
  #     it "should return a properly shape IntakesController-style params object" do
  #       expect(subject.errors).to eq([])
  #       expect(subject.review_params[:legacy_opt_in_approved]).to eq(true)
  #     end
  #   end
  # end

  # context ".complete_params" do
  #   it "should return a properly shape IntakesController-style params object" do
  #     expect(subject.complete_params.as_json).to eq(
  #       {
  #         request_issues: [
  #           {
  #             is_unidentified: false,
  #             benefit_type: benefit_type,
  #             nonrating_issue_category: category,
  #             contested_decision_issue_id: decision_issue_id,
  #             decision_date: decision_date,
  #             decision_text: decision_text,
  #             vacols_id: legacy_appeal_id,
  #             vacols_sequence_id: legacy_appeal_issue_id,
  #             notes: notes
  #           }
  #         ]
  #       }.as_json
  #     )
  #   end
  # end
end
