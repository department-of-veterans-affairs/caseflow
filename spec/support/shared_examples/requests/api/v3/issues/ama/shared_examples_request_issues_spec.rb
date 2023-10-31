# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# rubocop:disable Lint/ParenthesesAsGroupedExpression

RSpec.shared_examples :it_should_show_first_page_if_page_negatvie do |legacy_appeals_present|
  it "should show the first page if page is negative" do
    get(
      "/api/v3/issues/ama/find_by_veteran/#{vet.participant_id}?page=-5",
      headers: authorization_header
    )
    response_hash = JSON.parse(response.body)
    default_per_page = RequestIssue.default_per_page
    total_number_of_pages = (request_issue_for_vet_count / default_per_page.to_f).ceil
    expect(response).to have_http_status(200)
    expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
    expect(response_hash["legacy_appeals_present"]).to eq legacy_appeals_present
    expect(response_hash["request_issues"].size).to eq 2
    expect(response_hash["page"]).to eq 1
    expect(response_hash["total_number_of_pages"]).to eq total_number_of_pages
    expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
    expect(response_hash["max_request_issues_per_page"]).to eq default_per_page
    expect(response_hash["request_issues"][0]["id"] == request_issues[0].id).to eq true
    expect(response_hash["request_issues"][1]["id"] == request_issues[1].id).to eq true
  end
end

RSpec.shared_examples :it_should_show_last_page_if_page_larger_than_total do |legacy_appeals_present|
  it "should show last page if page larger than total" do
    get(
      "/api/v3/issues/ama/find_by_veteran/#{vet.participant_id}?page=5",
      headers: authorization_header
    )
    response_hash = JSON.parse(response.body)
    default_per_page = RequestIssue.default_per_page
    total_number_of_pages = (request_issue_for_vet_count / default_per_page.to_f).ceil
    expect(response).to have_http_status(200)
    expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
    expect(response_hash["legacy_appeals_present"]).to eq legacy_appeals_present
    expect(response_hash["page"]).to eq total_number_of_pages
    expect(response_hash["total_number_of_pages"]).to eq total_number_of_pages
    expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
    expect(response_hash["max_request_issues_per_page"]).to eq default_per_page
  end
end

RSpec.shared_examples :it_should_default_to_page_1 do |legacy_appeals_present|
  it "should default to page 1" do
    get(
      "/api/v3/issues/ama/find_by_veteran/#{vet.participant_id}",
      headers: authorization_header
    )
    response_hash = JSON.parse(response.body)
    default_per_page = RequestIssue.default_per_page
    total_number_of_pages = (request_issue_for_vet_count / default_per_page.to_f).ceil
    expect(response).to have_http_status(200)
    expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
    expect(response_hash["legacy_appeals_present"]).to eq legacy_appeals_present
    expect(response_hash["request_issues"].size).to eq 2
    expect(response_hash["page"]).to eq 1
    expect(response_hash["total_number_of_pages"]).to eq total_number_of_pages
    expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
    expect(response_hash["max_request_issues_per_page"]).to eq default_per_page
    expect(response_hash["request_issues"][0]["id"] == request_issues[0].id).to eq true
    expect(response_hash["request_issues"][1]["id"] == request_issues[1].id).to eq true
  end
end

RSpec.shared_examples :it_should_respond_with_legacy_present do |legacy_appeals_present|
  it "should respond with legacy_appeals_present" do
    get(
      "/api/v3/issues/ama/find_by_veteran/#{vet.participant_id}",
      headers: authorization_header
    )
    response_hash = JSON.parse(response.body)
    expect(response).to have_http_status(200)
    expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
    expect(response_hash["legacy_appeals_present"]).to eq legacy_appeals_present
  end
end

RSpec.shared_examples :it_should_respond_with_associated_request_issues do |legacy_appeals_present, is_empty|
  it "should respond with the associated request issues" do
    get(
      "/api/v3/issues/ama/find_by_veteran/#{vet.participant_id}",
      headers: authorization_header
    )
    response_hash = JSON.parse(response.body)
    request_issues_vet_participant_ids = response_hash["request_issues"].map { |ri| ri["veteran_participant_id"] }
    expect(response).to have_http_status(200)
    expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
    expect(response_hash["legacy_appeals_present"]).to eq legacy_appeals_present
    expect(response_hash["request_issues"].size).to eq request_issue_for_vet_count
    expect(response_hash["request_issues"].last["decision_issues"].empty?).to eq is_empty
    expect(request_issues_vet_participant_ids).to eq ([].tap { |me| request_issue_for_vet_count.times { me << vet.participant_id } })
  end
end

RSpec.shared_examples :it_should_respond_with_multiple_decision_issues_per_request_issues do |legacy_appeals_present, is_empty|
  it "should respond with the multiple decision issues per request issue" do
    get(
      "/api/v3/issues/ama/find_by_veteran/#{vet.participant_id}",
      headers: authorization_header
    )
    response_hash = JSON.parse(response.body)
    request_issues_vet_participant_ids = response_hash["request_issues"].map do |ri|
      ri["veteran_participant_id"]
    end
    expect(response).to have_http_status(200)
    expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
    expect(response_hash["legacy_appeals_present"]).to eq legacy_appeals_present
    expect(response_hash["request_issues"].size).to eq request_issue_for_vet_count
    expect(response_hash["request_issues"].last["decision_issues"].empty?).to eq is_empty
    expect(request_issues_vet_participant_ids).to eq ([].tap { |me| request_issue_for_vet_count.times { me << vet.participant_id } })
    expect(response_hash["request_issues"].first["decision_issues"].size).to eq 2
  end
end

RSpec.shared_examples :it_should_respond_with_same_multiple_decision_issues_per_request_issue do |legacy_appeals_present|
  it "should respond with the same multiple decision issues per request issue" do
    get(
      "/api/v3/issues/ama/find_by_veteran/#{vet.participant_id}",
      headers: authorization_header
    )
    response_hash = JSON.parse(response.body)
    request_issues_vet_participant_ids = response_hash["request_issues"].map { |ri| ri["veteran_participant_id"] }
    expect(response).to have_http_status(200)
    expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
    expect(response_hash["legacy_appeals_present"]).to eq legacy_appeals_present
    expect(response_hash["request_issues"].size).to eq request_issue_for_vet_count
    expect(response_hash["request_issues"].first["decision_issues"] == response_hash["request_issues"].second["decision_issues"]).to eq true
    expect(response_hash["request_issues"][3]["decision_issues"] == response_hash["request_issues"][5]["decision_issues"]).to eq false
    expect(request_issues_vet_participant_ids).to eq ([].tap { |me| request_issue_for_vet_count.times { me << vet.participant_id } })
  end
end

RSpec.shared_examples :it_should_show_page_1_when_page_0 do |legacy_appeals_present|
  it "should show page 1 when attempting to get page 0" do
    get(
      "/api/v3/issues/ama/find_by_veteran/#{vet.participant_id}?page=0",
      headers: authorization_header
    )
    response_hash = JSON.parse(response.body)
    default_per_page = RequestIssue.default_per_page
    total_number_of_pages = (request_issue_for_vet_count / default_per_page.to_f).ceil
    expect(response).to have_http_status(200)
    expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
    expect(response_hash["legacy_appeals_present"]).to eq legacy_appeals_present
    expect(response_hash["request_issues"].size).to eq 2
    expect(response_hash["page"]).to eq 1
    expect(response_hash["total_number_of_pages"]).to eq total_number_of_pages
    expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
    expect(response_hash["max_request_issues_per_page"]).to eq default_per_page
    expect(response_hash["request_issues"][0]["id"] == request_issues[0].id).to eq true
    expect(response_hash["request_issues"][1]["id"] == request_issues[1].id).to eq true
  end
end

RSpec.shared_examples :it_should_show_remaining_issues do |legacy_appeals_present|
  it "should only show remaining request issues on next page" do
    get(
      "/api/v3/issues/ama/find_by_veteran/#{vet.participant_id}?page=2",
      headers: authorization_header
    )
    response_hash = JSON.parse(response.body)
    default_per_page = RequestIssue.default_per_page
    total_number_of_pages = (request_issue_for_vet_count / default_per_page.to_f).ceil
    expect(response).to have_http_status(200)
    expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
    expect(response_hash["legacy_appeals_present"]).to eq legacy_appeals_present
    expect(response_hash["request_issues"].size).to eq 2
    expect(response_hash["page"]).to eq 2
    expect(response_hash["total_number_of_pages"]).to eq total_number_of_pages
    expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
    expect(response_hash["max_request_issues_per_page"]).to eq default_per_page
    expect(response_hash["request_issues"][0]["id"] == request_issues[2].id).to eq true
    expect(response_hash["request_issues"][1]["id"] == request_issues[3].id).to eq true
  end
end

RSpec.shared_examples :it_should_show_number_of_paginated_issues do |legacy_appeals_present|
  it "should only show number of request issues listed in the paginates_per value on first page" do
    get(
      "/api/v3/issues/ama/find_by_veteran/#{vet.participant_id}?page=1",
      headers: authorization_header
    )
    response_hash = JSON.parse(response.body)
    default_per_page = RequestIssue.default_per_page
    total_number_of_pages = (request_issue_for_vet_count / default_per_page.to_f).ceil
    expect(response).to have_http_status(200)
    expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
    expect(response_hash["legacy_appeals_present"]).to eq legacy_appeals_present
    expect(response_hash["request_issues"].size).to eq 2
    expect(response_hash["page"]).to eq 1
    expect(response_hash["total_number_of_pages"]).to eq total_number_of_pages
    expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
    expect(response_hash["max_request_issues_per_page"]).to eq default_per_page
    expect(response_hash["request_issues"][0]["id"] == request_issues[0].id).to eq true
    expect(response_hash["request_issues"][1]["id"] == request_issues[1].id).to eq true
  end
end
# rubocop:enable Layout/LineLength
# rubocop:enable Lint/ParenthesesAsGroupedExpression
