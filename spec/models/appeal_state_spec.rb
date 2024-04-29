# frozen_string_literal: true

describe AppealState do
  it_behaves_like "AppealState belongs_to polymorphic appeal" do
    let!(:_user) { create(:user) } # A User needs to exist for `appeal_state` factories
  end

  context "test quarterly notification status generation" do
    let(:appeal) { create(:appeal, :active) }
    let(:user) { create(:user) }

    context "for docketed status" do
      let(:docketed_appeal_state) {
        create(:appeal_state,
        appeal_id: appeal.id,
        appeal_type: "Appeal",
        created_by_id: user.id,
        updated_by_id: user.id,
        appeal_docketed: true
      ) }

      let(:hearing_withdrawn_docketed_appeal_state) {
        create(:appeal_state,
        appeal_id: 2,
        appeal_type: "Appeal",
        created_by_id: user.id,
        updated_by_id: user.id,
        hearing_withdrawn: true,
        appeal_docketed: true
      ) }

      it "matches the constant" do
        expect(docketed_appeal_state.quarterly_notification_status).to be(Constants.QUARTERLY_STATUSES.appeal_docketed)
        expect(hearing_withdrawn_docketed_appeal_state.quarterly_notification_status).to be(Constants.QUARTERLY_STATUSES.appeal_docketed)
      end
    end

    context "for privacy pending status" do
      let(:appeal_state) {
        create(:appeal_state,
        appeal_id: appeal.id,
        appeal_type: "Appeal",
        created_by_id: user.id,
        updated_by_id: user.id,
        hearing_withdrawn: false,
        vso_ihp_pending: false,
        privacy_act_pending: true
      ) }

      it "matches the constant" do
        expect(appeal_state.quarterly_notification_status).to be(Constants.QUARTERLY_STATUSES.privacy_pending)
      end
    end

    context "for ihp pending status" do
      let(:appeal_state) {
        create(:appeal_state,
        appeal_id: appeal.id,
        appeal_type: "Appeal",
        created_by_id: user.id,
        updated_by_id: user.id,
        hearing_withdrawn: false,
        vso_ihp_pending: true,
        privacy_act_pending: false
      ) }

      it "matches the constant" do
        expect(appeal_state.quarterly_notification_status).to be(Constants.QUARTERLY_STATUSES.ihp_pending)
      end
    end

    context "for ihp pending and privacy pending status" do
      let(:appeal_state) {
        create(:appeal_state,
        appeal_id: appeal.id,
        appeal_type: "Appeal",
        created_by_id: user.id,
        updated_by_id: user.id,
        hearing_withdrawn: false,
        vso_ihp_pending: true,
        privacy_act_pending: true
      ) }

      it "matches the constant" do
        expect(appeal_state.quarterly_notification_status).to be(Constants.QUARTERLY_STATUSES.ihp_pending_privacy_pending)
      end
    end

    context "for hearing scheduled status" do
      let(:appeal_state) {
        create(:appeal_state,
        appeal_id: appeal.id,
        appeal_type: "Appeal",
        created_by_id: user.id,
        updated_by_id: user.id,
        hearing_scheduled: true
      ) }

      it "matches the constant" do
        expect(appeal_state.quarterly_notification_status).to be(Constants.QUARTERLY_STATUSES.hearing_scheduled)
      end
    end

    context "for hearing scheduled status with privacy pending" do
      let(:appeal_state) {
        create(:appeal_state,
        appeal_id: appeal.id,
        appeal_type: "Appeal",
        created_by_id: user.id,
        updated_by_id: user.id,
        hearing_scheduled: true,
        privacy_act_pending: true
      ) }

      it "matches the constant" do
        expect(appeal_state.quarterly_notification_status).to be(Constants.QUARTERLY_STATUSES.hearing_scheduled_privacy_pending)
      end
    end

    context "for hearing rescheduled status" do
      let(:appeal_state) {
        create(:appeal_state,
        appeal_id: appeal.id,
        appeal_type: "Appeal",
        created_by_id: user.id,
        updated_by_id: user.id,
        hearing_postponed: true
      ) }

      it "matches the constant" do
        expect(appeal_state.quarterly_notification_status).to be(Constants.QUARTERLY_STATUSES.hearing_to_be_rescheduled)
      end
    end

    context "for hearing rescheduled privacy pending status" do
      let(:docketed_appeal_state) {
        create(:appeal_state,
        appeal_id: appeal.id,
        appeal_type: "Appeal",
        created_by_id: user.id,
        updated_by_id: user.id,
        hearing_postponed: true,
        privacy_act_pending: true
      ) }

      it "matches the constant" do
        expect(docketed_appeal_state.quarterly_notification_status).to be(Constants.QUARTERLY_STATUSES.hearing_to_be_rescheduled_privacy_pending)
      end
    end
  end
end
