# frozen_string_literal: true

describe AppealDecisionIssuesPolicy, :postgres do
  describe "#visible_decision_issues" do
    subject { AppealDecisionIssuesPolicy.new(user: user, appeal: appeal).visible_decision_issues }

    context "when the restrict poa visibility feature toggle is turned on" do
      before { FeatureToggle.enable!(:restrict_poa_visibility) }
      after { FeatureToggle.disable!(:restrict_poa_visibility) }
      context "when user has VSO role" do
        let(:user) { create(:user, :vso_role) }
        let(:result) { subject }

        context "when a decision issue has not yet reached its decision date" do
          let(:appeal) { create(:appeal, :decision_issue_with_future_date) }

          it "cannot be seen" do
            expect(subject).to be_empty
          end
        end

        context "when a decision issue has reached or passed its decision date" do
          let(:appeal) { create(:appeal, :dispatched, :with_decision_issue) }

          it "can be seen" do
            expect(result[0].id).to eq(appeal.decision_issues[0].id)
            expect(result[1].id).to eq(appeal.decision_issues[1].id)
          end

          it "its issue description is not visible" do
            expect(result[0].description).to be_nil
          end
        end

        context "when a decision issue has a nil decision date" do
          let(:appeal) { create(:appeal, :decision_issue_with_no_decision_date) }

          it "cannot be seen" do
            expect(subject).to be_empty
          end
        end

        context "when a decision issue was processed in caseflow and approx_decision_date returns nil" do
          let(:appeal) { create(:appeal, :decision_issue_with_no_end_product_last_action_date) }

          it "cannot be seen" do
            expect(subject).to be_empty
          end
        end

        context "when approx_decision_date throws an error that does not stem from comparing time to nil" do
          let(:appeal) { create(:appeal, :decision_issue_with_future_date) }

          before do
            allow_any_instance_of(DecisionIssue).to receive(:approx_decision_date).and_throw("Error!")
          end
          it "surfaces the error" do
            expect { subject }.to raise_error
          end
        end
      end

      context "when user has no VSO role" do
        let(:user) { create(:user) }

        context "when a decision issue has not yet reached its decision date" do
          let(:appeal) { create(:appeal, :decision_issue_with_future_date) }
          let(:result) { subject }

          it "can be seen" do
            expect(result[0].id).to eq(appeal.decision_issues[0].id)
          end

          it "its issue description is visible" do
            expect(result[0].description).to eq(appeal.decision_issues[0].description)
          end
        end

        context "when a decision issue has reached or passed its decision date" do
          let(:appeal) { create(:appeal, :dispatched, :with_decision_issue) }
          let(:result) { subject }

          it "can be seen" do
            expect(result[1].id).to eq(appeal.decision_issues[1].id)
          end

          it "its issue description is visible" do
            expect(result[0].description).to eq(appeal.decision_issues[0].description)
          end
        end

        context "when a decision issue has no decision date" do
          let(:appeal) { create(:appeal, :decision_issue_with_no_decision_date) }

          it "can be seen" do
            expect(subject[0].id).to eq(appeal.decision_issues[0].id)
          end

          it "its issue description is visible" do
            expect(subject[0].description).to eq(appeal.decision_issues[0].description)
          end
        end
      end
    end

    context "when the restrict poa visibility feature toggle is not turned on" do
      context "when user has VSO role" do
        let(:user) { create(:user, :vso_role) }

        context "when a decision issue has not yet reached its decision date" do
          let(:appeal) { create(:appeal, :decision_issue_with_future_date) }

          it "can be seen" do
            expect(subject).to match_array(appeal.decision_issues)
          end
        end

        context "when a decision issue has no decision date" do
          let(:appeal) { create(:appeal, :decision_issue_with_no_decision_date) }

          it "can be seen" do
            expect(subject).to match_array(appeal.decision_issues)
          end
        end
      end
    end
  end
end
