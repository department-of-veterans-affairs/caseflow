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

  context "#process_event_to_update_appeal_state!" do
    let(:user) { create(:user) }

    subject { appeal_state.process_event_to_update_appeal_state!(event) }

    context "receives vso_ihp_pending event" do
      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id,
          appeal_docketed: true
        )
      end

      let(:event) { "vso_ihp_pending" }

      it "sets vso_ihp_pending to true and all others false" do

        subject

        expect(appeal_state.appeal_docketed).to eq false
        expect(appeal_state.vso_ihp_pending).to eq true
      end
    end

    context "receives vso_ihp_cancelled event" do
      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id,
          vso_ihp_pending: true
        )
      end

      let(:event) { "vso_ihp_cancelled" }

      it "sets vso_ihp_pending to false and vso_ihp_complete to false" do

        subject

        expect(appeal_state.vso_ihp_pending).to eq false
        expect(appeal_state.vso_ihp_complete).to eq false
      end
    end

    context "receives vso_ihp_complete event" do
      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id,
          vso_ihp_pending: true
        )
      end

      let(:event) { "vso_ihp_complete" }

      it "sets vso_ihp_complete to true and all others false" do

        subject

        expect(appeal_state.vso_ihp_pending).to eq false
        expect(appeal_state.vso_ihp_complete).to eq true
      end
    end

    context "receives appeal_cancelled event" do
      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id,
          appeal_docketed: true
        )
      end

      let(:event) { "appeal_cancelled" }

      it "sets appeal_cancelled to true and all others false" do

        subject

        expect(appeal_state.appeal_docketed).to eq false
        expect(appeal_state.appeal_cancelled).to eq true
      end
    end

    context "receives appeal_docketed event" do
      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id
        )
      end

      let(:event) { "appeal_docketed" }

      it "sets appeal_docketed to true and all others false" do

        subject

        expect(appeal_state.appeal_docketed).to eq true
      end
    end

    context "receives decision_mailed event" do
      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id
        )
      end

      let(:event) { "decision_mailed" }

      it "sets decision_mailed to true and all others false" do

        subject

        expect(appeal_state.decision_mailed).to eq true
      end
    end

    context "receives privacy_act_pending event" do
      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id
        )
      end

      let(:event) { "privacy_act_pending" }

      it "sets privacy_act_pending to true and all others false" do

        subject

        expect(appeal_state.privacy_act_pending).to eq true
      end
    end

    context "receives privacy_act_cancelled event" do
      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id,
          privacy_act_pending: true
        )
      end

      let(:event) { "privacy_act_cancelled" }

      it "sets privacy_act_pending and privacy_act_complete to false" do

        subject

        expect(appeal_state.privacy_act_pending).to eq false
        expect(appeal_state.privacy_act_complete).to eq false
      end
    end

    context "receives privacy_act_complete event" do
      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id,
          privacy_act_pending: true
        )
      end

      let(:event) { "privacy_act_complete" }

      it "sets privacy_act_complete to true and all others to false." do

        subject

        expect(appeal_state.privacy_act_pending).to eq false
        expect(appeal_state.privacy_act_complete).to eq true
      end
    end

    context "receives hearing_scheduled event" do
      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id,
          appeal_docketed: true
        )
      end

      let(:event) { "hearing_scheduled" }

      it "sets hearing_scheduled to true and all others to false." do

        subject

        expect(appeal_state.appeal_docketed).to eq false
        expect(appeal_state.hearing_scheduled).to eq true
      end
    end

    context "receives hearing_withdrawn event" do
      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id,
          hearing_scheduled: true
        )
      end

      let(:event) { "hearing_withdrawn" }

      it "sets hearing_withdrawn to true and all others to false." do

        subject

        expect(appeal_state.hearing_scheduled).to eq false
        expect(appeal_state.hearing_withdrawn).to eq true
      end
    end

    context "receives hearing_postponed event" do
      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id,
          hearing_scheduled: true
        )
      end

      let(:event) { "hearing_postponed" }

      it "sets hearing_postponed to true and all others to false." do

        subject

        expect(appeal_state.hearing_scheduled).to eq false
        expect(appeal_state.hearing_postponed).to eq true
      end
    end

    context "receives scheduled_in_error event" do
      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id,
          hearing_scheduled: true
        )
      end

      let(:event) { "scheduled_in_error" }

      it "sets scheduled_in_error to true and all others to false." do

        subject

        expect(appeal_state.hearing_scheduled).to eq false
        expect(appeal_state.scheduled_in_error).to eq true
      end
    end
  end
end
