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
    let(:object) { Api::V3::DecisionReview::IntakeParams::OBJECT }
    let(:bool) { Api::V3::DecisionReview::IntakeParams::BOOL }
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
        [[String],       ["data", "attributes", "informalConferenceRep name"]],
        [[String, nil],  ["data", "attributes", "informalConferenceRep phoneNumber"]],
        [[String, nil],  ["data", "attributes", "informalConferenceRep phoneNumberCountryCode"]],
        [[String, nil],  ["data", "attributes", "informalConferenceRep phoneNumberExt"]],
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
      let(:included) do
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
            [[String],             ["included", 5, "attributes", "legacyAppealIssues", 0, "legacyAppealIssueId"]],
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
end
