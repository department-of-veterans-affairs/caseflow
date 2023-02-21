describe PostSendInitialNotificationLetterHoldingTask do
    let(:user) { create(:user) }
    let(:cob_team) { ClerkOfTheBoard.singleton }
    let(:root_task) { create(:root_task) }
    let(:distribution_task) { create(:distribution_task, parent: root_task) }
    let(:task_class) { PostSendInitialNotificationLetterHoldingTask }
    before do
      cob_team.add_user(user)
      User.authenticate!(user: user)
      FeatureToggle.enable!(:cc_appeal_workflow)
    end

    describe ".verify_user_can_create" do
      let(:params) { { appeal: root_task.appeal, parent_id: distribution_task_id, type: task_class.name} }
      let(:distribution_task_id) { distribution_task.id }

      context "when no distribution_task exists for appeal" do
        let(:distribution_task_id) { nil }

        it "throws an error" do
          expect { task_class.create_from_params(params, user) }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      # test contexts for successfully creating task when an appeal has a CC will go here once other tasks are made
    end

    describe ".available_actions" do
      let(:post_send_initial_notification_letter_holding_task) do
        task_class.create!(
          appeal: distribution_task.appeal,
          parent_id: distribution_task.id,
          assigned_to: cob_team,
          end_date: Time.zone.now + 45.days
        )
      end

      let(:available_task_actions) do
        [
          Constants.TASK_ACTIONS.CANCEL_CONTESTED_CLAIM_POST_INITIAL_LETTER_TASK.to_h,
          Constants.TASK_ACTIONS.RESEND_INITIAL_NOTIFICATION_LETTER.to_h,
          Constants.TASK_ACTIONS.PROCEED_FINAL_NOTIFICATION_LETTER.to_h
        ]
      end

      context "the user is not a member of COB" do
        let(:non_cob_user) { create(:user) }

        subject { post_send_initial_notification_letter_holding_task.available_actions(non_cob_user) }

        it "returns no actions" do
          expect(subject).to_not eql(available_task_actions)
          expect(subject).to eql([])
        end
      end

      context "the user is a member of COB" do
        subject { post_send_initial_notification_letter_holding_task.available_actions(user) }

        it "returns the task actions" do
          expect(subject).to eql(available_task_actions)
        end
      end
    end

    describe ".days_on_hold" do
      let(:post_task) do
        task_class.create!(
          appeal: distribution_task.appeal,
          parent_id: distribution_task.id,
          assigned_to: cob_team,
          end_date: Time.zone.now + 45.days
        )
      end

      let(:post_task_timer) do
        TimedHoldTask.create_from_parent(
          post_initial_task,
          days_on_hold: days_on_hold,
          instructions: "45 Days Hold Period"
        )
      end

      context "if the task has been on hold and hasn't reached its timer yet" do
        it "shows the difference between the current time and the created_at date" do
          # set the task timer and post_task to 12 days in the past
          tt = TaskTimer.find_by(task_id: post_task.id)

          tt.created_at = Time.zone.now - 12.days
          tt.save!
          post_task.created_at = Time.zone.now - 12.days
          post_task.save!
          expect(post_task.reload.days_on_hold).to eq(12)
        end
      end

      context "the task has been completed and time has passed since completion" do
        # binding.pry
        # set task closed_at and created at into the past
        # Time.stub(:now).and_return(Time.now + 100.days)
      end
    end
  end
