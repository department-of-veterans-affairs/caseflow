# frozen_string_literal: true

describe Api::V3::DecisionReview::ContestableIssuesController, :postgres, type: :request do
  before { FeatureToggle.enable!(:api_v3) }
  after { FeatureToggle.disable!(:api_v3) }

  describe "#index" do
    let(:veteran) { create(:veteran) }

    let!(:api_key) do
      ApiKey.create!(consumer_name: "ApiV3 Test Consumer").key_string
    end

    def get_issues(veteran_id: veteran.file_number, receipt_date: Time.zone.today)
      get(
        "/api/v3/decision_review/contestable_issues",
        headers: {
          "Authorization" => "Token #{api_key}",
          "veteranId" => veteran_id,
          "receiptDate" => receipt_date.strftime("%Y-%m-%d")
        }
      )
    end

    it "should return a 200 OK" do
      get_issues
      expect(response).to have_http_status(:ok)
    end

    it "should return a list of issues" do
      Generators::Rating.build(
        participant_id: veteran.ptcpnt_id,
        profile_date: Time.zone.today - 10.days # must be before receipt_date
      ) # this is a contestable_rating_issues
      get_issues
      issues = JSON.parse(response.body)
      expect(issues).to be_an Array
      expect(issues.count > 0).to be true
    end

    context "returned issues" do
      let(:source) { create(:higher_level_review, veteran_file_number: veteran.file_number, same_office: false) }
      let(:end_product_establishment) do
        EndProductEstablishment.new(
          source: source,
          veteran_file_number: veteran.file_number,
          code: "030HLRR",
          payee_code: "00",
          claim_date: 14.days.ago,
          station: "397",
          reference_id: nil,
          claimant_participant_id: veteran.ptcpnt_id,
          synced_status: nil,
          committed_at: nil,
          benefit_type_code: "2",
          doc_reference_id: nil,
          development_item_reference_id: nil,
          established_at: 30.days.ago,
          user: current_user,
          limited_poa_code: "ABC",
          limited_poa_access: true
        )
      end

      let(:another_decision_issue) do
        create(
          :decision_issue,
          decision_review: source,
          rating_profile_date: source.receipt_date - 1.day,
          end_product_last_action_date: source.receipt_date - 1.day,
          benefit_type: source.benefit_type,
          participant_id: veteran.ptcpnt_id,
          decision_text: "a past decision issue from another review"
        )
      end

      let(:issues) do
        date = Time.zone.today
        Generators::Rating.build(
          participant_id: veteran.ptcpnt_id,
          associated_claims: [
            { clm_id: end_product_establishment.reference_id, bnft_clm_tc: end_product_establishment.code, ramp: true }
          ],
          decisions: [
            {
              rating_issue_reference_id: "99999",
              original_denial_date: date - 7.days,
              diagnostic_text: "Broken arm",
              diagnostic_type: "Bone",
              diagnostic_code: "CD123",
              disability_id: "123",
              disability_date: date - 3.days,
              type_name: "Not Service Connected"
            },
          ],
          issues: [
            {
              reference_id: "99999",
              decision_text: "Decision1",
              dis_sn: "rating1"
            }
          ],
          disabilities: [
            {
              dis_dt: date - 2.days,
              dis_sn: "rating1",
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
        issues = JSON.parse(response.body)
        expect(issues.count > 0).to be true
        issues
      end
      it 'should have ratingIssueId attribute' do
        issues.each do |issue|
          expect(issue["attributes"].keys).to include("ratingIssueId")
          expect(issue["attributes"]["ratingIssueId"]).to match(/^\d+$/)
        end
      end
      it 'should have ratingIssueProfileDate attribute' do
        issues.each do |issue|
          expect(issue["attributes"].keys).to include("ratingIssueProfileDate")
          expect(issue["attributes"]["ratingIssueProfileDate"]).to match(/^\d{4}-\d{2}-\d{2}$/)
        end
      end
      it 'should have ratingIssueDiagnosticCode attribute' do
        issues.each do |issue|
          expect(issue["attributes"].keys).to include("ratingIssueDiagnosticCode")
          expect(issue["attributes"]["ratingIssueDiagnosticCode"]).to match(/^\d+$/)
        end
      end
      it 'should have description attribute' do
        issues.each do |issue|
          expect(issue["attributes"].keys).to include("description")
          expect(issue["attributes"]["description"]).to match(/\b.*\b.*\b/) # has some text
        end
      end
      it 'should have isRating attribute' do
        issues.each do |issue|
          expect(issue["attributes"].keys).to include("isRating")
          expect(issue["attributes"]["isRating"]).to be_in([true, false])
        end
      end
      it 'should have latestIssuesInChain attribute' do
        issues.each do |issue|
          expect(issue["attributes"].keys).to include("latestIssuesInChain")
          expect(issue["attributes"]["latestIssuesInChain"]).to be_a Array
          expect(issue["attributes"]["latestIssuesInChain"].first.keys).to include("id", "approxDecisionDate")
        end
      end
      it 'should have decisionIssueId attribute' do
        issue_with_decision_issue = issues.find { |i| i["attributes"].keys.include?("decisionIssueId") }
        expect(issue_with_decision_issue).to be_present
        expect(issue_with_decision_issue["attributes"]["decisionIssueId"]).to be_a Integer
      end
      xit 'should have ratingDecisionId attribute' do
        issues.each do |issue|
          expect(issue["attributes"].keys).to include("ratingDecisionId")
          # This can be nil, setup rating to include a decision issue id?
          expect(issue["attributes"]["ratingDecisionId"]).to match(/^\d+$/)
        end
      end
      it 'should have approxDecisionDate attribute' do
        issues.each do |issue|
          expect(issue["attributes"].keys).to include("approxDecisionDate")
          expect(issue["attributes"]["approxDecisionDate"]).to match(/^\d{4}-\d{2}-\d{2}$/)
        end
      end
      xit 'should have rampClaimId attribute' do
        issues.each do |issue|
          expect(issue["attributes"].keys).to include("rampClaimId")
          # This can be nil, setup rating to include a decision issue id?
          expect(issue["attributes"]["rampClaimId"]).to match(/^\d+$/)
        end
      end
      xit 'should have titleOfActiveReview attribute' do
        issues.each do |issue|
          expect(issue["attributes"].keys).to include("titleOfActiveReview")
          # This can be nil, setup rating to include a decision issue id?
          expect(issue["attributes"]["titleOfActiveReview"]).to match(/^\d+$/)
        end
      end
      it 'should have sourceReviewType attribute' do
        issue_with_source_decision_review = issues.find { |i| i["attributes"].keys.include?("sourceReviewType") }
        expect(issue_with_source_decision_review).to be_present
        expect(issue_with_source_decision_review["attributes"]["sourceReviewType"]).to eq source.class.to_s
      end
      it 'should have timely attribute' do
        issues.each do |issue|
          expect(issue["attributes"].keys).to include("timely")
          expect(issue["attributes"]["timely"]).to be_in([true, false])
        end
      end
    end

    it "should return a 404 when the veteran is not found" do
      get_issues(veteran_id: "abcdefg")
      expect(response).to have_http_status(:not_found)
    end

    it "should return a 422 when the receipt date is bad" do
      get_issues(receipt_date: Time.zone.today - 1000.years)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
