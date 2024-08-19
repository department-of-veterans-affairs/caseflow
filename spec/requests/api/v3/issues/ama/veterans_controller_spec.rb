# frozen_string_literal: true

require "test_prof/recipes/rspec/let_it_be"

# rubocop:disable Layout/LineLength
describe Api::V3::Issues::Ama::VeteransController, :postgres, type: :request do
  let_it_be(:api_key) do
    ApiKey.create!(consumer_name: "ApiV3 Test VBMS Consumer").key_string
  end

  let_it_be(:authorization_header) do
    { "Authorization" => "Token #{api_key}" }
  end

  RequestIssue::DEFAULT_UPPER_BOUND_PER_PAGE = 50

  describe "#show" do
    context "when feature is not enabled" do
      before { FeatureToggle.disable!(:api_v3_ama_issues) }
      let!(:vet) { create(:veteran) }

      it "should return 'Not Implemented' error" do
        get(
          "/api/v3/issues/ama/find_by_veteran/#{vet.participant_id}",
          headers: authorization_header
        )
        expect(response).to have_http_status(501)
        expect(response.body).to include("Not Implemented")
      end
    end

    context "when feature is enabled" do
      before do
        FeatureToggle.enable!(:api_v3_ama_issues)
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:info)
      end
      after { FeatureToggle.disable!(:api_v3_ama_issues) }

      context "when the api key is missing in the header" do
        let!(:vet) { create(:veteran) }

        it "should return 'Unauthorized' error" do
          get(
            "/api/v3/issues/ama/find_by_veteran/#{vet.participant_id}"
          )
          expect(response).to have_http_status(401)
          expect(response.body).to include("unauthorized")
        end
      end

      context "when the incorrect api key is present in the header" do
        let!(:vet) { create(:veteran) }
        authorization_header = { "Authorization" => "Token 99999999999900000000999999998888111000" }

        it "should return 'Unauthorized' error" do
          get(
            "/api/v3/issues/ama/find_by_veteran/#{vet.participant_id}",
            headers: authorization_header
          )
          expect(response).to have_http_status(401)
          expect(response.body).to include("unauthorized")
        end
      end

      context "when a veteran is not found" do
        it "should return veteran not found error" do
          get(
            "/api/v3/issues/ama/find_by_veteran/9999999999",
            headers: authorization_header
          )
          expect(response).to have_http_status(404)
          expect(response.body).to include("No Veteran found for the given identifier.")
        end
      end

      context "when a veteran is found" do
        context "when a veteran is found - but an unexpected error has happened." do
          before { RequestIssue::DEFAULT_UPPER_BOUND_PER_PAGE = nil }
          after { RequestIssue::DEFAULT_UPPER_BOUND_PER_PAGE = 50 }
          let(:vet) { create(:veteran) }
          it "should return empty request issues array for veteran" do
            get(
              "/api/v3/issues/ama/find_by_veteran/#{vet.participant_id}?page=1",
              headers: authorization_header
            )
            expect(response).to have_http_status(500)
            expect(response.body.include?("Use the error uuid to submit a support ticket")).to eq true
          end
        end

        context "when there is no error" do
          context "when a veteran is found - but has no request issues" do
            let(:vet) { create(:veteran) }
            it "should return empty request issues array for veteran" do
              get(
                "/api/v3/issues/ama/find_by_veteran/#{vet.participant_id}",
                headers: authorization_header
              )
              expect(response).to have_http_status(200)
              response_hash = JSON.parse(response.body)
              expect(response_hash["request_issues"].empty?).to eq true
            end
          end

          context "when a veteran is found - has request issues" do
            let(:vet) { create(:veteran) }
            let!(:request_issues) do
              [
                create(:request_issue, :with_associated_decision_issue, veteran_participant_id: vet.participant_id),
                create(:request_issue, :with_associated_decision_issue, decision_date: Time.zone.now, veteran_participant_id: vet.participant_id)
              ]
            end

            it "should return request issues array" do
              get(
                "/api/v3/issues/ama/find_by_veteran/#{vet.participant_id}",
                headers: authorization_header
              )
              response_hash = JSON.parse(response.body)
              expect(response).to have_http_status(200)
              expect(response_hash["request_issues"].empty?).to eq false
              expect(response_hash["request_issues"][0]["claim_errors"]).to eq []
            end
          end

          context "when a veteran has a legacy appeal" do
            context "when a veteran has multiple request issues with multiple decision issues" do
              let_it_be(:vet) { create(:veteran, file_number: "123456789") }
              let_it_be(:vacols_case) { create(:case, bfcorlid: "123456789S") }
              include_context :multiple_ri_multiple_di
              let_it_be(:reqeust_issue_no_di) { create(:request_issue, id: 5000, veteran_participant_id: vet.participant_id) }
              let_it_be(:request_issue_for_vet_count) { RequestIssue.where(veteran_participant_id: vet.participant_id).count }

              it_behaves_like :it_should_respond_with_legacy_present, true
              it_behaves_like :it_should_respond_with_associated_request_issues, true, true
              it_behaves_like :it_should_respond_with_multiple_decision_issues_per_request_issues, true, true

              include_context :number_of_request_issues_exceeds_paginates_per, true
            end

            context "when a veteran has multiple decision issues with multiple request issues", skip: "Flakey test" do
              let_it_be(:vet) { create(:veteran, file_number: "123456789") }
              let_it_be(:vacols_case) { create(:case, bfcorlid: "123456789S") }
              let_it_be(:decision_issues) { create_list(:decision_issue, 2, participant_id: vet.participant_id) }
              include_context :multiple_di_multiple_ri
              let_it_be(:reqeust_issue_no_di) { create(:request_issue, id: 5000, veteran_participant_id: vet.participant_id) }
              let_it_be(:request_issue_for_vet_count) { RequestIssue.where(veteran_participant_id: vet.participant_id).count }

              it_behaves_like :it_should_respond_with_legacy_present, true
              it_behaves_like :it_should_respond_with_associated_request_issues, true, true
              it_behaves_like :it_should_respond_with_same_multiple_decision_issues_per_request_issue, true

              include_context :number_of_request_issues_exceeds_paginates_per, true
            end
          end

          context "when a veteran does not have a legacy appeal" do
            context "when a veteran has multiple request issues with multiple decision issues" do
              let_it_be(:vet) { create(:veteran) }
              include_context :multiple_ri_multiple_di
              let_it_be(:reqeust_issue_no_di) { create(:request_issue, id: 5000, veteran_participant_id: vet.participant_id) }
              let_it_be(:request_issue_for_vet_count) { RequestIssue.where(veteran_participant_id: vet.participant_id).count }

              it_behaves_like :it_should_respond_with_legacy_present, false
              it_behaves_like :it_should_respond_with_associated_request_issues, false, true
              it_behaves_like :it_should_respond_with_multiple_decision_issues_per_request_issues, false, true

              include_context :number_of_request_issues_exceeds_paginates_per, false
            end

            context "when a veteran has multiple decision issues with multiple request issues" do
              let_it_be(:vet) { create(:veteran) }
              let_it_be(:decision_issues) { create_list(:decision_issue, 2, participant_id: vet.participant_id) }
              include_context :multiple_di_multiple_ri
              let_it_be(:reqeust_issue_no_di) { create(:request_issue, id: 5000, veteran_participant_id: vet.participant_id) }
              let_it_be(:request_issue_for_vet_count) { RequestIssue.where(veteran_participant_id: vet.participant_id).count }

              it_behaves_like :it_should_respond_with_legacy_present, false
              it_behaves_like :it_should_respond_with_associated_request_issues, false, true
              it_behaves_like :it_should_respond_with_same_multiple_decision_issues_per_request_issue, false

              include_context :number_of_request_issues_exceeds_paginates_per, false
            end
          end
        end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
