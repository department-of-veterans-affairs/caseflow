# frozen_string_literal: true

require_relative "./shared_setup.rb"

RSpec.feature "granting substitute appellant for appeals", :all_dbs do
  describe "with a dismissed appeal" do
    let(:veteran) { create(:veteran, date_of_death: 30.days.ago) }
    let(:appeal) do
      create(:appeal,
             :dispatched, :with_decision_issue,
             docket_type: docket_type,
             disposition: "dismissed_death",
             receipt_date: veteran.date_of_death + 5.days,
             veteran: veteran)
    end
    let(:substitution_date) { appeal.receipt_date + 10.days }
    let(:user) { create(:user) }

    context "as COTB user" do
      include_context "with Clerk of the Board user"
      include_context "with recognized_granted_substitution_after_dd feature toggle"
      include_context "with existing relationships"

      context "with evidence submission docket" do
        let(:docket_type) { "evidence_submission" }

        it_should_behave_like "fill substitution form"
      end

      context "with direct review docket" do
        let(:docket_type) { "direct_review" }

        it_should_behave_like "fill substitution form"
      end

      # use this for manual testing
      context "with hearing docket" do
        let(:docket_type) { Constants.AMA_DOCKETS.hearing }

        context "without hearings feature toggle" do
          it_should_behave_like "substitution unavailable"
        end

        context "with hearings feature toggle" do
          include_context "with hearings_substitution_death_dismissal feature toggle"

          it_should_behave_like "fill substitution form"
        end
      end
    end
  end
end
