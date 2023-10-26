# frozen_string_literal: true
require "test_prof/recipes/rspec/let_it_be"
describe Api::V3::VbmsIntake::Legacy::VacolsIssueSerializer, :postgres do
  context "VACOLS issue object" do
    let(:vacols_issue) { create(:case_issue) }
    let(:vacols_case) { create(:case, case_issues: [vacols_issue]) }
    let(:legacy_appeal) do
      create(:legacy_appeal, vacols_case: vacols_case)
    end
    it "should show all the fields" do
      serialized_vacols_issue = Api::V3::VbmsIntake::Legacy::VacolsIssueSerializer.new(vacols_issue)
        .serializable_hash[:data][:attributes]

       serialized_vacols_issue
    end
  end
end
