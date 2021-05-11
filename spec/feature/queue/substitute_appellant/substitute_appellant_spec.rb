# frozen_string_literal: true

require_relative "./shared_setup.rb"

RSpec.feature "granting substitute appellant for appeals", :all_dbs do
  describe "with a dismissed appeal" do
    let(:veteran) { create(:veteran, date_of_death: Time.zone.today - 10.days) }
    let(:appeal) do
      create(:appeal, :dispatched_with_decision_issue,
      docket_type: "evidence_submission",
      stream_type: "original",
      disposition: "dismissed_death",
      veteran: veteran)
    end
    let(:substitution_date) { Time.zone.today - 5.days }
    let(:user) { create(:user) }

    context "as COTB user" do
      include_context "with Clerk of the Board user"
      include_context "with feature toggle"
      include_context "with existing relationships"

      it_should_behave_like "fill substitution form"
    end
  end
end
