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

  describe ".prepend_path_to_paths" do
    let(:prepend_path) { [:data, :attributes] }
    let(:types_and_paths) do
      [
        [[Hash], []],
        [[String], [:name]],
        [[Hash], [:coord]],
        [[Float], [:coord, :x]],
        [[Float], [:coord, :y]]
      ]
    end
    subject do
      Api::V3::DecisionReview::IntakeParams.prepend_path_to_paths(
        prepend_path: prepend_path,
        types_and_paths: types_and_paths
      )
    end

    it do
      is_expected.to eq(
        [
          [[Hash], [:data, :attributes]],
          [[String], [:data, :attributes, :name]],
          [[Hash], [:data, :attributes, :coord]],
          [[Float], [:data, :attributes, :coord, :x]],
          [[Float], [:data, :attributes, :coord, :y]]
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

  describe "#for_array_at_path_enumerate_types_and_paths" do
    subject do
      intake_params.send(
        :for_array_at_path_enumerate_types_and_paths,
        array_path: array_path,
        types_and_paths: types_and_paths
      )
    end
    let(:array_path) { ["included"] }
    let(:types_and_paths) do
      [
        [[Hash], []],
        [["ContestableIssue"], ["type"]],
        [[Integer, nil],       %w[attributes decisionIssueId]],
        [[String, nil],        %w[attributes ratingIssueId]],
        [[String, nil],        %w[attributes ratingDecisionIssueId]],
        [[Array, nil],         %w[attributes legacyAppealIssues]]
      ]
    end

    it do
      is_expected.to eq(
        [
          [[Hash], ["included", 0]],
          [["ContestableIssue"], ["included", 0, "type"]],
          [[Integer, nil],       ["included", 0, "attributes", "decisionIssueId"]],
          [[String, nil],        ["included", 0, "attributes", "ratingIssueId"]],
          [[String, nil],        ["included", 0, "attributes", "ratingDecisionIssueId"]],
          [[Array, nil],         ["included", 0, "attributes", "legacyAppealIssues"]]
        ]
      )
    end

    context "types shouldn't matter" do
      let(:types_and_paths) do
        [
          [[], []],
          [{}, ["type"]],
          ["a",       %w[attributes decisionIssueId]],
          [12,        %w[attributes ratingIssueId]],
          [String, %w[attributes ratingDecisionIssueId]],
          [nil, %w[attributes legacyAppealIssues]]
        ]
      end

      it do
        is_expected.to eq(
          [
            [[], ["included", 0]],
            [{}, ["included", 0, "type"]],
            ["a",       ["included", 0, "attributes", "decisionIssueId"]],
            [12,        ["included", 0, "attributes", "ratingIssueId"]],
            [String, ["included", 0, "attributes", "ratingDecisionIssueId"]],
            [nil, ["included", 0, "attributes", "legacyAppealIssues"]]
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

  describe "#all_legacy_appeal_issue_paths" do
    subject { intake_params.send(:all_legacy_appeal_issue_paths) }

    it do
      is_expected.to eq(
        [
          ["included", 0, "legacyAppealIssues", 0]
        ]
      )
    end

    context "lots of contestable issues, some with legacyAppealIssues some without" do
      let(:included) do
        [
          { attributes: {} },
          { attributes: {} },
          {
            attributes: {
              legacyAppealIssues: ["a"]
            }
          },
          { attributes: {} },
          { attributes: {} },
          { attributes: {} },
          {
            attributes: {
              legacyAppealIssues: %w[b c d]
            }
          },
          {
            attributes: {
              legacyAppealIssues: ["e"]
            }
          },
          {
            attributes: {
              legacyAppealIssues: []
            }
          },
          {
            attributes: {
              legacyAppealIssues: %w[f g h]
            }
          }
        ]
      end

      it do
        is_expected.to eq(
          [
            ["included", 2, "legacyAppealIssues", 0],
            ["included", 6, "legacyAppealIssues", 0],
            ["included", 6, "legacyAppealIssues", 1],
            ["included", 6, "legacyAppealIssues", 2],
            ["included", 7, "legacyAppealIssues", 0],
            # no 8 (empty array)
            ["included", 9, "legacyAppealIssues", 0],
            ["included", 9, "legacyAppealIssues", 1],
            ["included", 9, "legacyAppealIssues", 2]
          ]
        )
      end
    end
  end
end
