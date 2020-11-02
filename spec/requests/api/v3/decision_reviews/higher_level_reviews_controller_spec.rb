# frozen_string_literal: true

require "support/intake_helpers"

describe Api::V3::DecisionReviews::HigherLevelReviewsController, :all_dbs, type: :request do
  include IntakeHelpers

  before do
    FeatureToggle.enable!(:api_v3_higher_level_reviews)

    Timecop.freeze(post_ama_start_date)
  end

  after { FeatureToggle.disable!(:api_v3_higher_level_reviews) }

  let!(:rating) do
    promulgation_date = receipt_date - 10.days
    profile_date = (receipt_date - 8.days).to_datetime
    generate_rating(veteran, promulgation_date, profile_date)
  end

  let(:authorization_header) do
    api_key = ApiKey.create!(consumer_name: "ApiV3 Test Consumer").key_string
    { "Authorization" => "Token #{api_key}" }
  end

  let(:veteran_ssn) { "642152050" }

  let(:veteran) { create(:veteran, ssn: veteran_ssn) }

  let(:current_user) do
    User.authenticate!(roles: ["Admin Intake"])
  end

  let(:mock_api_user) do
    val = "ABC"
    create(:user, station_id: val, css_id: val, full_name: val)
  end

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
        ssn: veteran.ssn
      }
    }
  end

  let(:receipt_date) { Time.zone.today - 5.days }
  let(:informal_conference) { false }
  let(:same_office) { false }
  let(:legacy_opt_in_approved) { true }
  let(:benefit_type) { "compensation" }

  let(:included) do
    [
      {
        type: "ContestableIssue",
        attributes: {
          issue: "Left Knee",
          decisionDate: "2020-04-01",
          ratingIssueReferenceId: contestable_issues.first.rating_issue_reference_id
        }
      }
    ]
  end

  let(:contestable_issues) do
    ContestableIssueGenerator.new(
      HigherLevelReview.new(
        veteran_file_number: veteran.file_number,
        receipt_date: receipt_date,
        benefit_type: benefit_type
      )
    ).contestable_issues
  end

  context "contestable_issues" do
    it { expect(contestable_issues).not_to be_empty }
  end

  describe "#create" do
    before do
      allow(User).to receive(:api_user).and_return(mock_api_user)
    end

    def post_create(parameters = params)
      post(
        "/api/v3/decision_reviews/higher_level_reviews",
        params: parameters,
        as: :json,
        headers: authorization_header
      )
    end

    let(:expected_error) { Api::V3::DecisionReviews::IntakeError.new(expected_error_code) }
    let(:expected_error_render_hash) do
      Api::V3::DecisionReviews::IntakeErrors.new([expected_error]).render_hash
    end
    let(:expected_error_json) { expected_error_render_hash[:json].as_json }
    let(:expected_error_status) { expected_error_render_hash[:status] }

    context "when feature toggle is not enabled" do
      before { FeatureToggle.disable!(:api_v3_higher_level_reviews) }

      it "should return a 501 response" do
        allow_any_instance_of(HigherLevelReview).to receive(:asyncable_status) { :submitted }
        post_create
        expect(response).to have_http_status(:not_implemented)
      end

      it "should have a jsonapi error response" do
        allow_any_instance_of(HigherLevelReview).to receive(:asyncable_status) { :submitted }
        post_create
        expect { JSON.parse(response.body) }.to_not raise_error
        parsed_response = JSON.parse(response.body)
        expect(parsed_response["errors"]).to be_a Array
        expect(parsed_response["errors"].first).to include("status", "title", "detail")
      end
    end

    context "good request" do
      it "should return a 202 on success" do
        allow_any_instance_of(HigherLevelReview).to receive(:asyncable_status) { :submitted }
        post_create
        expect(response).to have_http_status(202)
      end
    end

    context "params are missing" do
      let(:expected_error_code) { "malformed_request" }

      it "should return malformed_request error" do
        post_create({})
        first_error_code_in_response = JSON.parse(response.body)["errors"][0]["code"]
        expect(first_error_code_in_response).to eq expected_error_code
        expect(response).to have_http_status expected_error_status
      end
    end

    context "using a reserved veteran file number while in prod" do
      let(:expected_error_code) { "reserved_veteran_file_number" }

      it "should return reserved_veteran_file_number error" do
        allow_any_instance_of(IntakeStartValidator).to receive(:file_number_reserved?).and_return(true)
        post_create
        response_body = JSON.parse(response.body)
        expect(response_body).to eq expected_error_json
        expect(response).to have_http_status expected_error_status
      end
    end
  end

  context(
    "given a contestable issue that only has ID fields," \
    " request issues were correctly populated in DB (contestable issue" \
    " was properly looked up during create)"
  ) do
    it do
      allow(User).to receive(:api_user).and_return(mock_api_user)

      post(
        "/api/v3/decision_reviews/higher_level_reviews",
        params: params,
        as: :json,
        headers: authorization_header
      )
      uuid = JSON.parse(response.body)["data"]["id"]

      get(
        "/api/v3/decision_reviews/higher_level_reviews/#{uuid}",
        headers: authorization_header
      )

      request_issue = JSON.parse(response.body)["included"].find { |obj| obj["type"] == "RequestIssue" }["attributes"]
      rating_issue = rating.issues.find { |issue| issue.reference_id == request_issue["ratingIssueId"] }

      expect(request_issue["description"]).to eq rating_issue.decision_text
    end
  end

  describe "#show" do
    let(:higher_level_review) do
      processor = Api::V3::DecisionReviews::HigherLevelReviewIntakeProcessor.new(
        params,
        create(:user)
      )
      processor.run!
      processor.higher_level_review
    end

    def get_higher_level_review # rubocop:disable Naming/AccessorMethodName
      get(
        "/api/v3/decision_reviews/higher_level_reviews/#{higher_level_review.uuid}",
        headers: authorization_header
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

        context "HLR has ineligible request issues" do
          let(:contested_issue_id) { "hlr123" }
          let!(:request_issue_in_active_review) do
            create(
              :request_issue,
              decision_date: Time.zone.today - 5.days,
              decision_review: create(:higher_level_review, veteran_file_number: veteran.file_number),
              contested_rating_issue_reference_id: contested_issue_id,
              contention_reference_id: "2222",
              contention_removed_at: nil,
              ineligible_reason: nil
            )
          end
          let!(:ineligible_request_issue) do
            create(
              :request_issue,
              decision_date: Time.zone.today - 3.days,
              decision_review: higher_level_review,
              contested_rating_issue_reference_id: contested_issue_id,
              contention_reference_id: "3333",
              ineligible_reason: :duplicate_of_rating_issue_in_active_review,
              ineligible_due_to: request_issue_in_active_review
            )
          end

          it "should flag ineligible request issues" do
            ineligble_data = subject.find { |ri| ri["attributes"]["ineligible"] }["attributes"]["ineligible"]

            expect(ineligble_data["reason"]).to eq ineligible_request_issue.ineligible_reason
            expect(ineligble_data["dueToId"]).to eq ineligible_request_issue.ineligible_due_to_id
            expect(ineligble_data["titleOfActiveReview"]).to eq ineligible_request_issue.title_of_active_review
          end
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
