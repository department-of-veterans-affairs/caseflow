# frozen_string_literal: true

require "test_prof/recipes/rspec/let_it_be"

# rubocop:disable Layout/LineLength
# rubocop:disable Lint/ParenthesesAsGroupedExpression
describe Api::V3::Issues::Legacy::VeteransController, :postgres, type: :request do
  let_it_be(:api_key) do
    ApiKey.create!(consumer_name: "ApiV3 Test VBMS Consumer").key_string
  end

  let_it_be(:authorization_header) do
    { "Authorization" => "Token #{api_key}" }
  end

  describe "#show" do
    context "when feature is not enabled" do
      let!(:vet) { create(:veteran) }

      it "should return 'Not Implemented' error" do
        FeatureToggle.disable!(:api_v3_legacy_issues)
        get(
          "/api/v3/issues/legacy/find_by_veteran/#{vet.participant_id}",
          headers: authorization_header
        )
        expect(response).to have_http_status(501)
        expect(response.body).to include("Not Implemented")
      end
    end

    context "when feature is enabled" do
      before { FeatureToggle.enable!(:api_v3_legacy_issues) }
      after { FeatureToggle.disable!(:api_v3_legacy_issues) }

      context "when a veteran is not found" do
        it "should return veteran not found error" do
          get(
            "/api/v3/issues/legacy/find_by_veteran/9999999999",
            headers: authorization_header
          )
          expect(response).to have_http_status(404)
          expect(response.body).to include("No Veteran found for the given identifier")
        end
      end

      context "when a veteran is found" do
        context "when a veteran has no legacy issues(s)" do
          let(:vet) { create(:veteran) }
          it "should return a 204 status" do
            get(
              "/api/v3/issues/legacy/find_by_veteran/#{vet.participant_id}",
              headers: authorization_header
            )
            # expect(response).to have_http_status(202)
            # expect(response.body).to include("No VACOLS Issues found for the given veteran")

            expect(response).to have_http_status(200)
            response_hash = JSON.parse(response.body)
          end
        end

        context "when a veteran has legacy issues(s)" do
          let!(:veteran_with_legacy_issues) {create(:veteran, file_number: "123456789")}
          let!(:veteran_file_number_legacy) {"123456789S"}
          let!(:vacols_id) {"LEGACYID"}
          before do
            12.times do
              create(:case_issue,
                isskey: vacols_id,
                issprog: "02",
                isscode: "15",
                isslev1: "04")
            end
          end
          let!(:case_issues) {VACOLS::CaseIssue.where(isskey: vacols_id)}
          let!(:vacols_case) do
            create(:case_with_soc, :status_advance, case_issues: case_issues, bfkey: vacols_id, bfcorlid: veteran_file_number_legacy)
          end
          let!(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }

          it "should return all their issues" do
            expect(case_issues.count).to eq(12)
            get(
              "/api/v3/issues/legacy/find_by_veteran/#{veteran_with_legacy_issues.participant_id}",
              headers: authorization_header
            )
            expect(response).to have_http_status(200)
            response_hash = JSON.parse(response.body)
            expect(response_hash["veteran_participant_id"]).to eq veteran_with_legacy_issues.participant_id
            expect(response_hash["total_vacols_issues_for_vet"]).to eq(12)
            expect(response_hash["total_number_of_pages"]).to eq(2)
            # byebug
          end
        end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
# rubocop:enable Lint/ParenthesesAsGroupedExpression
