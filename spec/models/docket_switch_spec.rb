# frozen_string_literal: true

RSpec.describe DocketSwitch, type: :model do
  let(:cotb_team) { ClerkOfTheBoard.singleton }
  let(:judge) { create(:user, full_name: "Judge User", css_id: "JUDGE_1") }
  let(:attorney) { create(:user) }
  let!(:judge_team) do
    JudgeTeam.create_for_judge(judge).tap { |jt| jt.add_user(attorney) }
  end
  let(:cotb_user) { create(:user, full_name: "Clerk Atty") }
  let(:appeal) do
    create(
      :appeal,
      request_issues: build_list(
        :request_issue, 3
      )
    )
  end
  let(:root_task) { create(:root_task, appeal: appeal) }
  let(:new_docket_stream) { appeal.create_stream(:switched_docket) }
  let(:docket_switch_task) do
    task_class_type = (disposition == "denied") ? "denied" : "granted"
    create("docket_switch_#{task_class_type}_task".to_sym, appeal: appeal, assigned_to: cotb_user, assigned_by: judge)
  end
  let(:disposition) { nil }
  let(:assigned_to_id) { nil }
  let(:docket_type) { Constants.AMA_DOCKETS.hearing }
  let(:granted_request_issue_ids) { appeal.request_issues.map(&:id) }
  let(:docket_switch) do
    create(
      :docket_switch,
      old_docket_stream: appeal,
      task: docket_switch_task,
      disposition: disposition,
      docket_type: docket_type,
      granted_request_issue_ids: granted_request_issue_ids
    )
  end

  before do
    create(:staff, :attorney_role, sdomainid: cotb_user.css_id)
    create(:staff, :judge_role, sdomainid: judge.reload.css_id)
    cotb_team.add_user(cotb_user)
  end

  context "#process!" do
    subject { docket_switch.process! }

    context "disposition is denied" do
      let(:disposition) { "denied" }

      it "closes the DocketSwitchDeniedTask" do
        expect(docket_switch_task).to be_assigned

        subject

        expect(docket_switch_task).to be_completed
      end
    end

    context "disposition is granted or partially granted" do
      context "when disposition is granted (full grant)" do
        let(:disposition) { "granted" }
        let(:granted_request_issue_ids) { nil }

        it "moves all request issues to a new appeal stream and marks the original appeal as docket switched" do
          expect(docket_switch_task).to be_assigned

          subject

          # new stream has a the new docket type
          expect(docket_switch.new_docket_stream.docket_type).to eq(docket_switch.docket_type)

          # all request issues are copied to new appeal stream, accessible as new_docket_stream
          expect(docket_switch.new_docket_stream.request_issues.count).to eq appeal.request_issues.count

          # all old request issues closed
          expect(appeal.request_issues.map { |ri| ri.reload.closed_status }.uniq).to eq ["docket_switch"]

          # Docket switch task gets completed
          expect(docket_switch_task).to be_completed

          # Appeal Status API shows original stream's status of docket switched
          expect(appeal.status.to_sym).to eq :docket_switched

          # Docket switch task has been copied to new appeal stream
          new_completed_task = DocketSwitchGrantedTask.find_by(appeal: docket_switch.new_docket_stream)
          expect(new_completed_task).to_not be_nil
          expect(new_completed_task).to be_completed
        end

        context "when old docket stream has active attorney tasks" do
          let(:docket_type) { Constants.AMA_DOCKETS.evidence_submission }
          # add AttorneyTask w/ status of assigned or in_progress
          let!(:attorney_task) do
            create(
              :ama_attorney_task,
              :in_progress,
              appeal: appeal,
              assigned_to: attorney,
              placed_on_hold_at: 2.days.ago
            )
          end

          it "doesn't move attorney tasks to new stream" do
            docket_switch.selected_task_ids = [attorney_task.id.to_s]
            attorney_task.parent.update!(parent: root_task)
            docket_switch.process!

            expect(docket_switch_task).to be_completed

            expect(docket_switch.new_docket_stream.tasks.find_by(type: "JudgeDecisionReviewTask")).to be_nil
            expect(docket_switch.new_docket_stream.tasks.find_by(type: "AttorneyTask")).to be_nil
          end

          context "when switching to Direct Review" do
            let(:docket_type) { Constants.AMA_DOCKETS.direct_review }

            it "preserves the post-distribution tasks and cancels the new DistributionTask" do
              docket_switch.selected_task_ids = [attorney_task.id.to_s]
              attorney_task.parent.update!(parent: root_task)
              docket_switch.process!

              expect(docket_switch_task).to be_completed
              new_tasks = docket_switch.new_docket_stream.tasks
              expect(new_tasks.find_by(type: :DistributionTask)).to be_cancelled
              expect(new_tasks.find_by(type: :JudgeDecisionReviewTask)).to_not be_nil
              expect(new_tasks.find_by(type: :AttorneyTask)).to_not be_nil
            end
          end
        end

        context "when ihp task present" do
          let(:docket_type) { Constants.AMA_DOCKETS.direct_review }

          let(:vva) do
            Vso.create(
              name: "Vietnam Veterans Of America",
              role: "VSO",
              url: "vietnam-veterans-of-america",
              participant_id: "2452415"
            )
          end

          let(:ihp_task) do
            create(
              :informal_hearing_presentation_task,
              appeal: appeal,
              parent: root_task,
              assigned_to: vva
            )
          end

          it "successfully switches and creates new ihp task" do
            docket_switch.selected_task_ids = [ihp_task.id.to_s]
            docket_switch.process!

            expect(docket_switch_task).to be_completed
            new_tasks = docket_switch.new_docket_stream.tasks
            new_ihp = new_tasks.find_by(type: :InformalHearingPresentationTask)

            expect(new_ihp).to_not be_nil
            expect(new_ihp.id.to_s).not_to be(ihp_task.id.to_s)
          end
        end
      end

      context "when disposition is partially_granted" do
        let(:disposition) { "partially_granted" }
        let(:granted_request_issue_ids) { appeal.request_issues[0..1].map(&:id) }
        let!(:judge_assign_task) do
          create(
            :ama_judge_assign_task,
            :in_progress,
            appeal: appeal,
            parent: root_task,
            assigned_to: judge,
            placed_on_hold_at: 2.days.ago
          )
        end

        it "moves granted issues to new stream and maintains original post-distribution tasks" do
          expect(docket_switch_task).to be_assigned

          subject

          # new stream has a the new docket type
          expect(docket_switch.new_docket_stream.docket_type).to eq(docket_switch.docket_type)

          # granted request issues are copied to new appeal stream
          expect(docket_switch.new_docket_stream.request_issues.count).to eq 2

          # granted old request issues closed
          expect(appeal.request_issues.map { |ri| ri.reload.closed_status }.compact.uniq).to eq ["docket_switch"]
          expect(appeal.request_issues.active.count).to eq 1

          # Docket switch task gets completed
          expect(docket_switch_task).to be_completed

          # Docket switch task has been copied to new appeal stream
          new_completed_task = DocketSwitchGrantedTask.assigned_to_any_user.find_by(
            appeal: docket_switch.new_docket_stream
          )
          expect(new_completed_task).to_not be_nil
          expect(new_completed_task).to be_completed

          expect(appeal.tasks.find_by(type: "JudgeAssignTask")).to be_in_progress

          # To do: Check for correct appeal status after task handling logic is implemented
        end
      end
    end
  end

  context "#valid?" do
    subject do
      build(
        :docket_switch,
        old_docket_stream: appeal,
        task: docket_switch_task,
        disposition: disposition,
        granted_request_issue_ids: granted_request_issue_ids
      )
    end

    context "when partially granted" do
      let(:disposition) { "partially_granted" }

      context "when issue ids not set" do
        let(:granted_request_issue_ids) { nil }

        it "not be valid" do
          expect(subject).not_to be_valid
        end
      end
    end

    context "when not partial grant" do
      let(:disposition) { "denied" }

      it "validates without " do
        expect(subject).to be_valid
      end
    end
  end
end
