# frozen_string_literal: true

describe Api::V3::DecisionReview::ContestableIssuesController, :postgres, type: :request do
  before { FeatureToggle.enable!(:api_v3) }
  after do
    User.instance_variable_set(:@api_user, nil)
    FeatureToggle.disable!(:api_v3)
  end

  describe "#index" do
    let(:veteran) { create(:veteran) }

    let!(:api_key) do
      ApiKey.create!(consumer_name: "ApiV3 Test Consumer").key_string
    end

    def get_issues(ssn: veteran.ssn, receipt_date: Time.zone.today)
      date =
        if receipt_date.is_a? String
          receipt_date
        else
          receipt_date.strftime("%Y-%m-%d")
        end
      get(
        "/api/v3/decision_review/contestable_issues",
        headers: {
          "Authorization" => "Token #{api_key}",
          "X-VA-SSN" => ssn,
          "X-VA-Receipt-Date" => date || receipt_date
        }
      )
    end

    it "should return a 200 OK" do
      get_issues
      expect(response).to have_http_status(:ok)
    end

    it "should return a list of issues in JSONAPI format" do
      Generators::Rating.build(
        participant_id: veteran.ptcpnt_id,
        profile_date: Time.zone.today - 10.days # must be before receipt_date
      ) # this is a contestable_rating_issues
      get_issues
      issues = JSON.parse(response.body)["data"]
      expect(issues).to be_an Array
      expect(issues.count).to be > 0
    end

    context "returned issues" do
      let(:source) { create(:higher_level_review, veteran_file_number: veteran.file_number, same_office: false) }
      let(:claim_id) { "12345" }
      let(:rating_issue_reference_id) { "99999" }
      let(:end_product_establishment) do
        create(:end_product_establishment,
               source: source,
               veteran_file_number: veteran.file_number,
               code: "682HLRRRAMP", # "030HLRR",
               payee_code: "00",
               claim_date: 14.days.ago,
               station: "397",
               reference_id: claim_id,
               claimant_participant_id: veteran.ptcpnt_id,
               synced_status: nil,
               committed_at: nil,
               benefit_type_code: "2",
               doc_reference_id: nil,
               development_item_reference_id: nil,
               established_at: 30.days.ago,
               user: User.api_user,
               limited_poa_code: "ABC",
               limited_poa_access: true)
      end

      let(:another_decision_issue) do
        create(
          :decision_issue,
          decision_review: source,
          rating_profile_date: source.receipt_date - 1.day,
          end_product_last_action_date: source.receipt_date - 1.day,
          benefit_type: source.benefit_type,
          participant_id: veteran.ptcpnt_id,
          decision_text: "a past decision issue from another review",
          rating_issue_reference_id: "1800"
        )
      end

      let(:disability_dis_sn) { "98765" }
      let(:diagnostic_code) { "777" }
      let(:disability_id) { "123" }
      let(:issues) do
        date = Time.zone.today
        Generators::Rating.build(
          participant_id: veteran.ptcpnt_id,
          associated_claims: [
            { clm_id: end_product_establishment.reference_id, bnft_clm_tc: end_product_establishment.code }
          ],
          decisions: [
            {
              rating_issue_reference_id: rating_issue_reference_id,
              original_denial_date: date - 7.days,
              diagnostic_text: "Broken arm",
              diagnostic_type: "Bone",
              diagnostic_code: diagnostic_code,
              disability_id: disability_id,
              disability_date: date - 3.days,
              type_name: "Not Service Connected"
            }
          ],
          issues: [
            {
              reference_id: "99999",
              decision_text: "Decision1",
              dis_sn: disability_id
            }
          ],
          disabilities: [
            {
              dis_dt: date - 2.days,
              dis_sn: disability_dis_sn,
              disability_evaluations: {
                dis_dt: date - 2.days,
                dgnstc_tc: "123456"
              }
            }
          ],
          profile_date: date - 10.days # must be before receipt_date
        ) # this is a contestable_rating_issues
        another_decision_issue # instantiate this
        get_issues
        JSON.parse(response.body)["data"]
      end

      it "should have ratingIssueId attribute" do
        issue_with_rating_issue = issues.find { |i| i["attributes"].key?("ratingIssueId") }
        expect(issue_with_rating_issue).to be_present
        expect(issue_with_rating_issue["attributes"]["ratingIssueId"]).to match(/^\d+$/)
      end

      it "should have ratingIssueProfileDate attribute" do
        issues.each do |issue|
          expect(issue["attributes"].keys).to include("ratingIssueProfileDate")
          expect(issue["attributes"]["ratingIssueProfileDate"]).to match(/^\d{4}-\d{2}-\d{2}$/)
        end
      end

      it "should have ratingIssueDiagnosticCode attribute" do
        issue_with_rating_issue = issues.find { |i| i["attributes"].key?("ratingIssueDiagnosticCode") }
        expect(issue_with_rating_issue).to be_present
        expect(issue_with_rating_issue["attributes"]["ratingIssueDiagnosticCode"]).to eq diagnostic_code
      end

      it "should have description attribute" do
        issues.each do |issue|
          expect(issue["attributes"].keys).to include("description")
          expect(issue["attributes"]["description"]).to match(/\b.*\b.*\b/) # has some text
        end
      end

      it "should have isRating attribute" do
        issues.each do |issue|
          expect(issue["attributes"].keys).to include("isRating")
          expect(issue["attributes"]["isRating"]).to be_in([true, false])
        end
      end

      it "should have latestIssuesInChain attribute" do
        issues.each do |issue|
          expect(issue["attributes"].keys).to include("latestIssuesInChain")
          expect(issue["attributes"]["latestIssuesInChain"]).to be_a Array
          expect(issue["attributes"]["latestIssuesInChain"].count).to be > 0
          issue["attributes"]["latestIssuesInChain"].each do |latest_issues|
            expect(latest_issues.keys).to include("id", "approxDecisionDate")
          end
        end
      end

      it "should have decisionIssueId attribute" do
        issue_with_decision_issue = issues.find do |issue|
          issue["attributes"].key?("decisionIssueId") && issue["attributes"]["decisionIssueId"]
        end
        expect(issue_with_decision_issue).to be_present
        expect(issue_with_decision_issue["attributes"]["decisionIssueId"]).to be_a Integer
      end

      context "with contestable rating decisions enabled" do
        before { FeatureToggle.enable!(:contestable_rating_decisions) }
        after { FeatureToggle.disable!(:contestable_rating_decisions) }

        it "should have ratingDecisionId attribute" do
          issue_with_rating_decision = issues.find do |issue|
            issue["attributes"].key?("ratingDecisionId") && issue["attributes"]["ratingDecisionId"]
          end
          expect(issue_with_rating_decision).to be_present
          expect(issue_with_rating_decision["attributes"]["ratingDecisionId"]).to eq disability_dis_sn
        end
      end

      it "should have approxDecisionDate attribute" do
        issues.each do |issue|
          expect(issue["attributes"].keys).to include("approxDecisionDate")
          expect(issue["attributes"]["approxDecisionDate"]).to match(/^\d{4}-\d{2}-\d{2}$/)
        end
      end

      it "should have rampClaimId attribute" do
        issue_with_rating_issue = issues.find { |i| i["attributes"].key?("rampClaimId") }
        expect(issue_with_rating_issue).to be_present
        expect(issue_with_rating_issue["attributes"]["rampClaimId"]).to eq claim_id.to_s
      end

      it "should have titleOfActiveReview attribute" do
        decision_review = create(:supplemental_claim, veteran_file_number: veteran.file_number)
        create(
          :request_issue,
          decision_review: decision_review,
          contested_rating_issue_reference_id: rating_issue_reference_id
        )
        issue_with_rating_issue = issues.find { |i| i["attributes"].key?("titleOfActiveReview") }
        expect(issue_with_rating_issue).to be_present
        expect(issue_with_rating_issue["attributes"]["titleOfActiveReview"]).to eq decision_review.class.review_title
      end

      it "should have sourceReviewType attribute" do
        issue_with_source_decision_review = issues.find do |issue|
          issue["attributes"].key?("sourceReviewType") && issue["attributes"]["sourceReviewType"]
        end
        expect(issue_with_source_decision_review).to be_present
        expect(issue_with_source_decision_review["attributes"]["sourceReviewType"]).to eq source.class.to_s
      end

      it "should have timely attribute" do
        issues.each do |issue|
          expect(issue["attributes"].keys).to include("timely")
          expect(issue["attributes"]["timely"]).to be_in([true, false])
        end
      end
    end

    it "should return a 404 when the veteran is not found" do
      get_issues(ssn: "abcdefg")
      expect(response).to have_http_status(:not_found)
    end

    it "should return a 422 when the receipt is before AMA" do
      get_issues(receipt_date: Time.zone.today - 1000.years)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "should return a 422 when the receipt date after today" do
      get_issues(receipt_date: Time.zone.tomorrow)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "should return a 422 when the receipt date is not ISO 8601 date format" do
      get_issues(receipt_date: "January 8")
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
