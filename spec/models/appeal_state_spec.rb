# frozen_string_literal: true

describe AppealState do
  it_behaves_like "AppealState belongs_to polymorphic appeal" do
    let!(:_user) { create(:user) } # A User needs to exist for `appeal_state` factories
  end

  context "test quarterly notification status generation" do
    let(:appeal) { create(:appeal, :active) }
    let(:user) { create(:user) }

    context "for docketed status" do
      let!(:docketed_appeal_state) do
        create(
          :appeal_state,
          appeal_id: appeal.id,
          appeal_type: "Appeal",
          created_by_id: user.id,
          updated_by_id: user.id,
          appeal_docketed: true
        )
      end

      let!(:hearing_withdrawn_docketed_appeal_state) do
        create(
          :appeal_state,
          appeal_id: 2,
          appeal_type: "Appeal",
          created_by_id: user.id,
          updated_by_id: user.id,
          hearing_withdrawn: true,
          appeal_docketed: true
        )
      end

      it "matches the constant" do
        status = Constants.QUARTERLY_STATUSES.appeal_docketed
        expect(docketed_appeal_state.quarterly_notification_status).to be(status)
        expect(hearing_withdrawn_docketed_appeal_state.quarterly_notification_status).to be(status)
      end
    end

    context "for privacy pending status" do
      let!(:appeal_state) do
        create(
          :appeal_state,
          appeal_id: appeal.id,
          appeal_type: "Appeal",
          created_by_id: user.id,
          updated_by_id: user.id,
          hearing_withdrawn: false,
          vso_ihp_pending: false,
          privacy_act_pending: true
        )
      end

      it "matches the constant" do
        status = Constants.QUARTERLY_STATUSES.privacy_pending
        expect(appeal_state.quarterly_notification_status).to be(status)
      end
    end

    context "for ihp pending status" do
      let!(:appeal_state) do
        create(
          :appeal_state,
          appeal_id: appeal.id,
          appeal_type: "Appeal",
          created_by_id: user.id,
          updated_by_id: user.id,
          hearing_withdrawn: false,
          vso_ihp_pending: true,
          privacy_act_pending: false
        )
      end

      it "matches the constant" do
        status = Constants.QUARTERLY_STATUSES.ihp_pending
        expect(appeal_state.quarterly_notification_status).to be(status)
      end
    end

    context "for ihp pending and privacy pending status" do
      let!(:appeal_state) do
        create(
          :appeal_state,
          appeal_id: appeal.id,
          appeal_type: "Appeal",
          created_by_id: user.id,
          updated_by_id: user.id,
          hearing_withdrawn: false,
          vso_ihp_pending: true,
          privacy_act_pending: true
        )
      end

      it "matches the constant" do
        status = Constants.QUARTERLY_STATUSES.ihp_pending_privacy_pending
        expect(appeal_state.quarterly_notification_status).to be(status)
      end
    end

    context "for hearing scheduled status" do
      let!(:appeal_state) do
        create(
          :appeal_state,
          appeal_id: appeal.id,
          appeal_type: "Appeal",
          created_by_id: user.id,
          updated_by_id: user.id,
          hearing_scheduled: true
        )
      end

      it "matches the constant" do
        status = Constants.QUARTERLY_STATUSES.hearing_scheduled
        expect(appeal_state.quarterly_notification_status).to be(status)
      end
    end

    context "for hearing scheduled status with privacy pending" do
      let!(:appeal_state) do
        create(
          :appeal_state,
          appeal_id: appeal.id,
          appeal_type: "Appeal",
          created_by_id: user.id,
          updated_by_id: user.id,
          hearing_scheduled: true,
          privacy_act_pending: true
        )
      end

      it "matches the constant" do
        status = Constants.QUARTERLY_STATUSES.hearing_scheduled_privacy_pending
        expect(appeal_state.quarterly_notification_status).to be(status)
      end
    end

    context "for hearing rescheduled status" do
      let!(:appeal_state) do
        create(
          :appeal_state,
          appeal_id: appeal.id,
          appeal_type: "Appeal",
          created_by_id: user.id,
          updated_by_id: user.id,
          hearing_postponed: true
        )
      end

      it "matches the constant" do
        status = Constants.QUARTERLY_STATUSES.hearing_to_be_rescheduled
        expect(appeal_state.quarterly_notification_status).to be(status)
      end
    end

    context "for hearing rescheduled privacy pending status" do
      let!(:appeal_state) do
        create(
          :appeal_state,
          appeal_id: appeal.id,
          appeal_type: "Appeal",
          created_by_id: user.id,
          updated_by_id: user.id,
          hearing_postponed: true,
          privacy_act_pending: true
        )
      end

      it "matches the constant" do
        status = Constants.QUARTERLY_STATUSES.hearing_to_be_rescheduled_privacy_pending
        expect(appeal_state.quarterly_notification_status).to be(status)
      end
    end
  end

  # context "process_event_to_update_appeal_state method updates appeal state according to event type" do
  #   let(:user) { create(:user) }
  #   let(:appeal) { create(:appeal, :with_pre_docket_task) }
  #   let(:appeal_state) { create(:appeal_state, appeal_id: appeal.id, appeal_type: appeal.class.to_s,created_by_id: user.id, updated_by_id: user.id) }
  #   let(:template_name) { "appeal_docketed" }
  #   let!(:pre_docket_task) { PreDocketTask.find_by(appeal: appeal) }
  #   it "will update the appeal state after docketing the Predocketed Appeal" do
  #     expect(AppellantNotification).to receive(:update_appeal_state).with(appeal, template_name)
  #     pre_docket_task.docket_appeal
  #     expect(appeal_state.appeal_docketed).to eq(true)
  #   end
  # end
end
