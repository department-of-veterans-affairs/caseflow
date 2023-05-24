# frozen_string_literal: true

require_relative "./send_notification_shared_examples_spec.rb"

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

  after do
    Timecop.return
  end

  include_examples "verify_user_can_create"

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
        Constants.TASK_ACTIONS.RESEND_INITIAL_NOTIFICATION_LETTER_POST_HOLDING.to_h,
        Constants.TASK_ACTIONS.PROCEED_FINAL_NOTIFICATION_LETTER_POST_HOLDING.to_h
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

  describe ".timer_ends_at" do
    let(:hold_days) { 45 }
    let(:end_date) { Time.zone.now + hold_days.days }
    let(:post_task) do
      task_class.create!(
        appeal: distribution_task.appeal,
        parent_id: distribution_task.id,
        assigned_to: cob_team,
        end_date: end_date
      )
    end

    context "the post task was created before the timer" do
      it "returns the end date" do
        expect(post_task.timer_ends_at).to eq(end_date)
      end
    end

    context "the post task has a related TaskTimer" do
      let(:post_task_timer) do
        TimedHoldTask.create_from_parent(
          post_task,
          days_on_hold: hold_days,
          instructions: "45 Days Hold Period"
        )
      end

      it "returns TaskTimer submitted_at date" do
        tt = TaskTimer.find_by(task_id: post_task.id)
        expect(tt.task_id).to eq(post_task.id)
        expect(post_task.timer_ends_at).to be_within(1.second).of(tt.submitted_at)
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
      let(:now) { Time.zone.now }
      it "shows the difference between the current time and the created_at date" do
        # set the task timer and post_task to 12 days in the past
        tt = TaskTimer.find_by(task_id: post_task.id)
        tt.created_at = Time.zone.now - 12.days
        tt.save!
        post_task.created_at = Time.zone.now - 12.days
        post_task.save!
        end_date = tt.updated_at
        start_date = tt.created_at
        expect((end_date - start_date).to_i / 1.day).to eq(12)
      end

      it "shows the difference when time moves into the future if the task isn't closed" do
        # set the time 100 days into the future
        post_task.reload.created_at
        Timecop.travel(now + 100.days)

        # confirm the task isn't completed/cancelled and the timer is working
        expect(post_task.reload.status).to_not eq("cancelled")
        expect(post_task.reload.status).to_not eq("completed")

        expect((Time.zone.now - post_task.created_at).to_i / 1.day).to eq(100)
      end
    end

    context "the task has been completed and time has passed since completion" do
      let(:now) { Time.zone.now }

      it "returns the same on hold time because the task was completed" do
        # set the task timer and post_task to 12 days in the past
        tt = TaskTimer.find_by(task_id: post_task.id)
        tt.created_at = Time.zone.now - 12.days
        tt.save!
        post_task.created_at = Time.zone.now - 12.days
        # complete the task
        post_task.status = "completed"
        post_task.save!

        end_date = tt.updated_at
        start_date = tt.created_at

        expect((end_date - start_date).to_i / 1.day).to eq(12)

        # set the time 100 days into the future
        Timecop.travel(now + 100.days)

        # expect the same days on hold as before
        expect((end_date - start_date).to_i / 1.day).to eq(12)
      end

      it "returns the same on hold time because the task was cancelled" do
        # set the task timer and post_task to 12 days in the past
        tt = TaskTimer.find_by(task_id: post_task.id)
        tt.created_at = Time.zone.now - 12.days
        tt.save!
        post_task.created_at = Time.zone.now - 12.days
        # complete the task
        post_task.status = "cancelled"
        post_task.save!

        expect((post_task.closed_at - post_task.created_at).to_i / 1.day).to eq(12)

        # set the time 100 days into the future
        Timecop.travel(now + 100.days)

        # expect the same days on hold as before
        expect((post_task.closed_at - post_task.created_at).to_i / 1.day).to eq(12)
      end
    end
  end

  describe ".max_hold_day_period" do
    let(:hold_days) { 45 }
    let(:end_date) { Time.zone.now + hold_days.days }
    let(:post_task) do
      task_class.create!(
        appeal: distribution_task.appeal,
        parent_id: distribution_task.id,
        assigned_to: cob_team,
        end_date: end_date
      )
    end

    context "The TaskTimer for the hold period was not created yet" do
      it "returns the end date period" do
        expect((post_task.timer_ends_at - post_task.created_at.prev_day).to_i / 1.day).to eq(hold_days)
      end
    end

    context "The TaskTimer for the hold period was created" do
      let(:post_task_timer) do
        TimedHoldTask.create_from_parent(
          post_task,
          days_on_hold: hold_days,
          instructions: "45 Days Hold Period"
        )
      end

      it "returns the same max hold period using the TaskTimer dates" do
        tt = TaskTimer.find_by(task_id: post_task.id)
        expect(tt.task_id).to eq(post_task.id)
        expect((post_task.timer_ends_at - post_task.created_at.prev_day).to_i / 1.day).to eq(hold_days)

        # confirm the values are being pulled from the TaskTimer
        calculate_max_hold = (tt.submitted_at - post_task.created_at.prev_day).to_i / 1.day
        expect((post_task.timer_ends_at - post_task.created_at.prev_day).to_i / 1.day).to eq(calculate_max_hold)
      end
    end
  end

  describe "Process when hold time expire" do
    let(:days_on_hold) { 45 }
    let!(:post_task) do
      task_class.create!(
        appeal: distribution_task.appeal,
        parent_id: distribution_task.id,
        assigned_to: cob_team,
        end_date: Time.zone.now + 45.days
      )
    end

    let!(:post_task_timer) do
      TimedHoldTask.create_from_parent(
        post_task,
        days_on_hold: days_on_hold,
        instructions: "45 Days Hold Period"
      )
    end

    let(:timer_for_task) do
      task_timer = TaskTimer.last
      task_timer.update(last_submitted_at: 1.day.ago)
      task_timer.reload
    end

    context "Hold time expire" do
      let(:now) { Time.zone.now }

      it "Complete task" do
        Timecop.travel(now + 45.days) do
          timer_for_task.update(processed_at: 1.day.ago)

          processed_at = timer_for_task.reload.processed_at

          post_task.when_timer_ends

          expect(timer_for_task.reload.processed_at).to eq processed_at

          task = Task.find_by(type: "SendFinalNotificationLetterTask")
          expect(task.appeal_id).to eq(post_task.appeal_id)
          expect(task.status).to eq("assigned")

          task_complete = Task.find_by(type: "PostSendInitialNotificationLetterHoldingTask")
          expect(task_complete.appeal_id).to eq(post_task.appeal_id)
          expect(task_complete.status).to eq("completed")
        end
      end
    end
  end
end
