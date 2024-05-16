# frozen_string_literal: true

describe AppealState do
  it_behaves_like "AppealState belongs_to polymorphic appeal" do
    let!(:_user) { create(:user) } # A User needs to exist for `appeal_state` factories
  end

  context "State scopes" do
    let(:user) { create(:user) }

    let!(:appeal_docketed_state) do
      create(
        :appeal_state,
        :ama,
        created_by_id: user.id,
        updated_by_id: user.id,
        appeal_docketed: true
      )
    end

    let!(:hearing_withdrawn_docketed_appeal_state) do
      create(
        :appeal_state,
        :ama,
        created_by_id: user.id,
        updated_by_id: user.id,
        hearing_withdrawn: true,
        appeal_docketed: true
      )
    end

    let!(:privacy_pending_state) do
      create(
        :appeal_state,
        :ama,
        created_by_id: user.id,
        updated_by_id: user.id,
        hearing_withdrawn: false,
        vso_ihp_pending: false,
        privacy_act_pending: true
      )
    end

    let!(:ihp_pending_state) do
      create(
        :appeal_state,
        :ama,
        created_by_id: user.id,
        updated_by_id: user.id,
        hearing_withdrawn: false,
        vso_ihp_pending: true,
        privacy_act_pending: false
      )
    end

    let!(:ihp_pending_privacy_pending_state) do
      create(
        :appeal_state,
        :ama,
        created_by_id: user.id,
        updated_by_id: user.id,
        hearing_withdrawn: false,
        vso_ihp_pending: true,
        privacy_act_pending: true
      )
    end

    let!(:hearing_scheduled_state) do
      create(
        :appeal_state,
        :ama,
        created_by_id: user.id,
        updated_by_id: user.id,
        hearing_scheduled: true
      )
    end

    let!(:hearing_scheduled_privacy_pending_state) do
      create(
        :appeal_state,
        :ama,
        created_by_id: user.id,
        updated_by_id: user.id,
        hearing_scheduled: true,
        privacy_act_pending: true
      )
    end

    let!(:hearing_to_be_rescheduled_postponed_state) do
      create(
        :appeal_state,
        :ama,
        created_by_id: user.id,
        updated_by_id: user.id,
        hearing_postponed: true
      )
    end

    let!(:hearing_to_be_rescheduled_scheduled_in_error_state) do
      create(
        :appeal_state,
        :ama,
        created_by_id: user.id,
        updated_by_id: user.id,
        scheduled_in_error: true
      )
    end

    let!(:hearing_to_be_rescheduled_privacy_pending_state) do
      create(
        :appeal_state,
        :ama,
        created_by_id: user.id,
        updated_by_id: user.id,
        hearing_postponed: true,
        privacy_act_pending: true
      )
    end

    let!(:appeal_decided_state) do
      create(
        :appeal_state,
        :ama,
        created_by_id: user.id,
        updated_by_id: user.id,
        decision_mailed: true
      )
    end

    let!(:appeal_cancelled_state) do
      create(
        :appeal_state,
        :ama,
        created_by_id: user.id,
        updated_by_id: user.id,
        appeal_cancelled: true
      )
    end

    context "#eligible_for_quarterly" do
      subject { described_class.eligible_for_quarterly.pluck(:id) }

      it "Decided and cancelled appeals are excluded" do
        is_expected.to_not contain_exactly(
          appeal_decided_state.id, appeal_cancelled_state.id
        )
      end
    end

    context "#appeal_docketed" do
      subject { described_class.appeal_docketed.pluck(:id) }

      it "Only appeals in docketed state are included" do
        is_expected.to match_array(
          [appeal_docketed_state.id, hearing_withdrawn_docketed_appeal_state.id]
        )
      end
    end

    context "#hearing_scheduled" do
      subject { described_class.hearing_scheduled.pluck(:id) }

      it "Only appeals in hearing scheduled state are included" do
        is_expected.to match_array([hearing_scheduled_state.id])
      end
    end

    context "#hearing_scheduled_privacy_pending" do
      subject { described_class.hearing_scheduled_privacy_pending.pluck(:id) }

      it "Only appeals in hearing scheduled and privacy act state are included" do
        is_expected.to match_array([hearing_scheduled_privacy_pending_state.id])
      end
    end

    context "#hearing_to_be_rescheduled" do
      subject { described_class.hearing_to_be_rescheduled.pluck(:id) }

      it "Only appeals in hearing to be rescheduled state are included" do
        is_expected.to match_array(
          [
            hearing_to_be_rescheduled_postponed_state.id,
            hearing_to_be_rescheduled_scheduled_in_error_state.id
          ]
        )
      end
    end

    context "#hearing_to_be_rescheduled_privacy_pending" do
      subject { described_class.hearing_to_be_rescheduled_privacy_pending.pluck(:id) }

      it "Only appeals in hearing to be rescheduled and privacy act state are included" do
        is_expected.to match_array([hearing_to_be_rescheduled_privacy_pending_state.id])
      end
    end

    context "#ihp_pending" do
      subject { described_class.ihp_pending.pluck(:id) }

      it "Only appeals in VSO IHP pending state are included" do
        is_expected.to match_array([ihp_pending_state.id])
      end
    end

    context "#ihp_pending_privacy_pending" do
      subject { described_class.ihp_pending_privacy_pending.pluck(:id) }

      it "Only appeals in VSO IHP Pending and privacy act state are included" do
        is_expected.to match_array([ihp_pending_privacy_pending_state.id])
      end
    end

    context "#privacy_pending" do
      subject { described_class.privacy_pending.pluck(:id) }

      it "Only appeals in hearing to be rescheduled and privacy act state are included" do
        is_expected.to match_array([privacy_pending_state.id])
      end
    end
  end
end
