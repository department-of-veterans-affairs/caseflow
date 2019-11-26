# frozen_string_literal: true

require "support/database_cleaner"

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
      let(:issues) do
        Generators::Rating.build(
          participant_id: veteran.ptcpnt_id,
          decisions: [
            {
              rating_issue_reference_id: nil,
              original_denial_date: Time.zone.today - 7.days,
              diagnostic_text: "Broken arm",
              diagnostic_type: "Bone",
              diagnostic_code: "CD123",
              disability_id: "123",
              disability_date: Time.zone.today - 3.days,
              type_name: "Not Service Connected"
            }
          ],
          profile_date: Time.zone.today - 10.days # must be before receipt_date
        ) # this is a contestable_rating_issues
        # byebug # need a dis_sn in rating issue part
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
      # fit 'should have ratingIssueDiagnosticCode attribute' do
      #   issues.each do |issue|
      #     expect(issue["attributes"].keys).to include("ratingIssueDiagnosticCode")
      #     expect(issue["attributes"]["ratingIssueDiagnosticCode"]).to match(/^\d+$/)
      #   end
      # end
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
      xit 'should have decisionIssueId attribute' do
        issues.each do |issue|
          expect(issue["attributes"].keys).to include("decisionIssueId")
          # This can be nil, setup rating to include a decision issue id?
          expect(issue["attributes"]["decisionIssueId"]).to match(/^\d+$/)
        end
      end
      it "should have meaningful attributes"
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
