# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# rubocop:disable Lint/ParenthesesAsGroupedExpression
RSpec.shared_examples :it_should_show_upper_bound_per_if_default_is_higher do |legacy_appeals_present|
  # default RequestIssue.default_per_page is set to 2 in set_new_page_per shared context
  before { RequestIssue::DEFAULT_UPPER_BOUND_PER_PAGE = 1 }
  after { RequestIssue::DEFAULT_UPPER_BOUND_PER_PAGE = 50 }
  it "should show upper bound per if default is higher" do
    get(
      "/api/v3/issues/ama/find_by_veteran/#{vet.participant_id}?page=1",
      headers: authorization_header
    )
    response_hash = JSON.parse(response.body)
    # default RequestIssue.default_per_page is set to 2 in set_new_page_per shared context
    total_number_of_pages = (request_issue_for_vet_count / 1.to_f).ceil
    expect(response).to have_http_status(200)
    expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
    expect(response_hash["legacy_appeals_present"]).to eq legacy_appeals_present
    expect(response_hash["request_issues"].size).to eq 1
    expect(response_hash["page"]).to eq 1
    expect(response_hash["total_number_of_pages"]).to eq total_number_of_pages
    expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
    expect(response_hash["max_request_issues_per_page"]).to eq 1
  end
end

RSpec.shared_examples :it_should_show_correct_number_of_issues_on_page_increment_with_per do |legacy_appeals_present|
  it "should show correct number of issues on page increment with per" do
    get(
      "/api/v3/issues/ama/find_by_veteran/#{vet.participant_id}?page=2&per_page=1",
      headers: authorization_header
    )
    response_hash = JSON.parse(response.body)
    # default RequestIssue.default_per_page is set to 2 in set_new_page_per shared context
    total_number_of_pages = (request_issue_for_vet_count / 1.to_f).ceil
    expect(response).to have_http_status(200)
    expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
    expect(response_hash["legacy_appeals_present"]).to eq legacy_appeals_present
    expect(response_hash["request_issues"].size).to eq 1
    expect(response_hash["page"]).to eq 2
    expect(response_hash["total_number_of_pages"]).to eq total_number_of_pages
    expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
    expect(response_hash["max_request_issues_per_page"]).to eq 1
  end
end

RSpec.shared_examples :it_should_show_default_if_0_per_param do |legacy_appeals_present|
  it "should show default if 0 per param is supplied" do
    get(
      "/api/v3/issues/ama/find_by_veteran/#{vet.participant_id}?page=1&per_page=0",
      headers: authorization_header
    )
    response_hash = JSON.parse(response.body)
    # default RequestIssue.default_per_page is set to 2 in set_new_page_per shared context
    total_number_of_pages = (request_issue_for_vet_count / 2.to_f).ceil
    expect(response).to have_http_status(200)
    expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
    expect(response_hash["legacy_appeals_present"]).to eq legacy_appeals_present
    expect(response_hash["request_issues"].size).to eq 2
    expect(response_hash["page"]).to eq 1
    expect(response_hash["total_number_of_pages"]).to eq total_number_of_pages
    expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
    expect(response_hash["max_request_issues_per_page"]).to eq 2
  end
end

RSpec.shared_examples :it_should_show_default_if_negative_per_param do |legacy_appeals_present|
  it "should show default if negative per param is supplied" do
    get(
      "/api/v3/issues/ama/find_by_veteran/#{vet.participant_id}?page=1&per_page=-1",
      headers: authorization_header
    )
    response_hash = JSON.parse(response.body)
    # default RequestIssue.default_per_page is set to 2 in set_new_page_per shared context
    total_number_of_pages = (request_issue_for_vet_count / 2.to_f).ceil
    expect(response).to have_http_status(200)
    expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
    expect(response_hash["legacy_appeals_present"]).to eq legacy_appeals_present
    expect(response_hash["request_issues"].size).to eq 2
    expect(response_hash["page"]).to eq 1
    expect(response_hash["total_number_of_pages"]).to eq total_number_of_pages
    expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
    expect(response_hash["max_request_issues_per_page"]).to eq 2
  end
end

RSpec.shared_examples :it_should_show_default_limit_on_excessive_per_value do |legacy_appeals_present|
  before { RequestIssue::DEFAULT_UPPER_BOUND_PER_PAGE = 3 }
  after { RequestIssue::DEFAULT_UPPER_BOUND_PER_PAGE = 50 }
  it "should show default limit on excessive per value" do
    get(
      "/api/v3/issues/ama/find_by_veteran/#{vet.participant_id}?page=1&per_page=50",
      headers: authorization_header
    )
    response_hash = JSON.parse(response.body)
    # default RequestIssue.default_per_page is set to 2 in set_new_page_per shared context
    total_number_of_pages = (request_issue_for_vet_count / 2.to_f).ceil
    expect(response).to have_http_status(200)
    expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
    expect(response_hash["legacy_appeals_present"]).to eq legacy_appeals_present
    expect(response_hash["request_issues"].size).to eq 2
    expect(response_hash["page"]).to eq 1
    expect(response_hash["total_number_of_pages"]).to eq total_number_of_pages
    expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
    expect(response_hash["max_request_issues_per_page"]).to eq 2
  end
end

RSpec.shared_examples :it_should_show_correct_total_number_of_pages_and_max_request_issues_per_page_on_per_change do |legacy_appeals_present|
  it "should show correct total number of pages and max request issues per page on per change" do
    get(
      "/api/v3/issues/ama/find_by_veteran/#{vet.participant_id}?page=1&per_page=1",
      headers: authorization_header
    )
    response_hash = JSON.parse(response.body)
    total_number_of_pages = (request_issue_for_vet_count / 1.to_f).ceil
    expect(response).to have_http_status(200)
    expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
    expect(response_hash["legacy_appeals_present"]).to eq legacy_appeals_present
    expect(response_hash["request_issues"].size).to eq 1
    expect(response_hash["page"]).to eq 1
    expect(response_hash["total_number_of_pages"]).to eq total_number_of_pages
    expect(response_hash["total_request_issues_for_vet"]).to eq request_issue_for_vet_count
    expect(response_hash["max_request_issues_per_page"]).to eq 1
  end
end

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
    request_issue_without_dis = response_hash["request_issues"].find { |ri| ri["id"] == 5000 }
    expect(response).to have_http_status(200)
    expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
    expect(response_hash["legacy_appeals_present"]).to eq legacy_appeals_present
    expect(response_hash["request_issues"].size).to eq request_issue_for_vet_count
    expect(request_issue_without_dis["decision_issues"].empty?).to eq is_empty
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
    request_issue_without_dis = response_hash["request_issues"].find { |ri| ri["id"] == 5000 }
    request_issue_with_two_dis = response_hash["request_issues"].find { |ri| ri["decision_issues"].size == 2 }
    expect(response).to have_http_status(200)
    expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
    expect(response_hash["legacy_appeals_present"]).to eq legacy_appeals_present
    expect(response_hash["request_issues"].size).to eq request_issue_for_vet_count
    expect(request_issue_without_dis["decision_issues"].empty?).to eq is_empty
    expect(request_issues_vet_participant_ids).to eq ([].tap { |me| request_issue_for_vet_count.times { me << vet.participant_id } })
    expect(request_issue_with_two_dis).to_not eq nil
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
    decision_issues_array = response_hash["request_issues"].map { |ri| ri["decision_issues"] }
    expect(response).to have_http_status(200)
    expect(response_hash["veteran_participant_id"]).to eq vet.participant_id
    expect(response_hash["legacy_appeals_present"]).to eq legacy_appeals_present
    expect(response_hash["request_issues"].size).to eq request_issue_for_vet_count
    expect(decision_issues_array.uniq.length).to be < decision_issues_array.length
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
  end
end
# rubocop:enable Layout/LineLength
# rubocop:enable Lint/ParenthesesAsGroupedExpression
