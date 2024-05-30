# frozen_string_literal: true

# rubocop:disable Layout/LineLength
require "test_prof/recipes/rspec/let_it_be"

RSpec.shared_context :set_new_page_per do
  before { RequestIssue.paginates_per(2) }
  after { RequestIssue.paginates_per(ENV["REQUEST_ISSUE_PAGINATION_OFFSET"].to_i) }
end

RSpec.shared_context :multiple_ri_multiple_di do
  let_it_be(:request_issues) do
    ri_list = create_list(:request_issue, 4, :with_associated_decision_issue,
                          veteran_participant_id: vet.participant_id)
    ri_list.each do |ri|
      di = create(:decision_issue, participant_id: ri.veteran_participant_id, decision_review: ri.decision_review)
      create(:request_decision_issue, request_issue: ri, decision_issue: di)
    end
  end
end

RSpec.shared_context :multiple_di_multiple_ri do
  let_it_be(:request_issues) do
    decision_issues.each do |di|
      ri_list = create_list(:request_issue, 4, veteran_participant_id: vet.participant_id)
      ri_list.each do |ri|
        create(:request_decision_issue, request_issue: ri, decision_issue: di)
      end
    end
    RequestIssue.where(veteran_participant_id: vet.participant_id)
  end
end

RSpec.shared_context :number_of_request_issues_exceeds_paginates_per do |legacy_appeals_present|
  context "when number of request issues exceeds paginates_per value" do
    include_context :set_new_page_per

    it_behaves_like :it_should_show_number_of_paginated_issues, legacy_appeals_present
    it_behaves_like :it_should_show_remaining_issues, legacy_appeals_present
    it_behaves_like :it_should_show_page_1_when_page_0, legacy_appeals_present
    it_behaves_like :it_should_default_to_page_1, legacy_appeals_present
    it_behaves_like :it_should_show_first_page_if_page_negatvie, legacy_appeals_present
    it_behaves_like :it_should_show_last_page_if_page_larger_than_total, legacy_appeals_present
    it_behaves_like :it_should_show_correct_total_number_of_pages_and_max_request_issues_per_page_on_per_change, legacy_appeals_present
    it_behaves_like :it_should_show_default_limit_on_excessive_per_value, legacy_appeals_present
    it_behaves_like :it_should_show_default_if_negative_per_param, legacy_appeals_present
    it_behaves_like :it_should_show_default_if_0_per_param, legacy_appeals_present
    it_behaves_like :it_should_show_correct_number_of_issues_on_page_increment_with_per, legacy_appeals_present
    it_behaves_like :it_should_show_upper_bound_per_if_default_is_higher, legacy_appeals_present
  end
end
# rubocop:enable Layout/LineLength
