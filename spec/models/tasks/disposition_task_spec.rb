describe DispositionTask do
  describe "postponement" do
    let(:appeal) { FactoryBot.create(:appeal) }
    let!(:hearing) { FactoryBot.create(:hearing, appeal: appeal) }
    let!(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }
    let!(:hearing_task) { FactoryBot.create(:hearing_task, parent: root_task, appeal: appeal) }
    let!(:disposition_task) { DispositionTask.create_disposition_task!(appeal, hearing_task, hearing) }
    let(:after_disposition_update) { nil }

    let(:params) do
      {
        status: "cancelled",
        business_payloads: {
          values: {
            disposition: "postponed",
            after_disposition_update: after_disposition_update
          }
        }
      }
    end

    context "when hearing should be scheduled later" do
      let(:after_disposition_update) do
        {
          action: "schedule_later"
        }
      end

      it "creates a new HearingTask and ScheduleHearingTask" do
        disposition_task.update_from_params(params, nil)

        expect(Hearing.first.disposition).to eq "postponed"
        expect(HearingTask.count).to eq 2
        expect(HearingTask.first.status).to eq "cancelled"
        expect(DispositionTask.first.status).to eq "cancelled"
        expect(ScheduleHearingTask.count).to eq 1
        expect(ScheduleHearingTask.first.parent.id).to eq HearingTask.last.id
      end
    end

    context "when hearing should be scheduled later with admin action" do
      let(:instructions) { "Fix this." }
      let(:after_disposition_update) do
        {
          action: "schedule_later",
          with_admin_action_klass: "HearingAdminActionIncarceratedVeteranTask",
          admin_action_instructions: instructions
        }
      end

      it "creates a new HearingTask and ScheduleHearingTask with admin action" do
        disposition_task.update_from_params(params, nil)

        expect(Hearing.first.disposition).to eq "postponed"
        expect(HearingTask.count).to eq 2
        expect(HearingTask.first.status).to eq "cancelled"
        expect(DispositionTask.first.status).to eq "cancelled"
        expect(ScheduleHearingTask.count).to eq 1
        expect(ScheduleHearingTask.first.parent.id).to eq HearingTask.last.id
        expect(HearingAdminActionIncarceratedVeteranTask.count).to eq 1
        expect(HearingAdminActionIncarceratedVeteranTask.last.instructions).to eq [instructions]
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
        disposition_task.update_from_params(params, nil)

        expect(Hearing.count).to eq 2
        expect(Hearing.first.disposition).to eq "postponed"
        expect(Hearing.last.hearing_location.facility_id).to eq "vba_370"
        expect(Hearing.last.scheduled_time.strftime("%I:%M%p")).to eq "12:30PM"
        expect(HearingTask.count).to eq 2
        expect(HearingTask.first.status).to eq "cancelled"
        expect(HearingTask.last.hearing_task_association.hearing.id).to eq Hearing.last.id
        expect(DispositionTask.count).to eq 2
        expect(DispositionTask.first.status).to eq "cancelled"
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
end
