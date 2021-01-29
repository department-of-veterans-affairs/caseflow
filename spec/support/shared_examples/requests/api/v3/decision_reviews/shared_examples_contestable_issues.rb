# frozen_string_literal: true

RSpec.shared_examples "contestable issues index requests" do
  include_context "contestable issues request context", include_shared: true

  describe "#index" do
    include_context "contestable issues request index context", include_shared: true

    let(:promulgated_ratings) do
      Generators::PromulgatedRating.build(
        participant_id: veteran.ptcpnt_id,
        profile_date: Time.zone.today - 10.days # must be before receipt_date
      )
    end

    context "when SSN is used" do
      let(:file_number) { nil }
      let(:ssn) { veteran.ssn }

      it "should return 200 OK" do
        get_issues
        expect(response).to have_http_status(:ok)
      end

      it "should return a list of issues in JSON:API format" do
        promulgated_ratings
        get_issues
        expect(response_data).to be_an Array
        expect(response_data).not_to be_empty
      end
    end

    context "when file_number is used" do
      let(:file_number) { veteran.file_number }
      let(:ssn) { nil }

      it "should return 200 OK" do
        get_issues
        expect(response).to have_http_status(:ok)
      end

      it "should return a list of issues in JSON:API format" do
        promulgated_ratings
        get_issues
        expect(response_data).to be_an Array
        expect(response_data).not_to be_empty
      end
    end

    context "returned issues" do
      let(:claim_id) { "12345" }
      let(:rating_issue_reference_id) { "99999" }

      let(:end_product_establishment) do
        create(
          :end_product_establishment,
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
          limited_poa_access: true
        )
      end

      let(:another_decision_issue) do
        args = {
          decision_review: source,
          rating_profile_date: source.receipt_date - 1.day,
          end_product_last_action_date: source.receipt_date - 1.day,
          participant_id: veteran.ptcpnt_id,
          decision_text: "a past decision issue from another review",
          rating_issue_reference_id: "1800"
        }
        args[:benefit_type] = source.benefit_type if source.class.to_s != "Appeal"
        create :decision_issue, args
      end

      let(:disability_dis_sn) { "98765" }
      let(:diagnostic_code) { "777" }
      let(:disability_id) { "123" }
      let(:dgnstc_tc) { "123456" }

      let(:issues) do
        date = Time.zone.today
        Generators::PromulgatedRating.build(
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
              reference_id: rating_issue_reference_id,
              decision_text: "Service connection for Broken index finger is granted with an evaluation of 20 percent.",
              dis_sn: disability_dis_sn,
              subject_text: "Broken index finger"
            }
          ],
          disabilities: [
            {
              dis_dt: date - 2.days,
              dis_sn: disability_dis_sn,
              disability_evaluations: {
                dis_dt: date - 2.days,
                dgnstc_tc: dgnstc_tc,
                prcnt_no: "20"
              }
            }
          ],
          profile_date: date - 10.days # must be before receipt_date
        ) # this is a contestable_rating_issues
        another_decision_issue # instantiate this
        get_issues
        response_data
      end

      it "should have ratingIssueReferenceId attribute" do
        issue_with_rating_issue = issues.find { |i| i["attributes"].key?("ratingIssueReferenceId") }
        expect(issue_with_rating_issue).to be_present
        expect(issue_with_rating_issue["attributes"]["ratingIssueReferenceId"]).to match(/^\d+$/)
      end

      it "should have ratingIssueSubjectText attribute" do
        issue_with_subject_text = issues.find { |i| i["attributes"].key?("ratingIssueSubjectText") }
        expect(issue_with_subject_text).to be_present
        expect(issue_with_subject_text["attributes"]["ratingIssueSubjectText"]).to be_a String
      end

      it "should have ratingIssuePercentNumber attribute" do
        issue_with_percent_number = issues.find { |i| i["attributes"].key?("ratingIssuePercentNumber") }
        expect(issue_with_percent_number).to be_present
        expect(issue_with_percent_number["attributes"]["ratingIssuePercentNumber"]).to match(/^\d+$/)
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
        expect(issue_with_rating_issue["attributes"]["ratingIssueDiagnosticCode"]).to eq dgnstc_tc
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

        it "should not have ratingDecisionReferenceId attribute" do
          issue_with_rating_decision = issues.find do |issue|
            issue["attributes"].key?("ratingDecisionReferenceId") && issue["attributes"]["ratingDecisionReferenceId"]
          end
          expect(issue_with_rating_decision).not_to be_present
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

    context do
      let(:ssn) { "Hi!" }
      let(:x) { "Hi!" }
      it "should return a 422 when the veteran SSN is not formatted correctly" do
        get_issues
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context do
      let(:ssn) { "000000000" }
      it "should return a 404 when the veteran is not found" do
        get_issues
        expect(response).to have_http_status(:not_found)
      end
    end

    context do
      let(:receipt_date) { "Hello!" }
      it "should return a 422 when the receipt date isn't a date" do
        get_issues
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context do
      let(:receipt_date) { Time.zone.today - 1000.years }
      it "should return a 422 when the receipt is before AMA" do
        get_issues
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context do
      let(:receipt_date) { Time.zone.tomorrow }
      it "should return a 422 when the receipt date is in the future" do
        get_issues
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context do
      let(:receipt_date) { "January 8" }
      it "should return a 422 when the receipt date is not ISO 8601 date format" do
        get_issues
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when no ssn or file_number is present" do
      let(:ssn) { nil }
      let(:file_number) { nil }

      it "should return a 422" do
        get_issues
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
