# frozen_string_literal: true

describe DispositionTask do
  describe "#update_from_params for ama appeal" do
    let(:appeal) { FactoryBot.create(:appeal) }
    let!(:hearing) { FactoryBot.create(:hearing, appeal: appeal) }
    let!(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }
    let!(:hearing_task) { FactoryBot.create(:hearing_task, parent: root_task, appeal: appeal) }
    let!(:disposition_task) { DispositionTask.create_disposition_task!(appeal, hearing_task, hearing) }
    let(:after_disposition_update) { nil }
    let(:user) { FactoryBot.create(:user) }
    let(:params) { nil }

    subject { disposition_task.update_from_params(params, user) }

    before do
      OrganizationsUser.add_user_to_organization(user, HearingsManagement.singleton)
    end

    describe "hearing disposition of cancelled" do
      let(:params) do
        {
          status: Constants.TASK_STATUSES.cancelled,
          business_payloads: {
            values: {
              disposition: Constants.HEARING_DISPOSITION_TYPES.cancelled
            }
          }
        }.with_indifferent_access
      end

      it "sets the hearing disposition and calls cancel!" do
        expect(disposition_task).to receive(:cancel!).exactly(1).times

        subject

        expect(Hearing.count).to eq 1
        expect(hearing.disposition).to eq Constants.HEARING_DISPOSITION_TYPES.cancelled
      end
    end

    describe "hearing disposition of held" do
      let(:params) do
        {
          status: Constants.TASK_STATUSES.cancelled,
          business_payloads: {
            values: {
              disposition: Constants.HEARING_DISPOSITION_TYPES.held
            }
          }
        }.with_indifferent_access
      end

      it "sets the hearing disposition and calls hold!" do
        expect(disposition_task).to receive(:hold!).exactly(1).times

        subject

        expect(Hearing.count).to eq 1
        expect(hearing.disposition).to eq Constants.HEARING_DISPOSITION_TYPES.held
      end
    end

    describe "hearing disposition of no_show" do
      let(:params) do
        {
          status: Constants.TASK_STATUSES.cancelled,
          business_payloads: {
            values: {
              disposition: Constants.HEARING_DISPOSITION_TYPES.no_show
            }
          }
        }.with_indifferent_access
      end

      it "sets the hearing disposition and calls no_show!" do
        expect(disposition_task).to receive(:no_show!).exactly(1).times

        subject

        expect(Hearing.count).to eq 1
        expect(hearing.disposition).to eq Constants.HEARING_DISPOSITION_TYPES.no_show
      end
    end

    describe "hearing disposition of postponed" do
      let(:params) do
        {
          status: Constants.TASK_STATUSES.cancelled,
          business_payloads: {
            values: {
              disposition: Constants.HEARING_DISPOSITION_TYPES.postponed,
              after_disposition_update: after_disposition_update
            }
          }
        }.with_indifferent_access
      end

      context "when hearing should be scheduled later" do
        let(:after_disposition_update) do
          {
            action: "schedule_later"
          }
        end

        it "creates a new HearingTask and ScheduleHearingTask" do
          subject

          expect(Hearing.count).to eq 1
          expect(hearing.disposition).to eq Constants.HEARING_DISPOSITION_TYPES.postponed
          expect(HearingTask.count).to eq 2
          expect(HearingTask.first.cancelled?).to be_truthy
          expect(HearingTask.last.on_hold?).to be_truthy
          expect(DispositionTask.first.cancelled?).to be_truthy
          expect(ScheduleHearingTask.count).to eq 1
          expect(ScheduleHearingTask.first.parent.id).to eq HearingTask.last.id
        end

        context "when task instructions are passed" do
          let(:instructions_text) { "My informative task instructions" }
          before do
            params[:instructions] = instructions_text
          end

          it "adds the instructions to both the DispositionTask and the ScheduleHearingTask" do
            subject

            expect(DispositionTask.first.cancelled?).to be_truthy
            expect(DispositionTask.first.instructions).to eq [instructions_text]
            expect(ScheduleHearingTask.count).to eq 1
            expect(ScheduleHearingTask.first.instructions).to eq [instructions_text]
          end
        end
      end

      context "when hearing should be scheduled later with admin action" do
        let(:admin_action_instructions) { "Fix this." }
        let(:after_disposition_update) do
          {
            action: "schedule_later",
            with_admin_action_klass: "HearingAdminActionIncarceratedVeteranTask",
            admin_action_instructions: admin_action_instructions
          }
        end

        it "creates a new HearingTask and ScheduleHearingTask with admin action" do
          subject

          expect(Hearing.count).to eq 1
          expect(hearing.disposition).to eq Constants.HEARING_DISPOSITION_TYPES.postponed
          expect(HearingTask.count).to eq 2
          expect(HearingTask.first.cancelled?).to be_truthy
          expect(DispositionTask.first.cancelled?).to be_truthy
          expect(ScheduleHearingTask.count).to eq 1
          expect(ScheduleHearingTask.first.parent.id).to eq HearingTask.last.id
          expect(HearingAdminActionIncarceratedVeteranTask.count).to eq 1
          expect(HearingAdminActionIncarceratedVeteranTask.last.instructions).to eq [admin_action_instructions]
        end
      end

      context "when hearing should be resecheduled" do
        let(:after_disposition_update) do
          {
            action: "reschedule",
            new_hearing_attrs: {
              hearing_day_id: HearingDay.first.id,
              hearing_location: { facility_id: "vba_370", distance: 10 },
              hearing_time: { h: "12", m: "30", offset: "-05:00" }
            }
          }
        end

        it "creates a new hearing with a new DispositionTask" do
          subject

          expect(Hearing.count).to eq 2
          expect(hearing.disposition).to eq Constants.HEARING_DISPOSITION_TYPES.postponed
          expect(Hearing.last.hearing_location.facility_id).to eq "vba_370"
          expect(Hearing.last.scheduled_time.strftime("%I:%M%p")).to eq "12:30PM"
          expect(HearingTask.count).to eq 2
          expect(HearingTask.first.cancelled?).to be_truthy
          expect(HearingTask.last.hearing_task_association.hearing.id).to eq Hearing.last.id
          expect(DispositionTask.count).to eq 2
          expect(DispositionTask.first.cancelled?).to be_truthy
        end
      end
    end
  end

  describe ".create_disposition_task!" do
    let(:appeal) { FactoryBot.create(:appeal) }
    let(:parent) { nil }
    let!(:hearing) { FactoryBot.create(:hearing, appeal: appeal) }

    subject { described_class.create_disposition_task!(appeal, parent, hearing) }

    context "parent is a HearingTask" do
      let(:parent) { FactoryBot.create(:hearing_task, appeal: appeal) }

      it "creates a DispositionTask and a HearingTaskAssociation" do
        expect(DispositionTask.all.count).to eq 0
        expect(HearingTaskAssociation.all.count).to eq 0

        subject

        expect(DispositionTask.all.count).to eq 1
        expect(DispositionTask.first.appeal).to eq appeal
        expect(DispositionTask.first.parent).to eq parent
        expect(DispositionTask.first.assigned_to).to eq Bva.singleton
        expect(HearingTaskAssociation.all.count).to eq 1
        expect(HearingTaskAssociation.first.hearing).to eq hearing
        expect(HearingTaskAssociation.first.hearing_task).to eq parent
      end
    end

    context "parent is a RootTask" do
      let(:parent) { FactoryBot.create(:root_task, appeal: appeal) }

      it "should throw an error" do
        expect { subject }.to raise_error(Caseflow::Error::InvalidParentTask)
      end
    end
  end

  describe ".create_change_hearing_disposition_task_and_complete" do
    let(:appeal) { FactoryBot.create(:appeal) }
    let(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }
    let(:hearing_task) { FactoryBot.create(:hearing_task, parent: root_task, appeal: appeal) }
    let!(:disposition_task) do
      FactoryBot.create(
        :disposition_task,
        parent: hearing_task,
        appeal: appeal,
        status: Constants.TASK_STATUSES.in_progress
      )
    end

    subject { disposition_task.create_change_hearing_disposition_task_and_complete }

    it "completes the disposition task and creates a new change hearing disposition task" do
      expect(disposition_task.status).to_not eq Constants.TASK_STATUSES.completed
      expect(ChangeHearingDispositionTask.count).to eq 0

      subject

      expect(disposition_task.status).to eq Constants.TASK_STATUSES.completed
      expect(ChangeHearingDispositionTask.count).to eq 1
      change_hearing_disposition_task = ChangeHearingDispositionTask.first
      expect(change_hearing_disposition_task.appeal).to eq appeal
      expect(change_hearing_disposition_task.parent).to eq hearing_task
    end
  end

  context "disposition updates" do
    let(:disposition) { nil }
    let(:appeal) { FactoryBot.create(:appeal) }
    let(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }
    let(:hearing_task) { FactoryBot.create(:hearing_task, parent: root_task, appeal: appeal) }
    let(:evidence_window_waived) { nil }
    let(:hearing_scheduled_for) { appeal.receipt_date + 15.days }
    let(:hearing_day) { create(:hearing_day, scheduled_for: hearing_scheduled_for) }
    let(:hearing) do
      FactoryBot.create(
        :hearing,
        appeal: appeal,
        disposition: disposition,
        evidence_window_waived: evidence_window_waived,
        hearing_day: hearing_day
      )
    end
    let!(:hearing_task_association) do
      FactoryBot.create(
        :hearing_task_association,
        hearing: hearing,
        hearing_task: hearing_task
      )
    end
    let!(:schedule_hearing_task) do
      FactoryBot.create(
        :schedule_hearing_task,
        parent: hearing_task,
        appeal: appeal,
        status: Constants.TASK_STATUSES.completed
      )
    end
    let!(:disposition_task) do
      FactoryBot.create(
        :disposition_task,
        parent: hearing_task,
        appeal: appeal,
        status: Constants.TASK_STATUSES.in_progress
      )
    end

    describe ".cancel!" do
      subject { disposition_task.cancel! }

      context "the appeal is an AMA appeal" do
        context "the task's hearing's disposition is canceled" do
          let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.cancelled }

          it "cancels the disposition task and its parent hearing task" do
            expect(disposition_task.cancelled?).to be_falsey
            expect(hearing_task.on_hold?).to be_truthy

            expect { subject }.to_not raise_error

            expect(disposition_task.reload.cancelled?).to be_truthy
            expect(hearing_task.reload.cancelled?).to be_truthy
            expect(InformalHearingPresentationTask.where(appeal: appeal).length).to eq 0
          end

          context "the appeal has a VSO" do
            let(:participant_id_with_pva) { "000000" }
            let(:appeal) do
              create(:appeal, claimants: [create(:claimant, participant_id: participant_id_with_pva)])
            end

            before do
              Vso.create(
                name: "Paralyzed Veterans Of America",
                role: "VSO",
                url: "paralyzed-veterans-of-america",
                participant_id: "2452383"
              )

              allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids)
                .with([participant_id_with_pva]).and_return(
                  participant_id_with_pva => {
                    representative_name: "PARALYZED VETERANS OF AMERICA, INC.",
                    representative_type: "POA National Organization",
                    participant_id: "2452383"
                  }
                )
            end

            it "creates an IHP task" do
              expect(InformalHearingPresentationTask.where(appeal: appeal).length).to eq 0

              subject

              expect(InformalHearingPresentationTask.where(appeal: appeal).length).to eq 1
            end
          end
        end

        context "the task's hearing's disposition is not canceled" do
          let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.postponed }

          it "raises an error" do
            expect(disposition_task.cancelled?).to be_falsey

            expect { subject }.to raise_error(DispositionTask::HearingDispositionNotCanceled)

            expect(disposition_task.cancelled?).to be_falsey
          end
        end
      end

      context "the appeal is a legacy appeal" do
        let(:vacols_case) { FactoryBot.create(:case, bfcurloc: LegacyAppeal::LOCATION_CODES[:schedule_hearing]) }
        let(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
        let(:hearing) { create(:legacy_hearing, appeal: appeal, disposition: disposition) }
        let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.cancelled }

        context "there's no associated VSO" do
          it "updates the case location to case storage (81)" do
            subject

            expect(vacols_case.reload.bfcurloc).to eq(LegacyAppeal::LOCATION_CODES[:case_storage])
          end
        end

        context "there is an associated VSO" do
          let(:participant_id) { "1234" }
          let!(:vso) { create(:vso, name: "Gogozim", participant_id: participant_id) }

          before do
            allow(BGSService).to receive(:power_of_attorney_records).and_return(
              appeal.veteran_file_number => {
                file_number: appeal.veteran_file_number,
                power_of_attorney: {
                  legacy_poa_cd: "3QQ",
                  nm: "Clarence Darrow",
                  org_type_nm: "POA Attorney",
                  ptcpnt_id: participant_id
                }
              }
            )
          end

          it "updates the case location to service organization (55)" do
            subject

            expect(vacols_case.reload.bfcurloc).to eq(LegacyAppeal::LOCATION_CODES[:service_organization])
          end
        end
      end
    end

    describe ".postpone!" do
      subject { disposition_task.postpone! }

      context "the hearing's disposition is 'postponed'" do
        let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.postponed }

        it "creates a new HearingTask and ScheduleHearingTask" do
          subject

          expect(Hearing.count).to eq 1
          expect(hearing.disposition).to eq Constants.HEARING_DISPOSITION_TYPES.postponed
          expect(HearingTask.count).to eq 2
          expect(hearing_task.reload.cancelled?).to be_truthy
          expect(HearingTask.last.on_hold?).to be_truthy
          expect(disposition_task.reload.cancelled?).to be_truthy
          expect(ScheduleHearingTask.count).to eq 2
          expect(ScheduleHearingTask.last.parent.id).to eq HearingTask.last.id
        end
      end

      context "the hearing's disposition is nil" do
        let(:disposition) { nil }

        it "raises an error" do
          expect { subject }.to raise_error DispositionTask::HearingDispositionNotPostponed

          expect(disposition_task.status).to eq Constants.TASK_STATUSES.in_progress
        end
      end
    end

    describe ".no_show!" do
      subject { disposition_task.no_show! }

      context "the hearing's diposition is 'no_show'" do
        let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.no_show }

        it "marks the disposition task as no_show" do
          expect(disposition_task.in_progress?).to be_truthy
          expect(NoShowHearingTask.count).to eq 0

          subject

          expect(disposition_task.reload.on_hold?).to be_truthy
          no_show_hearing_task = NoShowHearingTask.first
          expect(no_show_hearing_task).to_not be_nil
          expect(no_show_hearing_task.placed_on_hold_at).to_not be_nil
          expect(no_show_hearing_task.on_hold_expired?).to be_falsey
          expect(no_show_hearing_task.reload.on_hold?).to be_truthy
          expect(no_show_hearing_task.on_hold_duration).to eq 25
        end
      end

      context "the hearing's disposition is nil" do
        let(:disposition) { nil }

        it "raises an error" do
          expect { subject }.to raise_error DispositionTask::HearingDispositionNotNoShow

          expect(disposition_task.reload.in_progress?).to be_truthy
        end
      end
    end

    describe ".hold!" do
      subject { disposition_task.hold! }

      context "the appeal is an AMA appeal" do
        context "the task's hearing's disposition is held" do
          let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.held }

          context "the evidence window has not been waived" do
            let(:evidence_window_waived) { false }

            it "creates a TranscriptionTask and an EvidenceSubmissionWindowTask as children of the DispositionTask" do
              expect(disposition_task.children.count).to eq 0

              expect { subject }.to_not raise_error

              expect(disposition_task.children.count).to eq 2
              expect(disposition_task.children.pluck(:type)).to match_array [
                TranscriptionTask.name, EvidenceSubmissionWindowTask.name
              ]
              transcription_task = disposition_task.children.find_by(type: TranscriptionTask.name)
              expect(transcription_task.parent).to eq disposition_task
              expect(transcription_task.appeal).to eq appeal
              expect(transcription_task.assigned_to).to eq TranscriptionTeam.singleton
              window_task = disposition_task.children.find_by(type: EvidenceSubmissionWindowTask.name)
              expect(window_task.parent).to eq disposition_task
              expect(window_task.appeal).to eq appeal
              expect(window_task.assigned_to).to eq MailTeam.singleton
              expect(window_task.timer_ends_at).to eq hearing_scheduled_for + 90.days
              expect(disposition_task.reload.on_hold?).to be_truthy
            end
          end

          context "the hearing has marked the evidence window waived" do
            let(:evidence_window_waived) { true }

            it "creates a TranscriptionTask as a child of the DispositionTask" do
              expect(disposition_task.children.count).to eq 0

              expect { subject }.to_not raise_error

              expect(disposition_task.children.count).to eq 1
              expect(disposition_task.children.first.type).to eq TranscriptionTask.name
              transcription_task = disposition_task.children.first
              expect(transcription_task.parent).to eq disposition_task
              expect(transcription_task.appeal).to eq appeal
              expect(transcription_task.assigned_to).to eq TranscriptionTeam.singleton
            end
          end
        end

        context "the task's hearing's disposition is not held" do
          let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.postponed }

          it "raises an error" do
            expect(disposition_task.children.count).to eq 0

            expect { subject }.to raise_error(DispositionTask::HearingDispositionNotHeld)

            expect(disposition_task.children.count).to eq 0
          end
        end
      end

      context "the appeal is a legacy appeal" do
        let(:vacols_case) { FactoryBot.create(:case, bfcurloc: LegacyAppeal::LOCATION_CODES[:schedule_hearing]) }
        let(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
        let(:hearing) { create(:legacy_hearing, appeal: appeal, disposition: disposition) }
        let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.cancelled }

        context "the task's hearing's disposition is held" do
          let(:disposition) { Constants.HEARING_DISPOSITION_TYPES.held }

          it "completes the DispositionTask, closes the HearingTask, and updates the appeal location" do
            expect(disposition_task.in_progress?).to be_truthy
            expect(hearing_task.on_hold?).to be_truthy

            subject

            expect(disposition_task.reload.completed?).to be_truthy
            expect(hearing_task.reload.completed?).to be_truthy
            expect(vacols_case.reload.bfcurloc).to eq(LegacyAppeal::LOCATION_CODES[:transcription])
          end
        end
      end
    end
  end
end
