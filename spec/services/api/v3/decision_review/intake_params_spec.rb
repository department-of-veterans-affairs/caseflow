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

  let(:rep_name) { "Jane Doe" }
  let(:rep_phone_number) { "8001234567" }
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

  let(:first_legacy_appeal_id) { "123" }
  let(:first_legacy_appeal_issue_id) { "1" }

  let(:object) { Api::V3::DecisionReview::IntakeParams::OBJECT }
  let(:bool) { Api::V3::DecisionReview::IntakeParams::BOOL }

  let(:included_with_lots_of_contestable_issues) do
    [
      {
        type: "ContestableIssue",
        attributes: {
          decisionIssueId: 1,
          ratingIssueId: "1",
          ratingDecisionIssueId: "1",
          legacyAppealIssues: nil
        }
      },
      {
        type: "ContestableIssue",
        attributes: {
          decisionIssueId: 2,
          ratingIssueId: "2",
          ratingDecisionIssueId: "2",
          legacyAppealIssues: []
        }
      },
      {
        type: "ContestableIssue",
        attributes: {
          decisionIssueId: 3,
          ratingIssueId: "3",
          ratingDecisionIssueId: "3",
          legacyAppealIssues: [
            {
              legacyAppealId: "123456",
              legacyAppealIssueId: "1"
            },
            {
              legacyAppealId: "123456",
              legacyAppealIssueId: "2"
            }
          ]
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
          ratingDecisionIssueId: "5",
          legacyAppealIssues: [
            {
              legacyAppealId: "789123",
              legacyAppealIssueId: "3"
            },
            {
              legacyAppealId: "8765",
              legacyAppealIssueId: "9"
            },
            {
              legacyAppealId: "8233",
              legacyAppealIssueId: "1"
            },
            {
              legacyAppealId: "8233",
              legacyAppealIssueId: "2"
            },
            {
              legacyAppealId: "1112",
              legacyAppealIssueId: "1"
            }
          ]
        }
      },
      {
        type: "ContestableIssue",
        attributes: {
          decisionIssueId: 6,
          ratingIssueId: "6",
          ratingDecisionIssueId: "6",
          legacyAppealIssues: [
            {
              legacyAppealId: "34343",
              legacyAppealIssueId: "56"
            }
          ]
        }
      }
    ]
  end

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

  describe "#legacy_appeal_issues_paths" do
    subject { intake_params.send(:legacy_appeal_issues_paths) }

    it { is_expected.to eq([["included", 0, "attributes", "legacyAppealIssues"]]) }

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
            ["included", 2, "attributes", "legacyAppealIssues"],
            ["included", 6, "attributes", "legacyAppealIssues"],
            ["included", 7, "attributes", "legacyAppealIssues"],
            ["included", 9, "attributes", "legacyAppealIssues"]
          ]
        )
      end
    end
  end

  describe "#types_and_paths" do
    subject { intake_params.send(:types_and_paths) }

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
        [[String],       %w[data attributes veteran fileNumberOrSsn]],
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
        [[Array],              ["included"]],
        [object,               ["included", 0]],
        [["ContestableIssue"], ["included", 0, "type"]],
        [[Integer, nil],       ["included", 0, "attributes", "decisionIssueId"]],
        [[String, nil],        ["included", 0, "attributes", "ratingIssueId"]],
        [[String, nil],        ["included", 0, "attributes", "ratingDecisionIssueId"]],
        [[Array, nil],         ["included", 0, "attributes", "legacyAppealIssues"]],
        [object,               ["included", 0, "attributes", "legacyAppealIssues", 0]],
        [[String],             ["included", 0, "attributes", "legacyAppealIssues", 0, "legacyAppealId"]],
        [[String],             ["included", 0, "attributes", "legacyAppealIssues", 0, "legacyAppealIssueId"]]
      ]
    end

    it do
      expect(subject.length).to eq(expected_array.length)
      expected_array.each.with_index do |expected, index|
        expect(subject[index]).to eq(expected)
      end
    end

    context "an empty legacyAppealIssues array is ignored" do
      let(:first_contestable_issue_legacy_appeal_issues) { [] }
      let(:expected_array_without_legacy_appeal_issues) { expected_array[0...-3] }

      it do
        expect(subject.length).to eq(expected_array_without_legacy_appeal_issues.length)
        expected_array_without_legacy_appeal_issues.each.with_index do |expected, index|
          expect(subject[index]).to eq(expected)
        end
      end

      context do
        let(:first_contestable_issue_legacy_appeal_issues) { nil }

        it do
          expect(subject.length).to eq(expected_array_without_legacy_appeal_issues.length)
          expected_array_without_legacy_appeal_issues.each.with_index do |expected, index|
            expect(subject[index]).to eq(expected)
          end
        end
      end
    end

    context "an empty included array is ignored" do
      let(:included) { [] }
      let(:expected_array_without_included) { expected_array[0...-9] }

      it do
        expect(subject.length).to eq(expected_array_without_included.length)
        expected_array_without_included.each.with_index do |expected, index|
          expect(subject[index]).to eq(expected)
        end
      end

      context do
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
        expected_array[0...-9] +
          [
            [object,               ["included", 0]],
            [["ContestableIssue"], ["included", 0, "type"]],
            [[Integer, nil],       ["included", 0, "attributes", "decisionIssueId"]],
            [[String, nil],        ["included", 0, "attributes", "ratingIssueId"]],
            [[String, nil],        ["included", 0, "attributes", "ratingDecisionIssueId"]],
            [[Array, nil],         ["included", 0, "attributes", "legacyAppealIssues"]],
            [object,               ["included", 1]],
            [["ContestableIssue"], ["included", 1, "type"]],
            [[Integer, nil],       ["included", 1, "attributes", "decisionIssueId"]],
            [[String, nil],        ["included", 1, "attributes", "ratingIssueId"]],
            [[String, nil],        ["included", 1, "attributes", "ratingDecisionIssueId"]],
            [[Array, nil],         ["included", 1, "attributes", "legacyAppealIssues"]],
            [object,               ["included", 2]],
            [["ContestableIssue"], ["included", 2, "type"]],
            [[Integer, nil],       ["included", 2, "attributes", "decisionIssueId"]],
            [[String, nil],        ["included", 2, "attributes", "ratingIssueId"]],
            [[String, nil],        ["included", 2, "attributes", "ratingDecisionIssueId"]],
            [[Array, nil],         ["included", 2, "attributes", "legacyAppealIssues"]],
            [object,               ["included", 3]],
            [["ContestableIssue"], ["included", 3, "type"]],
            [[Integer, nil],       ["included", 3, "attributes", "decisionIssueId"]],
            [[String, nil],        ["included", 3, "attributes", "ratingIssueId"]],
            [[String, nil],        ["included", 3, "attributes", "ratingDecisionIssueId"]],
            [[Array, nil],         ["included", 3, "attributes", "legacyAppealIssues"]],
            [object,               ["included", 4]],
            [["ContestableIssue"], ["included", 4, "type"]],
            [[Integer, nil],       ["included", 4, "attributes", "decisionIssueId"]],
            [[String, nil],        ["included", 4, "attributes", "ratingIssueId"]],
            [[String, nil],        ["included", 4, "attributes", "ratingDecisionIssueId"]],
            [[Array, nil],         ["included", 4, "attributes", "legacyAppealIssues"]],
            [object,               ["included", 5]],
            [["ContestableIssue"], ["included", 5, "type"]],
            [[Integer, nil],       ["included", 5, "attributes", "decisionIssueId"]],
            [[String, nil],        ["included", 5, "attributes", "ratingIssueId"]],
            [[String, nil],        ["included", 5, "attributes", "ratingDecisionIssueId"]],
            [[Array, nil],         ["included", 5, "attributes", "legacyAppealIssues"]],
            [object,               ["included", 2, "attributes", "legacyAppealIssues", 0]],
            [[String],             ["included", 2, "attributes", "legacyAppealIssues", 0, "legacyAppealId"]],
            [[String],             ["included", 2, "attributes", "legacyAppealIssues", 0, "legacyAppealIssueId"]],
            [object,               ["included", 2, "attributes", "legacyAppealIssues", 1]],
            [[String],             ["included", 2, "attributes", "legacyAppealIssues", 1, "legacyAppealId"]],
            [[String],             ["included", 2, "attributes", "legacyAppealIssues", 1, "legacyAppealIssueId"]],
            [object,               ["included", 4, "attributes", "legacyAppealIssues", 0]],
            [[String],             ["included", 4, "attributes", "legacyAppealIssues", 0, "legacyAppealId"]],
            [[String],             ["included", 4, "attributes", "legacyAppealIssues", 0, "legacyAppealIssueId"]],
            [object,               ["included", 4, "attributes", "legacyAppealIssues", 1]],
            [[String],             ["included", 4, "attributes", "legacyAppealIssues", 1, "legacyAppealId"]],
            [[String],             ["included", 4, "attributes", "legacyAppealIssues", 1, "legacyAppealIssueId"]],
            [object,               ["included", 4, "attributes", "legacyAppealIssues", 2]],
            [[String],             ["included", 4, "attributes", "legacyAppealIssues", 2, "legacyAppealId"]],
            [[String],             ["included", 4, "attributes", "legacyAppealIssues", 2, "legacyAppealIssueId"]],
            [object,               ["included", 4, "attributes", "legacyAppealIssues", 3]],
            [[String],             ["included", 4, "attributes", "legacyAppealIssues", 3, "legacyAppealId"]],
            [[String],             ["included", 4, "attributes", "legacyAppealIssues", 3, "legacyAppealIssueId"]],
            [object,               ["included", 4, "attributes", "legacyAppealIssues", 4]],
            [[String],             ["included", 4, "attributes", "legacyAppealIssues", 4, "legacyAppealId"]],
            [[String],             ["included", 4, "attributes", "legacyAppealIssues", 4, "legacyAppealIssueId"]],
            [object,               ["included", 5, "attributes", "legacyAppealIssues", 0]],
            [[String],             ["included", 5, "attributes", "legacyAppealIssues", 0, "legacyAppealId"]],
            [[String],             ["included", 5, "attributes", "legacyAppealIssues", 0, "legacyAppealIssueId"]]
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

  describe "#benefit_type_valid?" do
    subject { intake_params.send(:benefit_type_valid?) }

    it { is_expected.to be true }

    context do
      let(:benefit_type) { "qwerty" }

      it { is_expected.to be false }
    end

    context do
      let(:benefit_type) { "pension" }

      it { is_expected.to be false }
    end
  end

  describe "#contestable_issue_errors" do
    subject { intake_params.send(:contestable_issue_errors) }

    it { is_expected.to eq [] }

    context do
      let(:first_contestable_issue_decision_issue_id) { nil }
      let(:first_contestable_issue_rating_issue_id) { nil }
      let(:first_contestable_issue_rating_decision_issue_id) { nil }

      it { is_expected.not_to be_empty }
    end
  end

  describe "#contestable_issues" do
    subject { intake_params.send(:contestable_issues) }

    it { is_expected.not_to be_empty }
    it { expect(subject.first).to be_a Api::V3::DecisionReview::ContestableIssueParams }

    context do
      let(:included) { [] }

      it { is_expected.to be_empty }
    end
  end

  describe "#receipt_date" do
    subject { intake_params.send(:receipt_date) }

    it { is_expected.to eq receipt_date }

    context do
      let(:receipt_date) { nil }

      it { is_expected.to eq Time.zone.now.strftime("%F") }
    end
  end

  describe "#veteran_is_not_the_claimant?" do
    subject { intake_params.send(:veteran_is_not_the_claimant?) }

    it { is_expected.to be true }

    context do
      let(:claimant) { nil }

      it { is_expected.to be false }
    end

    context do
      let(:params) { 1 }

      it { is_expected.to be false }
    end
  end

  describe "#attributes" do
    subject { intake_params.send(:attributes) }

    it { expect(subject.as_json).to eq attributes.as_json }
  end

  describe "#describe_shape_error" do
    subject { intake_params.send(:describe_shape_error) }

    it { is_expected.to be nil }

    context do
      let(:params) { nil }
      it { is_expected.to eq "payload must be an object" }
    end

    context do
      let(:data) { nil }
      it { is_expected.to eq "[\"data\"] should be one of #{object.inspect}. Got: #{data.inspect}." }
    end

    context do
      let(:type) { nil }
      it { is_expected.to eq "[\"data\"][\"type\"] should be \"HigherLevelReview\". Got: #{type.inspect}." }
    end

    context do
      let(:attributes) { nil }
      it { is_expected.to eq "[\"data\"][\"attributes\"] should be one of #{object.inspect}. Got: #{attributes.inspect}." }
    end

    context do
      let(:receipt_date) { 12 }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"receiptDate\"] should be one of [String, nil]. Got: #{receipt_date.inspect}." }
    end

    context do
      let(:informal_conference) { nil }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"informalConference\"] should be one of [true, false]. Got: #{informal_conference.inspect}." }
    end

    context do
      let(:informal_conference_times) { "dog" }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"informalConferenceTimes\"] should be one of [Array, nil]. Got: #{informal_conference_times.inspect}." }
    end

    context do
      let(:informal_conference_times) { [13] }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"informalConferenceTimes\"][0] should be one of [String, nil]. Got: #{informal_conference_times[0].inspect}." }
    end

    context do
      let(:informal_conference_times) { [nil, 24] }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"informalConferenceTimes\"][1] should be one of [String, nil]. Got: #{informal_conference_times[1].inspect}." }
    end

    context do
      let(:informal_conference_times) { [nil, nil, 87] }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"informalConferenceTimes\"][2] should be nil. Got: #{informal_conference_times[2].inspect}." }
    end

    context do
      let(:informal_conference_rep) { 33 }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"informalConferenceRep\"] should be one of #{object.inspect[0...-1] + ', nil]'}. Got: #{informal_conference_rep.inspect}." }
    end

    context do
      let(:rep_name) { nil }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"informalConferenceRep\"][\"name\"] should be a(n) string. Got: #{rep_name.inspect}." }
    end

    context do
      let(:rep_phone_number) { nil }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"informalConferenceRep\"][\"phoneNumber\"] should be one of [String, Integer]. Got: #{rep_phone_number.inspect}." }
    end

    context do
      let(:rep_phone_number_country_code) { [] }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"informalConferenceRep\"][\"phoneNumberCountryCode\"] should be one of [String, Integer, nil]. Got: #{rep_phone_number_country_code.inspect}." }
    end

    context do
      let(:rep_phone_number_ext) { true }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"informalConferenceRep\"][\"phoneNumberExt\"] should be one of [String, Integer, nil]. Got: #{rep_phone_number_ext.inspect}." }
    end

    context do
      let(:same_office) { nil }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"sameOffice\"] should be one of [true, false]. Got: #{same_office.inspect}." }
    end

    context do
      let(:legacy_opt_in_approved) { nil }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"legacyOptInApproved\"] should be one of [true, false]. Got: #{legacy_opt_in_approved.inspect}." }
    end

    context do
      let(:benefit_type) { nil }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"benefitType\"] should be a(n) string. Got: #{benefit_type.inspect}." }
    end

    context do
      let(:veteran) { nil }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"veteran\"] should be one of #{object.inspect}. Got: #{veteran.inspect}." }
    end

    context do
      let(:file_number_or_ssn) { nil }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"veteran\"][\"fileNumberOrSsn\"] should be a(n) string. Got: #{file_number_or_ssn.inspect}." }
    end

    context do
      let(:vet_address_line_1) { true }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"veteran\"][\"addressLine1\"] should be one of [String, nil]. Got: #{vet_address_line_1.inspect}." }
    end

    context do
      let(:vet_address_line_2) { true }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"veteran\"][\"addressLine2\"] should be one of [String, nil]. Got: #{vet_address_line_2.inspect}." }
    end

    context do
      let(:vet_city) { true }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"veteran\"][\"city\"] should be one of [String, nil]. Got: #{vet_city.inspect}." }
    end

    context do
      let(:vet_state_province_code) { true }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"veteran\"][\"stateProvinceCode\"] should be one of [String, nil]. Got: #{vet_state_province_code.inspect}." }
    end

    context do
      let(:vet_country_code) { true }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"veteran\"][\"countryCode\"] should be one of [String, nil]. Got: #{vet_country_code.inspect}." }
    end

    context do
      let(:vet_zip_postal_code) { true }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"veteran\"][\"zipPostalCode\"] should be one of [String, nil]. Got: #{vet_zip_postal_code.inspect}." }
    end

    context do
      let(:vet_phone_number) { true }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"veteran\"][\"phoneNumber\"] should be one of [String, nil]. Got: #{vet_phone_number.inspect}." }
    end

    context do
      let(:vet_phone_number_country_code) { true }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"veteran\"][\"phoneNumberCountryCode\"] should be one of [String, nil]. Got: #{vet_phone_number_country_code.inspect}." }
    end

    context do
      let(:vet_phone_number_ext) { true }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"veteran\"][\"phoneNumberExt\"] should be one of [String, nil]. Got: #{vet_phone_number_ext.inspect}." }
    end

    context do
      let(:vet_email_address) { true }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"veteran\"][\"emailAddress\"] should be one of [String, nil]. Got: #{vet_email_address.inspect}." }
    end

    context do
      let(:claimant) { true }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"claimant\"] should be one of #{object.inspect[0...-1] + ', nil]'}. Got: #{claimant.inspect}." }
    end

    context do
      let(:participant_id) { nil }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"claimant\"][\"participantId\"] should be a(n) string. Got: #{participant_id.inspect}." }
    end

    context do
      let(:payee_code) { nil }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"claimant\"][\"payeeCode\"] should be a(n) string. Got: #{payee_code.inspect}." }
    end

    context do
      let(:claimant_address_line_1) { true }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"claimant\"][\"addressLine1\"] should be one of [String, nil]. Got: #{claimant_address_line_1.inspect}." }
    end

    context do
      let(:claimant_address_line_2) { true }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"claimant\"][\"addressLine2\"] should be one of [String, nil]. Got: #{claimant_address_line_2.inspect}." }
    end

    context do
      let(:claimant_city) { true }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"claimant\"][\"city\"] should be one of [String, nil]. Got: #{claimant_city.inspect}." }
    end

    context do
      let(:claimant_state_province_code) { true }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"claimant\"][\"stateProvinceCode\"] should be one of [String, nil]. Got: #{claimant_state_province_code.inspect}." }
    end

    context do
      let(:claimant_country_code) { true }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"claimant\"][\"countryCode\"] should be one of [String, nil]. Got: #{claimant_country_code.inspect}." }
    end

    context do
      let(:claimant_zip_postal_code) { true }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"claimant\"][\"zipPostalCode\"] should be one of [String, nil]. Got: #{claimant_zip_postal_code.inspect}." }
    end

    context do
      let(:claimant_phone_number) { true }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"claimant\"][\"phoneNumber\"] should be one of [String, nil]. Got: #{claimant_phone_number.inspect}." }
    end

    context do
      let(:claimant_phone_number_country_code) { true }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"claimant\"][\"phoneNumberCountryCode\"] should be one of [String, nil]. Got: #{claimant_phone_number_country_code.inspect}." }
    end

    context do
      let(:claimant_phone_number_ext) { true }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"claimant\"][\"phoneNumberExt\"] should be one of [String, nil]. Got: #{claimant_phone_number_ext.inspect}." }
    end

    context do
      let(:claimant_email_address) { true }
      it { is_expected.to eq "[\"data\"][\"attributes\"][\"claimant\"][\"emailAddress\"] should be one of [String, nil]. Got: #{claimant_email_address.inspect}." }
    end

    context do
      let(:included) { nil }
      it { is_expected.to eq "[\"included\"] should be a(n) array. Got: #{included.inspect}." }
    end

    context do
      let(:included) { [nil] }
      it { is_expected.to eq "[\"included\"][0] should be one of #{object.inspect}. Got: #{included[0].inspect}." }
    end

    context do
      let(:first_contestable_issue_type) { nil }
      it { is_expected.to eq "[\"included\"][0][\"type\"] should be \"ContestableIssue\". Got: #{first_contestable_issue_type.inspect}." }
    end

    context do
      let(:first_contestable_issue_decision_issue_id) { true }
      it { is_expected.to eq "[\"included\"][0][\"attributes\"][\"decisionIssueId\"] should be one of [Integer, nil]. Got: #{first_contestable_issue_decision_issue_id.inspect}." }
    end

    context do
      let(:first_contestable_issue_rating_issue_id) { true }
      it { is_expected.to eq "[\"included\"][0][\"attributes\"][\"ratingIssueId\"] should be one of [String, nil]. Got: #{first_contestable_issue_rating_issue_id.inspect}." }
    end

    context do
      let(:first_contestable_issue_rating_decision_issue_id) { true }
      it { is_expected.to eq "[\"included\"][0][\"attributes\"][\"ratingDecisionIssueId\"] should be one of [String, nil]. Got: #{first_contestable_issue_rating_decision_issue_id.inspect}." }
    end

    context do
      let(:first_contestable_issue_legacy_appeal_issues) { "dog" }
      it { is_expected.to eq "[\"included\"][0][\"attributes\"][\"legacyAppealIssues\"] should be one of [Array, nil]. Got: #{first_contestable_issue_legacy_appeal_issues.inspect}." }
    end

    context do
      let(:first_contestable_issue_legacy_appeal_issues) { [nil] }
      it { is_expected.to eq "[\"included\"][0][\"attributes\"][\"legacyAppealIssues\"][0] should be one of #{object.inspect}. Got: #{first_contestable_issue_legacy_appeal_issues[0].inspect}." }
    end

    context do
      let(:first_legacy_appeal_id) { nil }
      it { is_expected.to eq "[\"included\"][0][\"attributes\"][\"legacyAppealIssues\"][0][\"legacyAppealId\"] should be a(n) string. Got: #{first_legacy_appeal_id.inspect}." }
    end

    context do
      let(:first_legacy_appeal_issue_id) { nil }
      it { is_expected.to eq "[\"included\"][0][\"attributes\"][\"legacyAppealIssues\"][0][\"legacyAppealIssueId\"] should be a(n) string. Got: #{first_legacy_appeal_issue_id.inspect}." }
    end
  end

  describe "#shape_error_message" do
    subject { intake_params.send(:shape_error_message) }

    it { is_expected.to be nil }

    context do
      let(:params) { nil }
      it { is_expected.to eq "payload must be an object" }
    end
  end

  describe "#shape_valid?" do
    subject { intake_params.send(:shape_valid?) }

    it { is_expected.to be true }

    context do
      let(:params) { nil }
      it { is_expected.to be false  }
    end
  end

  describe "#file_number_or_ssn?" do
    subject { intake_params.file_number_or_ssn }

    it { is_expected.to eq file_number_or_ssn }

    context do
      let(:file_number_or_ssn) { 12 }
      it { is_expected.to eq "12" }
    end

    context do
      let(:file_number_or_ssn) { "  hello  " }
      it { is_expected.to eq "hello" }
    end
  end

  describe "#errors" do
    subject { intake_params.errors }

    it { is_expected.to eq [] }

    context do
      let(:params) { nil }
      it do
        expect(subject.as_json).to eq(
          [Api::V3::DecisionReview::IntakeError.new(:malformed_request, "payload must be an object").as_json]
        )
      end
    end
  end

  describe "#errors?" do
    subject { intake_params.errors? }

    it { is_expected.to be false }

    context do
      let(:params) { nil }
      it { expect(subject.as_json).to be true }
    end
  end

  describe "#complete_params" do
    subject { intake_params.complete_params }

    it do
      expect(subject.as_json).to eq(
        {
          request_issues: [
            Api::V3::DecisionReview::ContestableIssueParams.new(
              params: first_contestable_issue,
              benefit_type: benefit_type,
              legacy_opt_in_approved: legacy_opt_in_approved
            ).intakes_controller_params
          ]
        }.as_json
      )
    end

    context do
      let(:included) { included_with_lots_of_contestable_issues }

      it do
        expect(subject.as_json).to eq(
          {
            request_issues: (
              included_with_lots_of_contestable_issues.map do |contestable_issue|
                Api::V3::DecisionReview::ContestableIssueParams.new(
                  params: contestable_issue,
                  benefit_type: benefit_type,
                  legacy_opt_in_approved: legacy_opt_in_approved
                ).intakes_controller_params
              end
            )
          }.as_json
        )
      end
    end
  end
end
