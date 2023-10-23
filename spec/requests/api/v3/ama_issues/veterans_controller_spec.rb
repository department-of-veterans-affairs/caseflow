# frozen_string_literal: true

require "test_prof/recipes/rspec/let_it_be"

# rubocop:disable Layout/LineLength
# rubocop:disable Lint/ParenthesesAsGroupedExpression
describe Api::V3::AmaIssues::VeteransController, :postgres, type: :request do
  let_it_be(:api_key) do
    ApiKey.create!(consumer_name: "ApiV3 Test VBMS Consumer").key_string
  end

  let_it_be(:authorization_header) do
    { "Authorization" => "Token #{api_key}" }
  end

  describe "#show" do
    # context "when feature is not enabled" do
    #   let!(:vet) { create(:veteran) }

    #   it "should return 'Not Implemented' error" do
    #     FeatureToggle.disable!(:api_v3_vbms_intake_ama)
    #     get(
    #       "/api/v3/ama_issues/veterans/#{vet.participant_id}",
    #       headers: authorization_header
    #     )
    #     expect(response).to have_http_status(501)
    #     expect(response.body).to include("Not Implemented")
    #   end
    # end

    context "when feature is enabled" do
      # before { FeatureToggle.enable!(:api_v3_vbms_intake_ama) }

      # after { FeatureToggle.disable!(:api_v3_vbms_intake_ama) }

      context "when a veteran is not found" do
        it "should return veteran not found error" do
          get(
            "/api/v3/ama_issues/veterans/9999999999",
            headers: authorization_header
          )
          expect(response).to have_http_status(500)
          expect(response.body).to include("Couldn't find Veteran")
        end
      end

      context "when a veteran is found" do
        context "when a veteran has a legacy appeal" do
          context "when a veteran has multiple request issues with multiple decision issues" do
            let_it_be(:vet) { create(:veteran, file_number: "123456789") }
            let_it_be(:vacols_case) { create(:case, bfcorlid: "123456789S") }
            let_it_be(:request_issues) do
              ri_list = create_list(:request_issue, 4,
                                    :with_associated_decision_issue,
                                    veteran_participant_id: vet.participant_id)
              ri_list.each do |ri|
                di = create(:decision_issue,
                            participant_id: ri.veteran_participant_id,
                            decision_review: ri.decision_review)
                create(:request_decision_issue, request_issue: ri, decision_issue: di)
              end
            end
            let_it_be(:reqeust_issue_no_di) do
              create(:request_issue, veteran_participant_id: vet.participant_id)
            end
            let_it_be(:request_issue_for_vet_count) do
              RequestIssue.where(veteran_participant_id: vet.participant_id).count
            end

            it "should respond with legacy_appeals_present true" do
              get(
                "/api/v3/ama_issues/veterans/#{vet.participant_id}",
                headers: authorization_header
              )
              response_hash = JSON.parse(response.body)
              expect(response).to have_http_status(200)
              expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
              expect(response_hash["legacy_appeals_present"]).to eq true
            end

            it "should respond with the associated request issues" do
              get(
                "/api/v3/ama_issues/veterans/#{vet.participant_id}",
                headers: authorization_header
              )
              response_hash = JSON.parse(response.body)
              request_issues_vet_participant_ids = response_hash["request_issues"].map { |ri| ri["veteran_participant_id"] }
              expect(response).to have_http_status(200)
              expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
              expect(response_hash["legacy_appeals_present"]).to eq true
              expect(response_hash["request_issues"].size).to eq request_issue_for_vet_count
              expect(response_hash["request_issues"].last["decision_issues"]).to be_empty
              expect(request_issues_vet_participant_ids).to eq ([].tap { |me| request_issue_for_vet_count.times { me << vet.participant_id } })
            end

            it "should respond with the multiple decision issues per request issue" do
              get(
                "/api/v3/ama_issues/veterans/#{vet.participant_id}",
                headers: authorization_header
              )
              response_hash = JSON.parse(response.body)
              request_issues_vet_participant_ids = response_hash["request_issues"].map { |ri| ri["veteran_participant_id"] }
              expect(response).to have_http_status(200)
              expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
              expect(response_hash["legacy_appeals_present"]).to eq true
              expect(response_hash["request_issues"].size).to eq request_issue_for_vet_count
              expect(response_hash["request_issues"].last["decision_issues"]).to be_empty
              expect(request_issues_vet_participant_ids).to eq ([].tap { |me| request_issue_for_vet_count.times { me << vet.participant_id } })
              expect(response_hash["request_issues"].first["decision_issues"].size).to eq 2
            end

            context "when number of request issues exceeds paginates_per value" do
              before { RequestIssue.paginates_per(2) }
              after { RequestIssue.paginates_per(ENV["REQUEST_ISSUE_PAGINATION_OFFSET"]) }

              it "should only show number of request issues listed in the paginates_per value on first page" do
                get(
                  "/api/v3/ama_issues/veterans/#{vet.participant_id}?page=1",
                  headers: authorization_header
                )
                response_hash = JSON.parse(response.body)
                default_per_page = RequestIssue.default_per_page
                expect(response).to have_http_status(200)
                expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
                expect(response_hash["legacy_appeals_present"]).to eq true
                expect(response_hash["request_issues"].size).to eq 2
                expect(response_hash["page"]).to eq 1
                expect(response_hash["total_number_of_pages"]).to eq (request_issue_for_vet_count / default_per_page.to_f).ceil
                expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
                expect(response_hash["max_request_issues_per_page"]).to eq default_per_page
                expect(response_hash["request_issues"][0]["id"] == request_issues[0].id).to eq true
                expect(response_hash["request_issues"][1]["id"] == request_issues[1].id).to eq true
              end

              it "should only show remaining request issues on next page" do
                get(
                  "/api/v3/ama_issues/veterans/#{vet.participant_id}?page=2",
                  headers: authorization_header
                )
                response_hash = JSON.parse(response.body)
                default_per_page = RequestIssue.default_per_page
                expect(response).to have_http_status(200)
                expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
                expect(response_hash["legacy_appeals_present"]).to eq true
                expect(response_hash["request_issues"].size).to eq 2
                expect(response_hash["page"]).to eq 2
                expect(response_hash["total_number_of_pages"]).to eq (request_issue_for_vet_count / default_per_page.to_f).ceil
                expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
                expect(response_hash["max_request_issues_per_page"]).to eq default_per_page
                expect(response_hash["request_issues"][0]["id"] == request_issues[2].id).to eq true
                expect(response_hash["request_issues"][1]["id"] == request_issues[3].id).to eq true
              end

              it "should show page 1 when attempting to get page 0" do
                get(
                  "/api/v3/ama_issues/veterans/#{vet.participant_id}?page=0",
                  headers: authorization_header
                )
                response_hash = JSON.parse(response.body)
                default_per_page = RequestIssue.default_per_page
                expect(response).to have_http_status(200)
                expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
                expect(response_hash["legacy_appeals_present"]).to eq true
                expect(response_hash["request_issues"].size).to eq 2
                expect(response_hash["page"]).to eq 1
                expect(response_hash["total_number_of_pages"]).to eq (request_issue_for_vet_count / default_per_page.to_f).ceil
                expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
                expect(response_hash["max_request_issues_per_page"]).to eq default_per_page
                expect(response_hash["request_issues"][0]["id"] == request_issues[0].id).to eq true
                expect(response_hash["request_issues"][1]["id"] == request_issues[1].id).to eq true
              end

              it "should default to page 1" do
                get(
                  "/api/v3/ama_issues/veterans/#{vet.participant_id}",
                  headers: authorization_header
                )
                response_hash = JSON.parse(response.body)
                default_per_page = RequestIssue.default_per_page
                expect(response).to have_http_status(200)
                expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
                expect(response_hash["legacy_appeals_present"]).to eq true
                expect(response_hash["request_issues"].size).to eq 2
                expect(response_hash["page"]).to eq 1
                expect(response_hash["total_number_of_pages"]).to eq (request_issue_for_vet_count / default_per_page.to_f).ceil
                expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
                expect(response_hash["max_request_issues_per_page"]).to eq default_per_page
                expect(response_hash["request_issues"][0]["id"] == request_issues[0].id).to eq true
                expect(response_hash["request_issues"][1]["id"] == request_issues[1].id).to eq true
              end
            end
          end

          context "when a veteran has multiple decision issues with multiple request issues" do
            let_it_be(:vet) { create(:veteran, file_number: "123456789") }
            let_it_be(:vacols_case) { create(:case, bfcorlid: "123456789S") }
            let_it_be(:decision_issues) { create_list(:decision_issue, 2, participant_id: vet.participant_id) }
            let_it_be(:request_issues) do
              decision_issues.each do |di|
                ri_list = create_list(:request_issue, 4, veteran_participant_id: vet.participant_id)
                ri_list.each do |ri|
                  create(:request_decision_issue, request_issue: ri, decision_issue: di)
                end
              end
              RequestIssue.where(veteran_participant_id: vet.participant_id)
            end
            let_it_be(:request_issue_for_vet_count) { RequestIssue.where(veteran_participant_id: vet.participant_id).count }

            it "should respond with legacy_appeals_present true" do
              get(
                "/api/v3/ama_issues/veterans/#{vet.participant_id}",
                headers: authorization_header
              )
              response_hash = JSON.parse(response.body)
              expect(response).to have_http_status(200)
              expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
              expect(response_hash["legacy_appeals_present"]).to eq true
            end

            it "should respond with the associated request issues" do
              get(
                "/api/v3/ama_issues/veterans/#{vet.participant_id}",
                headers: authorization_header
              )
              response_hash = JSON.parse(response.body)
              request_issues_vet_participant_ids = response_hash["request_issues"].map { |ri| ri["veteran_participant_id"] }
              expect(response).to have_http_status(200)
              expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
              expect(response_hash["legacy_appeals_present"]).to eq true
              expect(response_hash["request_issues"].size).to eq request_issue_for_vet_count
              expect(request_issues_vet_participant_ids).to eq ([].tap { |me| request_issue_for_vet_count.times { me << vet.participant_id } })
            end

            it "should respond with the same multiple decision issues per request issue" do
              get(
                "/api/v3/ama_issues/veterans/#{vet.participant_id}",
                headers: authorization_header
              )
              response_hash = JSON.parse(response.body)
              request_issues_vet_participant_ids = response_hash["request_issues"].map { |ri| ri["veteran_participant_id"] }
              expect(response).to have_http_status(200)
              expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
              expect(response_hash["legacy_appeals_present"]).to eq true
              expect(response_hash["request_issues"].size).to eq request_issue_for_vet_count
              expect(response_hash["request_issues"].first["decision_issues"] == response_hash["request_issues"].second["decision_issues"]).to eq true
              expect(response_hash["request_issues"][3]["decision_issues"] == response_hash["request_issues"][5]["decision_issues"]).to eq false
              expect(request_issues_vet_participant_ids).to eq ([].tap { |me| request_issue_for_vet_count.times { me << vet.participant_id } })
            end

            context "when number of request issues exceeds paginates_per value" do
              before { RequestIssue.paginates_per(2) }
              after { RequestIssue.paginates_per(ENV["REQUEST_ISSUE_PAGINATION_OFFSET"]) }

              it "should only show number of request issues listed in the paginates_per value on first page" do
                get(
                  "/api/v3/ama_issues/veterans/#{vet.participant_id}?page=1",
                  headers: authorization_header
                )
                response_hash = JSON.parse(response.body)
                default_per_page = RequestIssue.default_per_page
                expect(response).to have_http_status(200)
                expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
                expect(response_hash["legacy_appeals_present"]).to eq true
                expect(response_hash["request_issues"].size).to eq 2
                expect(response_hash["page"]).to eq 1
                expect(response_hash["total_number_of_pages"]).to eq (request_issue_for_vet_count / default_per_page.to_f).ceil
                expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
                expect(response_hash["max_request_issues_per_page"]).to eq default_per_page
                expect(response_hash["request_issues"][0]["id"] == request_issues[0].id).to eq true
                expect(response_hash["request_issues"][1]["id"] == request_issues[1].id).to eq true
              end

              it "should only show remaining request issues on next page" do
                get(
                  "/api/v3/ama_issues/veterans/#{vet.participant_id}?page=2",
                  headers: authorization_header
                )
                response_hash = JSON.parse(response.body)
                default_per_page = RequestIssue.default_per_page
                expect(response).to have_http_status(200)
                expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
                expect(response_hash["legacy_appeals_present"]).to eq true
                expect(response_hash["request_issues"].size).to eq 2
                expect(response_hash["page"]).to eq 2
                expect(response_hash["total_number_of_pages"]).to eq (request_issue_for_vet_count / default_per_page.to_f).ceil
                expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
                expect(response_hash["max_request_issues_per_page"]).to eq default_per_page
                expect(response_hash["request_issues"][0]["id"] == request_issues[2].id).to eq true
                expect(response_hash["request_issues"][1]["id"] == request_issues[3].id).to eq true
              end

              it "should show page 1 when attempting to get page 0" do
                get(
                  "/api/v3/ama_issues/veterans/#{vet.participant_id}?page=0",
                  headers: authorization_header
                )
                response_hash = JSON.parse(response.body)
                default_per_page = RequestIssue.default_per_page
                expect(response).to have_http_status(200)
                expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
                expect(response_hash["legacy_appeals_present"]).to eq true
                expect(response_hash["request_issues"].size).to eq 2
                expect(response_hash["page"]).to eq 1
                expect(response_hash["total_number_of_pages"]).to eq (request_issue_for_vet_count / default_per_page.to_f).ceil
                expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
                expect(response_hash["max_request_issues_per_page"]).to eq default_per_page
                expect(response_hash["request_issues"][0]["id"] == request_issues[0].id).to eq true
                expect(response_hash["request_issues"][1]["id"] == request_issues[1].id).to eq true
              end

              it "should default to page 1" do
                get(
                  "/api/v3/ama_issues/veterans/#{vet.participant_id}",
                  headers: authorization_header
                )
                response_hash = JSON.parse(response.body)
                default_per_page = RequestIssue.default_per_page
                expect(response).to have_http_status(200)
                expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
                expect(response_hash["legacy_appeals_present"]).to eq true
                expect(response_hash["request_issues"].size).to eq 2
                expect(response_hash["page"]).to eq 1
                expect(response_hash["total_number_of_pages"]).to eq (request_issue_for_vet_count / default_per_page.to_f).ceil
                expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
                expect(response_hash["max_request_issues_per_page"]).to eq default_per_page
                expect(response_hash["request_issues"][0]["id"] == request_issues[0].id).to eq true
                expect(response_hash["request_issues"][1]["id"] == request_issues[1].id).to eq true
              end
            end
          end
        end

        context "when a veteran does not have a legacy appeal" do
          context "when a veteran has multiple request issues with multiple decision issues" do
            let_it_be(:vet) { create(:veteran) }
            let_it_be(:request_issues) do
              ri_list = create_list(:request_issue, 4, :with_associated_decision_issue, veteran_participant_id: vet.participant_id)
              ri_list.each do |ri|
                di = create(:decision_issue, participant_id: ri.veteran_participant_id, decision_review: ri.decision_review)
                create(:request_decision_issue, request_issue: ri, decision_issue: di)
              end
            end
            let_it_be(:reqeust_issue_no_di) { create(:request_issue, veteran_participant_id: vet.participant_id) }
            let_it_be(:request_issue_for_vet_count) { RequestIssue.where(veteran_participant_id: vet.participant_id).count }

            it "should respond with legacy_appeals_present false" do
              get(
                "/api/v3/ama_issues/veterans/#{vet.participant_id}",
                headers: authorization_header
              )
              response_hash = JSON.parse(response.body)
              expect(response).to have_http_status(200)
              expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
              expect(response_hash["legacy_appeals_present"]).to eq false
            end

            it "should respond with the associated request issues" do
              get(
                "/api/v3/ama_issues/veterans/#{vet.participant_id}",
                headers: authorization_header
              )
              response_hash = JSON.parse(response.body)
              request_issues_vet_participant_ids = response_hash["request_issues"].map { |ri| ri["veteran_participant_id"] }
              expect(response).to have_http_status(200)
              expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
              expect(response_hash["legacy_appeals_present"]).to eq false
              expect(response_hash["request_issues"].size).to eq request_issue_for_vet_count
              expect(response_hash["request_issues"].last["decision_issues"]).to be_empty
              expect(request_issues_vet_participant_ids).to eq ([].tap { |me| request_issue_for_vet_count.times { me << vet.participant_id } })
            end

            it "should respond with the multiple decision issues per request issue" do
              get(
                "/api/v3/ama_issues/veterans/#{vet.participant_id}",
                headers: authorization_header
              )
              response_hash = JSON.parse(response.body)
              request_issues_vet_participant_ids = response_hash["request_issues"].map do |ri|
                ri["veteran_participant_id"]
              end
              expect(response).to have_http_status(200)
              expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
              expect(response_hash["legacy_appeals_present"]).to eq false
              expect(response_hash["request_issues"].size).to eq request_issue_for_vet_count
              expect(response_hash["request_issues"].last["decision_issues"]).to be_empty
              expect(request_issues_vet_participant_ids).to eq ([].tap { |me| request_issue_for_vet_count.times { me << vet.participant_id } })
              expect(response_hash["request_issues"].first["decision_issues"].size).to eq 2
            end

            context "when number of request issues exceeds paginates_per value" do
              before { RequestIssue.paginates_per(2) }
              after { RequestIssue.paginates_per(ENV["REQUEST_ISSUE_PAGINATION_OFFSET"]) }

              it "should only show number of request issues listed in the paginates_per value on first page" do
                get(
                  "/api/v3/ama_issues/veterans/#{vet.participant_id}?page=1",
                  headers: authorization_header
                )
                response_hash = JSON.parse(response.body)
                default_per_page = RequestIssue.default_per_page
                expect(response).to have_http_status(200)
                expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
                expect(response_hash["legacy_appeals_present"]).to eq false
                expect(response_hash["request_issues"].size).to eq 2
                expect(response_hash["page"]).to eq 1
                expect(response_hash["total_number_of_pages"]).to eq (request_issue_for_vet_count / default_per_page.to_f).ceil
                expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
                expect(response_hash["max_request_issues_per_page"]).to eq default_per_page
                expect(response_hash["request_issues"][0]["id"] == request_issues[0].id).to eq true
                expect(response_hash["request_issues"][1]["id"] == request_issues[1].id).to eq true
              end

              it "should only show remaining request issues on next page" do
                get(
                  "/api/v3/ama_issues/veterans/#{vet.participant_id}?page=2",
                  headers: authorization_header
                )
                response_hash = JSON.parse(response.body)
                default_per_page = RequestIssue.default_per_page
                expect(response).to have_http_status(200)
                expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
                expect(response_hash["legacy_appeals_present"]).to eq false
                expect(response_hash["request_issues"].size).to eq 2
                expect(response_hash["page"]).to eq 2
                expect(response_hash["total_number_of_pages"]).to eq (request_issue_for_vet_count / default_per_page.to_f).ceil
                expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
                expect(response_hash["max_request_issues_per_page"]).to eq default_per_page
                expect(response_hash["request_issues"][0]["id"] == request_issues[2].id).to eq true
                expect(response_hash["request_issues"][1]["id"] == request_issues[3].id).to eq true
              end

              it "should show page 1 when attempting to get page 0" do
                get(
                  "/api/v3/ama_issues/veterans/#{vet.participant_id}?page=0",
                  headers: authorization_header
                )
                response_hash = JSON.parse(response.body)
                default_per_page = RequestIssue.default_per_page
                expect(response).to have_http_status(200)
                expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
                expect(response_hash["legacy_appeals_present"]).to eq false
                expect(response_hash["request_issues"].size).to eq 2
                expect(response_hash["page"]).to eq 1
                expect(response_hash["total_number_of_pages"]).to eq (request_issue_for_vet_count / default_per_page.to_f).ceil
                expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
                expect(response_hash["max_request_issues_per_page"]).to eq default_per_page
                expect(response_hash["request_issues"][0]["id"] == request_issues[0].id).to eq true
                expect(response_hash["request_issues"][1]["id"] == request_issues[1].id).to eq true
              end

              it "should default to page 1" do
                get(
                  "/api/v3/ama_issues/veterans/#{vet.participant_id}",
                  headers: authorization_header
                )
                response_hash = JSON.parse(response.body)
                default_per_page = RequestIssue.default_per_page
                expect(response).to have_http_status(200)
                expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
                expect(response_hash["legacy_appeals_present"]).to eq false
                expect(response_hash["request_issues"].size).to eq 2
                expect(response_hash["page"]).to eq 1
                expect(response_hash["total_number_of_pages"]).to eq (request_issue_for_vet_count / default_per_page.to_f).ceil
                expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
                expect(response_hash["max_request_issues_per_page"]).to eq default_per_page
                expect(response_hash["request_issues"][0]["id"] == request_issues[0].id).to eq true
                expect(response_hash["request_issues"][1]["id"] == request_issues[1].id).to eq true
              end
            end
          end

          context "when a veteran has multiple decision issues with multiple request issues" do
            let_it_be(:vet) { create(:veteran) }
            let_it_be(:decision_issues) { create_list(:decision_issue, 2, participant_id: vet.participant_id) }
            let_it_be(:request_issues) do
              decision_issues.each do |di|
                ri_list = create_list(:request_issue, 4, veteran_participant_id: vet.participant_id)
                ri_list.each do |ri|
                  create(:request_decision_issue, request_issue: ri, decision_issue: di)
                end
              end
              RequestIssue.where(veteran_participant_id: vet.participant_id)
            end
            let_it_be(:request_issue_for_vet_count) do
              RequestIssue.where(veteran_participant_id: vet.participant_id).count
            end

            it "should respond with legacy_appeals_present false" do
              get(
                "/api/v3/ama_issues/veterans/#{vet.participant_id}",
                headers: authorization_header
              )
              response_hash = JSON.parse(response.body)
              expect(response).to have_http_status(200)
              expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
              expect(response_hash["legacy_appeals_present"]).to eq false
            end

            it "should respond with the associated request issues" do
              get(
                "/api/v3/ama_issues/veterans/#{vet.participant_id}",
                headers: authorization_header
              )
              response_hash = JSON.parse(response.body)
              request_issues_vet_participant_ids = response_hash["request_issues"].map { |ri| ri["veteran_participant_id"] }
              expect(response).to have_http_status(200)
              expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
              expect(response_hash["legacy_appeals_present"]).to eq false
              expect(response_hash["request_issues"].size).to eq request_issue_for_vet_count
              expect(request_issues_vet_participant_ids).to eq ([].tap { |me| request_issue_for_vet_count.times { me << vet.participant_id } })
            end

            it "should respond with the same multiple decision issues per request issue" do
              get(
                "/api/v3/ama_issues/veterans/#{vet.participant_id}",
                headers: authorization_header
              )
              response_hash = JSON.parse(response.body)
              request_issues_vet_participant_ids = response_hash["request_issues"].map { |ri| ri["veteran_participant_id"] }
              expect(response).to have_http_status(200)
              expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
              expect(response_hash["legacy_appeals_present"]).to eq false
              expect(response_hash["request_issues"].size).to eq request_issue_for_vet_count
              expect(response_hash["request_issues"].first["decision_issues"] == response_hash["request_issues"].second["decision_issues"]).to eq true
              expect(response_hash["request_issues"][3]["decision_issues"] == response_hash["request_issues"][5]["decision_issues"]).to eq false
              expect(request_issues_vet_participant_ids).to eq ([].tap { |me| request_issue_for_vet_count.times { me << vet.participant_id } })
            end

            context "when number of request issues exceeds paginates_per value" do
              before { RequestIssue.paginates_per(2) }
              after { RequestIssue.paginates_per(ENV["REQUEST_ISSUE_PAGINATION_OFFSET"]) }

              it "should only show number of request issues listed in the paginates_per value on first page" do
                get(
                  "/api/v3/ama_issues/veterans/#{vet.participant_id}?page=1",
                  headers: authorization_header
                )
                response_hash = JSON.parse(response.body)
                default_per_page = RequestIssue.default_per_page
                expect(response).to have_http_status(200)
                expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
                expect(response_hash["legacy_appeals_present"]).to eq false
                expect(response_hash["request_issues"].size).to eq 2
                expect(response_hash["page"]).to eq 1
                expect(response_hash["total_number_of_pages"]).to eq (request_issue_for_vet_count / default_per_page.to_f).ceil
                expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
                expect(response_hash["max_request_issues_per_page"]).to eq default_per_page
                expect(response_hash["request_issues"][0]["id"] == request_issues[0].id).to eq true
                expect(response_hash["request_issues"][1]["id"] == request_issues[1].id).to eq true
              end

              it "should only show remaining request issues on next page" do
                get(
                  "/api/v3/ama_issues/veterans/#{vet.participant_id}?page=2",
                  headers: authorization_header
                )
                response_hash = JSON.parse(response.body)
                default_per_page = RequestIssue.default_per_page
                expect(response).to have_http_status(200)
                expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
                expect(response_hash["legacy_appeals_present"]).to eq false
                expect(response_hash["page"]).to eq 2
                expect(response_hash["total_number_of_pages"]).to eq (request_issue_for_vet_count / default_per_page.to_f).ceil
                expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
                expect(response_hash["max_request_issues_per_page"]).to eq default_per_page
                expect(response_hash["request_issues"].size).to eq 2
                expect(response_hash["request_issues"][0]["id"] == request_issues[2].id).to eq true
                expect(response_hash["request_issues"][1]["id"] == request_issues[3].id).to eq true
              end

              it "should show page 1 when attempting to get page 0" do
                get(
                  "/api/v3/ama_issues/veterans/#{vet.participant_id}?page=0",
                  headers: authorization_header
                )
                response_hash = JSON.parse(response.body)
                default_per_page = RequestIssue.default_per_page
                expect(response).to have_http_status(200)
                expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
                expect(response_hash["legacy_appeals_present"]).to eq false
                expect(response_hash["request_issues"].size).to eq 2
                expect(response_hash["page"]).to eq 1
                expect(response_hash["total_number_of_pages"]).to eq (request_issue_for_vet_count / default_per_page.to_f).ceil
                expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
                expect(response_hash["max_request_issues_per_page"]).to eq default_per_page
                expect(response_hash["request_issues"][0]["id"] == request_issues[0].id).to eq true
                expect(response_hash["request_issues"][1]["id"] == request_issues[1].id).to eq true
              end

              it "should default to page 1" do
                get(
                  "/api/v3/ama_issues/veterans/#{vet.participant_id}",
                  headers: authorization_header
                )
                response_hash = JSON.parse(response.body)
                default_per_page = RequestIssue.default_per_page
                expect(response).to have_http_status(200)
                expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
                expect(response_hash["legacy_appeals_present"]).to eq false
                expect(response_hash["request_issues"].size).to eq 2
                expect(response_hash["page"]).to eq 1
                expect(response_hash["total_number_of_pages"]).to eq (request_issue_for_vet_count / default_per_page.to_f).ceil
                expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
                expect(response_hash["max_request_issues_per_page"]).to eq default_per_page
                expect(response_hash["request_issues"][0]["id"] == request_issues[0].id).to eq true
                expect(response_hash["request_issues"][1]["id"] == request_issues[1].id).to eq true
              end
            end
          end
        end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
# rubocop:enable Lint/ParenthesesAsGroupedExpression
