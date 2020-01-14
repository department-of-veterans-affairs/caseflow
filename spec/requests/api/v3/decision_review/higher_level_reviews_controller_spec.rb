# frozen_string_literal: true

require "support/intake_helpers"

describe Api::V3::DecisionReview::HigherLevelReviewsController, :all_dbs, type: :request do
  include IntakeHelpers

  before do
    FeatureToggle.enable!(:api_v3)

    Timecop.freeze(post_ama_start_date)
  end

  after { FeatureToggle.disable!(:api_v3) }

  let!(:api_key) { ApiKey.create!(consumer_name: "ApiV3 Test Consumer").key_string }

  let(:file_number_or_ssn) { "64205050" }

  let!(:veteran) do
    Generators::Veteran.build(file_number: file_number_or_ssn,
                              first_name: "Ed",
                              last_name: "Merica")
  end

  let!(:current_user) do
    User.authenticate!(roles: ["Admin Intake"])
  end

  let(:mock_api_user) do
    val = "ABC"
    create(:user, station_id: val, css_id: val, full_name: val)
  end

  let(:response_json) { JSON.parse(response.body) }
  let(:first_error_code_in_response) { response_json["errors"][0]["code"] }

  let(:params) { ActionController::Parameters.new(data: data, included: included) }

  let(:data) { { type: "HigherLevelReview", attributes: attributes } }

  let(:attributes) { default_attributes }
  let(:default_attributes) do
    {
      receiptDate: receipt_date.strftime("%F"),
      informalConference: informal_conference,
      sameOffice: same_office,
      legacyOptInApproved: legacy_opt_in_approved,
      benefitType: benefit_type,
      veteran: {
        fileNumberOrSsn: file_number_or_ssn
      }
    }
  end

  let(:receipt_date) { Time.zone.today - 5.days }
  let(:informal_conference) { true }
  let(:same_office) { false }
  let(:legacy_opt_in_approved) { true }
  let(:benefit_type) { "compensation" }

  let(:included) do
    [
      {
        type: "ContestableIssue",
        attributes: {
          ratingIssueId: contestable_issues.first.rating_issue_reference_id,
          decisionIssueId: contestable_issues.first.decision_issue&.id,
          ratingDecisionIssueId: contestable_issues.first.rating_decision_reference_id
        }
      }
    ]
  end

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

  context do
    it { expect(contestable_issues).not_to be_empty }
  end

  describe "#create" do
    before do
      allow(User).to receive(:api_user).and_return(mock_api_user)
      before_post
      post(
        "/api/v3/decision_review/higher_level_reviews",
        params: params,
        as: :json,
        headers: { "Authorization" => "Token #{api_key}" }
      )
    end

    let(:before_post) { nil }

    let(:expected_error) { Api::V3::DecisionReview::IntakeError.new(expected_error_code) }
    let(:expected_error_render_hash) do
      Api::V3::DecisionReview::IntakeErrors.new([expected_error]).render_hash
    end
    let(:expected_error_json) { expected_error_render_hash[:json].as_json }
    let(:expected_error_status) { expected_error_render_hash[:status] }

    context "good request" do
      let(:before_post) do
        allow_any_instance_of(HigherLevelReview).to receive(:asyncable_status) { :submitted }
      end

      it "should return a 202 on success" do
        expect(response).to have_http_status(202)
      end
    end

    context "params are missing" do
      let(:params) { {} }
      let(:expected_error_code) { "malformed_request" }

      it "should return malformed_request error" do
        expect(first_error_code_in_response).to eq expected_error_code
        expect(response).to have_http_status expected_error_status
      end
    end

    context "using a reserved veteran file number while in prod" do
      let(:file_number_or_ssn) { "123456789" }
      let(:before_post) { allow(Rails).to receive(:deploy_env?).with(:prod).and_return(true) }
      let(:expected_error_code) { "reserved_veteran_file_number" }

      it "should return reserved_veteran_file_number error" do
        expect(response_json).to eq expected_error_json
        expect(response).to have_http_status expected_error_status
      end
    end
  end

  describe "#show" do
    let!(:higher_level_review) do
      processor = Api::V3::DecisionReview::HigherLevelReviewIntakeProcessor.new(
        params,
        create(:user)
      )
      processor.run!
      puts processor.errors.map(&:to_h)
      processor.higher_level_review
    end

    def get_higher_level_review # rubocop:disable Naming/AccessorMethodName
      get(
        "/api/v3/decision_review/higher_level_reviews/#{higher_level_review.uuid}",
        headers: { "Authorization" => "Token #{api_key}" }
      )
    end

    it "should return ok" do
      get_higher_level_review
      expect(response).to have_http_status(:ok)
    end

    it "should be json with a data key and included key" do
      get_higher_level_review
      json = JSON.parse(response.body)
      expect(json.keys).to include("data", "included")
    end

    let(:request_issues) do
      higher_level_review.request_issues
        .includes(:decision_review, :contested_decision_issue).active_or_ineligible_or_withdrawn
    end

    let(:decision_issues) { higher_level_review.fetch_all_decision_issues }

    context "data" do
      subject do
        get_higher_level_review
        JSON.parse(response.body)["data"]
      end

      it "should have HigherLevelReview as the type" do
        expect(subject["type"]).to eq "HigherLevelReview"
      end

      it "should have an id" do
        expect(subject["id"]).to eq higher_level_review.uuid
      end

      it "should have attributes" do
        expect(subject["attributes"]).to_not be_empty
      end

      context "attributes" do
        subject do
          get_higher_level_review
          JSON.parse(response.body)["data"]["attributes"]
        end

        it "should include status" do
          expect(subject["status"]).to eq higher_level_review.fetch_status.to_s
        end

        it "should include aoj" do
          expect(subject["aoj"]).to eq higher_level_review.aoj
        end

        it "should include programArea" do
          expect(subject["programArea"]).to eq higher_level_review.program
        end

        it "should include benefitType" do
          expect(subject["benefitType"]).to eq higher_level_review.benefit_type
        end

        it "should include description" do
          expect(subject["description"]).to eq higher_level_review.description
        end

        it "should include receiptDate" do
          expect(subject["receiptDate"]).to eq higher_level_review.receipt_date.strftime("%F")
        end

        it "should include informalConference" do
          expect(subject["informalConference"]).to eq higher_level_review.informal_conference
        end

        it "should include sameOffice" do
          expect(subject["sameOffice"]).to eq higher_level_review.same_office
        end

        it "should include legacyOptInApproved" do
          expect(subject["legacyOptInApproved"]).to eq higher_level_review.legacy_opt_in_approved
        end

        it "should include alerts" do
          expect(subject["alerts"]).to be_a Array
        end

        context "alerts" do
          subject do
            get_higher_level_review
            JSON.parse(response.body)["data"]["attributes"]["alerts"]
          end

          it "should have the same alerts" do
            higher_level_review.decision_issues << create(:decision_issue)
            higher_level_review.end_product_establishments.first.update(synced_status: "CLR")
            expect(subject.count).to eq higher_level_review.alerts.count

            higher_level_review.alerts.collect { |alert| JSON.parse(alert.to_json) }.each do |alert_data|
              expect(subject).to include(alert_data)
            end
          end
        end

        it "should include events" do
          expect(subject["events"]).to be_a Array
        end

        context "events" do
          subject do
            get_higher_level_review
            JSON.parse(response.body)["data"]["attributes"]["events"]
          end

          it "should have the same events" do
            expect(subject.count).to eq higher_level_review.events.count
            subject.each do |event_data|
              event = higher_level_review.events.find do |e|
                e.type.to_s == event_data["type"] && e.date.strftime("%Y-%m-%d") == event_data["date"]
              end
              expect(event).to_not be_nil
            end
          end
        end
      end

      it "should have relationships" do
        expect(subject["relationships"]).to_not be_empty
      end

      context "relationships" do
        subject do
          get_higher_level_review
          JSON.parse(response.body)["data"]["relationships"]
        end

        it "should include the veteran" do
          expect(subject.dig("veteran", "data", "id")).to eq higher_level_review.veteran.id.to_s
          expect(subject.dig("veteran", "data", "type")).to eq "Veteran"
        end

        it "should include the claimant" do
          expect(subject.dig("claimant", "data", "id")).to eq higher_level_review.claimant.id.to_s
          expect(subject.dig("claimant", "data", "type")).to eq "Claimant"
        end

        it "should include request issues" do
          ri_relationships = subject["requestIssues"]["data"]
          expect(ri_relationships.count).to eq request_issues.count
          expect(ri_relationships.collect { |ri| ri["id"].to_i }).to include(*request_issues.collect(&:id))
          expect(ri_relationships.collect { |ri| ri["type"] }.uniq).to eq ["RequestIssue"]
        end

        it "should include decision issues" do
          higher_level_review.decision_issues << create(:decision_issue)
          expect(subject["decisionIssues"]["data"].count).to eq decision_issues.count
          di_relationships = subject["decisionIssues"]["data"]
          expect(di_relationships.count).to eq decision_issues.count
          expect(di_relationships.collect { |di| di["id"].to_i }).to include(*decision_issues.collect(&:id))
          expect(di_relationships.collect { |di| di["type"] }.uniq).to eq ["DecisionIssue"]
        end
      end
    end

    context "included" do
      subject do
        get_higher_level_review
        JSON.parse(response.body)["included"]
      end

      it "should be an array" do
        expect(subject).to be_a Array
      end

      it "should include one veteran" do
        veteran = subject.find { |obj| obj["type"] == "Veteran" }
        expect(veteran).to_not be_nil
        expect(veteran["attributes"].keys).to include(
          "firstName", "middleName", "lastName", "nameSuffix", "fileNumber", "ssn", "participantId"
        )
      end

      it "should include a claimant" do
        claimant = subject.find { |obj| obj["type"] == "Claimant" }
        expect(claimant).to_not be_nil
        expect(claimant["attributes"].keys).to include(
          "firstName", "middleName", "lastName", "payeeCode", "relationshipType"
        )
      end

      it "should not have a claimant when one is not present" do
        higher_level_review.claimants.delete_all
        claimant = subject.find { |obj| obj["type"] == "Claimant" }
        expect(claimant).to be_nil
      end

      it "should include RequestIssues" do
        included_request_issues = subject.select { |obj| obj["type"] == "RequestIssue" }
        expect(included_request_issues.count).to eq request_issues.count
        expect(included_request_issues.first["attributes"].keys).to include(
          "active", "statusDescription", "diagnosticCode", "ratingIssueId", "ratingIssueProfileDate",
          "ratingDecisionId", "description", "contentionText", "approxDecisionDate", "category",
          "notes", "isUnidentified", "rampClaimId", "legacyAppealId", "legacyAppealIssueId",
          "decisionReviewTitle", "decisionIssueId", "withdrawalDate", "contestedIssueDescription",
          "endProductCleared", "endProductCode", "ineligible"
        )
      end

      context "RequestIssues" do
        subject do
          get_higher_level_review
          JSON.parse(response.body)["included"].select { |obj| obj["type"] == "RequestIssue" }
        end

        it "should have a null ineligible" do
          expect(subject.first["ineligible"]).to be_nil
        end

        it "should have an ineligible object" do
          request_issue_in_active_review = create(
            :request_issue,
            decision_date: Time.zone.today - 5.days,
            decision_review: create(:higher_level_review, id: 10, veteran_file_number: veteran.file_number),
            contested_rating_issue_reference_id: "hlr123",
            contention_reference_id: "2222",
            end_product_establishment: create(:end_product_establishment, :active),
            contention_removed_at: nil,
            ineligible_reason: nil
          )
          ineligible_request_issue = create(
            :request_issue,
            decision_date: Time.zone.today - 3.days,
            decision_review: create(:higher_level_review, id: 11, veteran_file_number: veteran.file_number),
            contested_rating_issue_reference_id: "hlr123",
            contention_reference_id: "3333",
            ineligible_reason: :duplicate_of_rating_issue_in_active_review,
            ineligible_due_to: request_issue_in_active_review
          )
          higher_level_review.request_issues = [request_issue_in_active_review, ineligible_request_issue]
          ineligble_data = subject.find { |ri| ri["attributes"]["ineligible"] }["attributes"]["ineligible"]

          expect(ineligble_data["reason"]).to eq ineligible_request_issue.ineligible_reason
          expect(ineligble_data["dueToId"]).to eq ineligible_request_issue.ineligible_due_to_id
          expect(ineligble_data["titleOfActiveReview"]).to eq ineligible_request_issue.title_of_active_review
        end
      end

      it "should include DecisionIssues" do
        higher_level_review.decision_issues << create(:decision_issue)
        included_decision_issues = subject.select { |obj| obj["type"] == "DecisionIssue" }
        expect(included_decision_issues.count).to eq decision_issues.count
        expect(included_decision_issues.first["attributes"].keys).to include(
          "approxDecisionDate", "decisionText", "description", "disposition", "finalized"
        )
      end
    end
  end
end
