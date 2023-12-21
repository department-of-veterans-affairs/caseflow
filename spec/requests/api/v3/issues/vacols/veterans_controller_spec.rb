# frozen_string_literal: true

require "test_prof/recipes/rspec/let_it_be"

# rubocop:disable Layout/LineLength
describe Api::V3::Issues::Vacols::VeteransController, :postgres, type: :request do
  let_it_be(:api_key) do
    ApiKey.create!(consumer_name: "ApiV3 Test VBMS Consumer").key_string
  end

  let_it_be(:authorization_token) do
    "Token #{api_key}"
  end

  describe "#show" do
    context "when feature is not enabled" do
      let!(:vet) { create(:veteran) }

      it "should return 'Not Implemented' error" do
        FeatureToggle.disable!(:api_v3_vacols_issues)

        get_vacols_issues(file_number: vet.file_number)
        expect(response).to have_http_status(501)
        expect(response.body).to include("Not Implemented")
      end
    end

    context "when feature is enabled" do
      before { FeatureToggle.enable!(:api_v3_vacols_issues) }
      after { FeatureToggle.disable!(:api_v3_vacols_issues) }

      context "when no ApiKey is provided" do
        it "returns a 401 error" do
          get_vacols_issues(auth_token: nil)

          expect(response).to have_http_status(401)
        end
      end

      context "when no file_number provided" do
        it "returns a 422 error" do
          get_vacols_issues
          errors = JSON.parse(response.body)["errors"][0]

          expect(errors["status"]).to eq 422
          expect(errors["title"]).to eq "Veteran file number header is required"
        end
      end

      context "when a veteran is not found" do
        it "should return veteran not found error" do
          get_vacols_issues(file_number: 999_999_999_9)
          expect(response).to have_http_status(404)
          expect(response.body).to include("No Veteran found for the given identifier")
        end

        it "should return 404 error for non happy paths" do
          get_vacols_issues(file_number: 87)
          expect(response).to have_http_status(404)

          get_vacols_issues(file_number: 123_456_789_876_543_21)
          expect(response).to have_http_status(404)

          get_vacols_issues(file_number: "fakevet")
          expect(response).to have_http_status(404)
        end
      end

      context "when a veteran is found" do
        context "when a veteran has no legacy issues(s)" do
          let(:vet) { create(:veteran) }
          it "should return a success status and an empty list of Issues" do
            get_vacols_issues(file_number: vet.file_number)

            expect(response).to have_http_status(200)
            response_hash = JSON.parse(response.body)
            expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
            expect(response_hash["total_vacols_issues_for_vet"]).to eq(0)
            expect(response_hash["total_number_of_pages"]).to eq(0)
          end
        end

        context "when a veteran is found - but an unexpected error has happened." do
          before { Api::V3::Issues::Vacols::VeteransController::DEFAULT_UPPER_BOUND_PER_PAGE = "breaking_the_api" }
          after { Api::V3::Issues::Vacols::VeteransController::DEFAULT_UPPER_BOUND_PER_PAGE = 50 }
          let(:vet) { create(:veteran) }
          it "should return 500 error" do
            headers = { "Authorization": authorization_token, "X-VA-File-Number": vet.file_number }
            get("/api/v3/issues/vacols/find_by_veteran?page=1&per_page=40", headers: headers)
            expect(response).to have_http_status(500)
            expect(response.body.include?("Use the error uuid to submit a support ticket")).to eq true
          end
        end

        context "when veterans have legacy issues(s)" do
          let!(:veteran_with_legacy_issues) { create(:veteran, file_number: "123456789") }
          let!(:veteran_file_number_legacy) { "123456789S" }
          let!(:vacols_id) { "LEGACYID" }
          before do
            12.times do
              create(:case_issue,
                     isskey: vacols_id,
                     issprog: "02",
                     isscode: "15",
                     isslev1: "04")
            end
          end
          let!(:case_issues) { VACOLS::CaseIssue.where(isskey: vacols_id) }
          let!(:vacols_case) do
            create(:case_with_soc, :status_advance, case_issues: case_issues, bfkey: vacols_id, bfcorlid: veteran_file_number_legacy)
          end
          let!(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }

          # Create Veteran with 2 Legacy Appeals
          let!(:veteran_with_multiple_legacy_appeals) { create(:veteran, file_number: "222222222") }
          let!(:veteran_file_number_legacy2) { "222222222S" }
          let!(:vacols_id2) { "LEGACYID2" }
          let!(:vacols_id3) { "LEGACYID3" }
          before do
            7.times do
              create(:case_issue,
                     isskey: vacols_id2,
                     issprog: "02",
                     isscode: "15",
                     isslev1: "04")
            end
            7.times do
              create(:case_issue,
                     isskey: vacols_id3,
                     issprog: "02",
                     isscode: "15",
                     isslev1: "04")
            end
          end
          let!(:case_issues2) { VACOLS::CaseIssue.where(isskey: vacols_id2) }
          let!(:case_issues3) { VACOLS::CaseIssue.where(isskey: vacols_id3) }
          let!(:vacols_case2) do
            create(:case_with_soc, :status_advance, case_issues: case_issues2, bfkey: vacols_id2, bfcorlid: veteran_file_number_legacy2)
          end
          let!(:vacols_case3) do
            create(:case_with_soc, :status_advance, case_issues: case_issues3, bfkey: vacols_id3, bfcorlid: veteran_file_number_legacy2)
          end
          let!(:appeal2) { create(:legacy_appeal, vacols_case: vacols_case2) }
          let!(:appeal3) { create(:legacy_appeal, vacols_case: vacols_case3) }

          it "the standard API call should return all their Issues if a Veteran only has 1 Legacy Appeal" do
            expect(case_issues.count).to eq(12)

            get_vacols_issues(file_number: veteran_with_legacy_issues.file_number)
            expect(response).to have_http_status(200)
            response_hash = JSON.parse(response.body)
            expect(response_hash["veteran_participant_id"]).to eq veteran_with_legacy_issues.participant_id
            expect(response_hash["total_vacols_issues_for_vet"]).to eq(12)
            expect(response_hash["total_number_of_pages"]).to eq(2)
          end

          it "the standard API call should return all Issues across all Legacy Appeals for a given Veteran" do
            get_vacols_issues(file_number: veteran_with_multiple_legacy_appeals.file_number)
            expect(response).to have_http_status(200)
            response_hash = JSON.parse(response.body)
            expect(response_hash["veteran_participant_id"]).to eq veteran_with_multiple_legacy_appeals.participant_id
            expect(response_hash["total_vacols_issues_for_vet"]).to eq(14)
            expect(response_hash["total_number_of_pages"]).to eq(2)
          end

          it "API call works when you pass in a page param" do
            headers = { "Authorization": authorization_token, "X-VA-File-Number": veteran_with_multiple_legacy_appeals.file_number }
            get("/api/v3/issues/vacols/find_by_veteran?page=1", headers: headers)
            response_hash = JSON.parse(response.body)
            expect(response).to have_http_status(200)
            expect(response_hash["total_vacols_issues_for_vet"]).to eq(14)
            expect(response_hash["total_number_of_pages"]).to eq(2)
            expect(response_hash["vacols_issues"].count).to eq(10)
          end

          it "API call returns the last page when you pass in a page param that exceeds it" do
            headers = { "Authorization": authorization_token, "X-VA-File-Number": veteran_with_multiple_legacy_appeals.file_number }
            get("/api/v3/issues/vacols/find_by_veteran?page=9", headers: headers)
            response_hash = JSON.parse(response.body)
            expect(response).to have_http_status(200)
            expect(response_hash["total_vacols_issues_for_vet"]).to eq(14)
            expect(response_hash["page"]).to eq(2)
            expect(response_hash["total_number_of_pages"]).to eq(2)
            expect(response_hash["vacols_issues"].count).to eq(4)
          end

          it "API call works when you pass in a page and per_page param" do
            headers = { "Authorization": authorization_token, "X-VA-File-Number": veteran_with_multiple_legacy_appeals.file_number }
            get("/api/v3/issues/vacols/find_by_veteran?page=1&per_page=4", headers: headers)
            response_hash = JSON.parse(response.body)
            expect(response).to have_http_status(200)
            expect(response_hash["total_vacols_issues_for_vet"]).to eq(14)
            expect(response_hash["total_number_of_pages"]).to eq(4)
            expect(response_hash["vacols_issues"].count).to eq(4)
          end

          it "API call returns a maximum of 50 issues when you pass in a per_page param thats over the upper_limit of 50" do
            headers = { "Authorization": authorization_token, "X-VA-File-Number": veteran_with_multiple_legacy_appeals.file_number }
            get("/api/v3/issues/vacols/find_by_veteran?page=1&per_page=100", headers: headers)
            response_hash = JSON.parse(response.body)
            expect(response).to have_http_status(200)
            expect(response_hash["total_vacols_issues_for_vet"]).to eq(14)
            expect(response_hash["total_number_of_pages"]).to eq(1)
            expect(response_hash["vacols_issues"].count).to eq(14)
            expect(response_hash["max_vacols_issues_per_page"]).to eq(50)
          end

          it "API call returns the default max issues when you pass in a per_page param of 0" do
            headers = { "Authorization": authorization_token, "X-VA-File-Number": veteran_with_multiple_legacy_appeals.file_number }
            get("/api/v3/issues/vacols/find_by_veteran?page=1&per_page=0", headers: headers)
            response_hash = JSON.parse(response.body)
            expect(response).to have_http_status(200)
            expect(response_hash["total_vacols_issues_for_vet"]).to eq(14)
            expect(response_hash["total_number_of_pages"]).to eq(2)
            expect(response_hash["vacols_issues"].count).to eq(10)
            expect(response_hash["max_vacols_issues_per_page"]).to eq(10)
          end
        end
      end
    end

    def get_vacols_issues(auth_token: authorization_token, file_number: nil)
      headers = { "Authorization": auth_token, "X-VA-File-Number": file_number }

      get("/api/v3/issues/vacols/find_by_veteran", headers: headers)
    end
  end
end
# rubocop:enable Layout/LineLength
