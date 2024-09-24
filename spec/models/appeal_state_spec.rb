# frozen_string_literal: true

describe AppealState do
  it_behaves_like "AppealState belongs_to polymorphic appeal" do
    let!(:user) { create(:user) } # A User needs to exist for `appeal_state` factories
  end

  let!(:user) { create(:user) }

  context "State scopes" do
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

    shared_context "staged hearing task tree" do
      let(:appeal) { create(:appeal, :active) }
      let(:distribution_task) { DistributionTask.create!(appeal: appeal, parent: appeal.root_task) }
      let(:hearing_task) { HearingTask.create!(appeal: appeal, parent: distribution_task) }
      let!(:assign_disp_task) do
        AssignHearingDispositionTask.create!(appeal: appeal, parent: hearing_task, assigned_to: Bva.singleton)
      end
    end

    shared_context "vacols case with case hearing" do
      let(:case_hearing) { create(:case_hearing) }
      let(:vacols_case) { create(:case, case_hearings: [case_hearing]) }
      let!(:legacy_appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
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

      context "ama" do
        subject do
          AppealState.find_by_appeal_id(appeal.id).update!(hearing_scheduled: true)

          described_class.hearing_scheduled.pluck(:id)
        end

        let!(:appeal_state) { appeal.appeal_state }

        context "Whenever the expected task is absent" do
          let(:appeal) { create(:appeal, :active) }

          it "The appeal state isn't retrieved by the query" do
            is_expected.to be_empty
          end
        end

        context "Whenever the hearing has been held and the evidence submission window is open" do
          include_context "staged hearing task tree"

          let!(:evidence_task) do
            EvidenceSubmissionWindowTask.create!(
              appeal: appeal,
              parent: assign_disp_task,
              assigned_to: MailTeam.singleton
            )
          end

          it "The appeal state isn't retrieved by the query" do
            is_expected.to be_empty
          end
        end

        context "Whenever the hearing has not been held" do
          include_context "staged hearing task tree"

          it "The appeal state is returned" do
            is_expected.to match_array([appeal_state.id])
          end
        end
      end

      context "legacy" do
        include_context "vacols case with case hearing"

        let!(:appeal_state) { legacy_appeal.appeal_state.tap { _1.update!(hearing_scheduled: true) } }

        context "hearing has not been held" do
          it "the appeal state is returned" do
            is_expected.to match_array([appeal_state.id])
          end
        end

        context "hearing has been held" do
          it "the appeal state is not returned" do
            case_hearing.update!(hearing_disp: "H")

            is_expected.to be_empty
          end
        end
      end

      context "ama and legacy" do
        include_context "vacols case with case hearing"
        include_context "staged hearing task tree"

        let!(:ama_state) { appeal.appeal_state.tap { _1.update!(hearing_scheduled: true) } }
        let!(:legacy_state) { legacy_appeal.appeal_state.tap { _1.update!(hearing_scheduled: true) } }

        context "An AMA and legacy hearings are both pending" do
          it "both appeal states are returned by the query" do
            is_expected.to match_array([ama_state.id, legacy_state.id])
          end
        end

        context "An AMA and legacy hearings have been held" do
          let!(:evidence_task) do
            EvidenceSubmissionWindowTask.create!(
              parent: assign_disp_task,
              appeal: appeal,
              assigned_to: MailTeam.singleton
            )
          end

          it "neither appeal states are returned by the query" do
            case_hearing.update!(hearing_disp: "H")

            is_expected.to be_empty
          end
        end

        context "An AMA hearing is pending and the legacy hearing has been held" do
          it "only the AMA appeal state is returned by the query" do
            case_hearing.update!(hearing_disp: "H")

            is_expected.to match_array([ama_state.id])
          end
        end

        context "A legacy hearing is pending and an AMA hearing has been held" do
          let!(:evidence_task) do
            EvidenceSubmissionWindowTask.create!(
              assigned_to: MailTeam.singleton,
              parent: assign_disp_task,
              appeal: appeal
            )
          end

          it "only the legacy appeal state is returned by the query" do
            is_expected.to match_array([legacy_state.id])
          end
        end
      end
    end

    context "#hearing_scheduled_privacy_pending" do
      include_context "staged hearing task tree"

      subject { described_class.hearing_scheduled_privacy_pending.pluck(:id) }

      let!(:hearing_scheduled_privacy_pending_state) do
        appeal.appeal_state.tap do
          _1.update!(hearing_scheduled: true,
                     privacy_act_pending: true)
        end
      end

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

  shared_examples "privacy_act_pending status remains active upon update" do
    before { appeal_state.update!(privacy_act_pending: true) }

    it "privacy_act_pending remains true" do
      subject

      expect(appeal_state.privacy_act_pending).to eq true
    end
  end

  context "#appeal_docketed_appeal_state_update!" do
    subject { appeal_state.appeal_docketed_appeal_state_update_action! }

    context "updates the appeal_docketed attribute" do
      include_examples "privacy_act_pending status remains active upon update"

      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id,
          appeal_docketed: false
        )
      end

      it "sets appeal_docketed to true and all others false" do
        subject

        expect(appeal_state.appeal_docketed).to eq true
      end
    end
  end

  context "#vso_ihp_pending_appeal_state_update!" do
    subject { appeal_state.vso_ihp_pending_appeal_state_update_action! }

    context "updates the vso_ihp_pending attribute" do
      include_examples "privacy_act_pending status remains active upon update"

      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id,
          appeal_docketed: true
        )
      end

      it "sets vso_ihp_pending to true" do
        subject

        expect(appeal_state.vso_ihp_pending).to eq true
      end
    end
  end

  context "#vso_ihp_cancelled_appeal_state_update!" do
    subject { appeal_state.vso_ihp_cancelled_appeal_state_update_action! }

    context "updates the vso_ihp_pending attribute" do
      include_examples "privacy_act_pending status remains active upon update"

      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id,
          vso_ihp_pending: true
        )
      end

      it "sets vso_ihp_pending to false and all others false" do
        subject

        expect(appeal_state.vso_ihp_pending).to eq false
      end
    end
  end

  context "#vso_ihp_complete_appeal_state_update_action!" do
    subject { appeal_state.vso_ihp_complete_appeal_state_update_action! }

    context "updates the vso_ihp_complete attribute" do
      include_examples "privacy_act_pending status remains active upon update"

      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id,
          vso_ihp_complete: true
        )
      end

      it "sets vso_ihp_complete to true and all others false" do
        subject

        expect(appeal_state.vso_ihp_complete).to eq true
      end
    end
  end

  context "#privacy_act_pending_appeal_state_update!" do
    subject { appeal_state.privacy_act_pending_appeal_state_update_action! }

    context "updates the privacy_act_pending attribute" do
      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id,
          privacy_act_pending: false
        )
      end

      it "sets privacy_act_pending to true and all others false" do
        subject

        expect(appeal_state.privacy_act_pending).to eq true
      end
    end
  end

  context "#privacy_act_cancelled_appeal_state_update_action!" do
    subject { appeal_state.privacy_act_cancelled_appeal_state_update_action! }

    context "updates the privacy_act_pending attribute" do
      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id,
          privacy_act_pending: true
        )
      end

      it "sets privacy_act_cancelled to true and all others false" do
        subject

        expect(appeal_state.privacy_act_pending).to eq false
      end
    end
  end

  context "#privacy_act_complete_appeal_state_update_action!" do
    subject { appeal_state.privacy_act_complete_appeal_state_update_action! }

    context "updates the privacy_act_complete attribute" do
      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id,
          privacy_act_pending: true,
          hearing_scheduled: true
        )
      end

      it "sets privacy_act_complete to true and leaves others intact" do
        subject

        expect(appeal_state.privacy_act_pending).to eq false
        expect(appeal_state.privacy_act_complete).to eq true
        expect(appeal_state.hearing_scheduled).to eq true
      end
    end
  end

  context "#decision_mailed_appeal_state_update_action!" do
    subject { appeal_state.decision_mailed_appeal_state_update_action! }

    context "updates the decision_mailed attribute" do
      include_examples "privacy_act_pending status remains active upon update"

      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id,
          decision_mailed: false
        )
      end

      it "sets decision_mailed to true and all others false" do
        subject

        expect(appeal_state.decision_mailed).to eq true
      end
    end
  end

  context "#appeal_cancelled_appeal_state_update_action!" do
    subject { appeal_state.appeal_cancelled_appeal_state_update_action! }

    context "updates the appeal_cancelled attribute" do
      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id,
          hearing_scheduled: true,
          privacy_act_complete: true
        )
      end

      it "sets appeal_cancelled to true and all others false" do
        subject

        expect(appeal_state.hearing_scheduled).to eq false
        expect(appeal_state.privacy_act_complete).to eq false
        expect(appeal_state.appeal_cancelled).to eq true
      end
    end
  end

  context "#hearing_postponed_appeal_state_update!" do
    subject { appeal_state.hearing_postponed_appeal_state_update_action! }

    context "updates the hearing_postponed attribute" do
      include_examples "privacy_act_pending status remains active upon update"

      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id,
          hearing_scheduled: true
        )
      end

      it "sets hearing_postponed to true and all others false" do
        subject

        expect(appeal_state.hearing_scheduled).to eq false
        expect(appeal_state.hearing_postponed).to eq true
      end
    end
  end

  context "#hearing_withdrawn_appeal_state_update!" do
    subject { appeal_state.hearing_withdrawn_appeal_state_update_action! }

    context "updates the hearing_withdrawn attribute" do
      include_examples "privacy_act_pending status remains active upon update"

      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id,
          hearing_scheduled: true
        )
      end

      it "sets hearing_withdrawn to true and all others false" do
        subject

        expect(appeal_state.appeal_docketed).to eq false
        expect(appeal_state.hearing_withdrawn).to eq true
      end
    end
  end
  context "#hearing_scheduled_appeal_state_update!" do
    subject { appeal_state.hearing_scheduled_appeal_state_update_action! }

    context "updates the hearing_scheduled attribute" do
      include_examples "privacy_act_pending status remains active upon update"

      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id,
          appeal_docketed: true
        )
      end

      it "sets hearing_scheduled to true" do
        subject

        expect(appeal_state.hearing_scheduled).to eq true
      end
    end
  end

  context "hearing_held_appeal_state_update_action!" do
    subject { appeal_state.hearing_held_appeal_state_update_action! }

    context "updates the hearing_scheduled attribute" do
      include_examples "privacy_act_pending status remains active upon update"

      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id,
          hearing_scheduled: true
        )
      end

      it "sets hearing_scheduled to true and all others false" do
        expect(appeal_state.hearing_scheduled).to eq true

        subject

        expect(appeal_state.hearing_scheduled).to eq false
      end
    end
  end

  context "#scheduled_in_error_appeal_state_update!" do
    subject { appeal_state.scheduled_in_error_appeal_state_update_action! }

    context "updates the scheduled_in_error attribute" do
      include_examples "privacy_act_pending status remains active upon update"

      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id,
          hearing_scheduled: true
        )
      end

      it "sets scheduled_in_error to true and all others false" do
        subject

        expect(appeal_state.hearing_scheduled).to eq false
        expect(appeal_state.scheduled_in_error).to eq true
      end
    end
  end
end
