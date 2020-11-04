# frozen_string_literal: true

describe TasksForAppeal do
  describe "#call" do
    context "for a legacy appeal with a travel board hearing request" do
      let(:user_roles) { ["Build HearSched"] }
      let!(:user) { create(:user, roles: user_roles) }
      let(:vacols_case) { create(:case, :travel_board_hearing) }
      let!(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }

      before { FeatureToggle.enable!(:convert_travel_board_to_video_or_virtual) }
      after { FeatureToggle.disable!(:convert_travel_board_to_video_or_virtual) }

      subject { TasksForAppeal.new(appeal: appeal, user: user, user_role: "").call }

      it "calls the hearing task tree initializer" do
        expect(HearingTaskTreeInitializer)
          .to receive(:for_appeal_with_pending_travel_board_hearing)
          .with(appeal)
          .once

        subject
      end

      context "the appeal is not a legacy appeal" do
        let!(:appeal) { create(:appeal) }

        it "doesn't call the hearing task tree intitializer" do
          expect(HearingTaskTreeInitializer).to_not receive(:for_appeal_with_pending_travel_board_hearing)

          subject
        end
      end

      context "the appeal has a hearing task" do
        let(:root_task) { create(:root_task, appeal: appeal) }
        let!(:hearing_task) { create(:hearing_task, appeal: appeal, parent: root_task) }

        context "the hearing task is open" do
          it "doesn't call the hearing task tree intitializer" do
            expect(HearingTaskTreeInitializer).to_not receive(:for_appeal_with_pending_travel_board_hearing)

            subject
          end
        end

        context "the appeal has a canceled hearing task tree with a change hearing request type task" do
          let(:schedule_hearing_task) { create(:schedule_hearing_task, appeal: appeal, parent: hearing_task) }
          let!(:change_hearing_request_type_task) do
            create(:change_hearing_request_type_task, appeal: appeal, parent: schedule_hearing_task)
          end

          before { hearing_task.cancel_task_and_child_subtasks }

          it "doesn't call the hearing task tree intitializer" do
            expect(HearingTaskTreeInitializer).to_not receive(:for_appeal_with_pending_travel_board_hearing)

            subject
          end
        end
      end

      context "the appeal doesn't have a travel board hearing request type" do
        let(:vacols_case) { create(:case, :video_hearing_requested) }

        it "doesn't call the hearing task tree intitializer" do
          expect(HearingTaskTreeInitializer).to_not receive(:for_appeal_with_pending_travel_board_hearing)

          subject
        end
      end

      context "the appeal isn't active" do
        it "doesn't call the hearing task tree intitializer" do
          allow(appeal).to receive(:active?).and_return(false)
          expect(HearingTaskTreeInitializer).to_not receive(:for_appeal_with_pending_travel_board_hearing)

          subject
        end
      end
    end
  end
end
