# frozen_string_literal: true

RSpec.configure { |rspec| rspec.shared_context_metadata_behavior = :apply_to_host_groups }

RSpec.shared_context "legacy appeal", shared_context: :metadata do
  let(:vacols_issue) { create(:case_issue) }
  let(:vacols_case) { create(:case, case_issues: [vacols_issue]) }
  let(:legacy_appeal) do
    create(:legacy_appeal, vacols_case: vacols_case)
  end
end
