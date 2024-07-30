# frozen_string_literal: true

require_relative "./shared_setup.rb"

RSpec.feature "granting substitute appellant for appeals", :all_dbs do
  describe "with a dismissed appeal" do
    let(:veteran) { create(:veteran, date_of_death: Time.zone.parse("2021-07-04")) }
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
      include_context "with existing relationships"

      context "with evidence submission docket" do
        let(:docket_type) { "evidence_submission" }
        let(:evidence_submission_window_end_time) { Time.zone.parse("2021-10-17 00:00") }

        it_should_behave_like "fill substitution form"
      end

      context "with direct review docket" do
        let(:docket_type) { "direct_review" }

        it_should_behave_like "fill substitution form"
      end

      context "with hearing docket" do
        let(:docket_type) { Constants.AMA_DOCKETS.hearing }
        let(:appeal) do
          create(:appeal,
                 :dispatched, :with_decision_issue, :held_hearing_no_tasks,
                 docket_type: docket_type,
                 disposition: "dismissed_death",
                 receipt_date: veteran.date_of_death + 5.days,
                 veteran: veteran)
        end

        it_should_behave_like "fill substitution form"
      end
    end
  end

  describe "with a pending appeal" do
    let(:judge) { create(:user, :judge) }
    let(:veteran) { create(:veteran, date_of_death: Time.zone.parse("2021-07-04")) }
    let(:appeal) do
      create(:appeal,
             :assigned_to_judge,
             associated_judge: judge,
             docket_type: docket_type,
             receipt_date: veteran.date_of_death + 5.days,
             veteran: veteran)
    end
    let(:substitution_date) { appeal.receipt_date + 10.days }
    let(:user) { create(:user) }

    context "without feature toggle" do
      include_context "with Clerk of the Board user"
      let(:docket_type) { "direct_review" }

      it_should_behave_like "substitution unavailable"
    end

    context "with feature toggle" do
      include_context "with listed_granted_substitution_before_dismissal feature toggle"

      context "as COTB user" do
        include_context "with Clerk of the Board user"
        include_context "with existing relationships"

        context "with evidence submission docket" do
          let(:docket_type) { "evidence_submission" }
          let(:evidence_submission_window_end_time) { Time.zone.parse("2021-10-17 00:00") }

          it_should_behave_like "fill substitution form"
        end

        context "with direct review docket" do
          let(:docket_type) { "direct_review" }

          it_should_behave_like "fill substitution form"
        end

        context "with hearing docket" do
          # create appeal with docket type 'hearing'
          let(:docket_type) { Constants.AMA_DOCKETS.hearing }
          let(:appeal) do
            create(:appeal,
                   :assigned_to_judge,
                   :held_hearing_no_tasks,
                   associated_judge: judge,
                   docket_type: docket_type,
                   receipt_date: veteran.date_of_death + 5.days,
                   veteran: veteran)
          end

          it_should_behave_like "fill substitution form"
        end
      end
    end
  end
end
