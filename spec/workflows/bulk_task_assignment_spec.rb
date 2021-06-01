# frozen_string_literal: true

describe BulkTaskAssignment, :postgres do
  describe "#process" do
    let(:organization) { HearingsManagement.singleton }
    let!(:no_show_hearing_task1) do
      create(
        :no_show_hearing_task,
        assigned_to: organization,
        created_at: 5.days.ago
      )
    end
    let!(:no_show_hearing_task2) do
      create(:no_show_hearing_task,
             assigned_to: organization,
             created_at: 2.days.ago)
    end
    let!(:no_show_hearing_task3) do
      create(:no_show_hearing_task,
             assigned_to: organization,
             created_at: 1.day.ago)
    end

    # Even it is the oldest task, it should skip it because it is on hold
    let!(:no_show_hearing_task4) do
      create(:no_show_hearing_task,
             :on_hold,
             assigned_to: organization,
             created_at: 6.days.ago)
    end

    let(:assigned_to) { create(:user) }
    let(:assigned_by) { create(:user) }

    let(:params) do
      {
        assigned_to_id: assigned_to_param.id,
        assigned_by: assigned_by_param,
        organization_url: organization_url,
        task_type: task_type,
        task_count: task_count,
        regional_office: regional_office
      }
    end
    let(:task_type) { "NoShowHearingTask" }
    let(:organization_url) { organization.url }
    let(:task_count) { 2 }
    let(:regional_office) { nil }
    let(:assigned_by_param) { assigned_by }
    let(:assigned_to_param) { assigned_to }

    before do
      OrganizationsUser.make_user_admin(assigned_by, organization)
      organization.users << assigned_to
    end

    shared_examples "invalid bulk assign" do
      it "does not bulk assigns tasks" do
        bulk_assignment = BulkTaskAssignment.new(params)
        expect(bulk_assignment.valid?).to eq false
        expect(bulk_assignment.errors[error_sym]).to eq [error]
      end
    end

    context "when assigned to user does not belong to organization" do
      let(:assigned_to_param) { create(:user) }
      let(:error) { "does not belong to organization with url #{organization.url}" }
      let(:error_sym) { :assigned_to }

      it_behaves_like "invalid bulk assign"
    end

    context "when assigned by user is not admin of organization" do
      let(:assigned_by_param) { create(:user) }
      let(:error) { "is not admin of organization with url #{organization.url}" }
      let(:error_sym) { :assigned_by }

      it_behaves_like "invalid bulk assign"
    end

    context "when regional office is not valid" do
      let(:regional_office) { "Not Valid" }
      let(:error) { "could not find regional office: #{regional_office}" }
      let(:error_sym) { :regional_office }

      it_behaves_like "invalid bulk assign"
    end

    context "when task type is not valid" do
      let(:task_type) { "UnknownTaskType" }
      let(:error) { "#{task_type} is not a valid task type" }
      let(:error_sym) { :task_type }

      it_behaves_like "invalid bulk assign"
    end

    context "when organization is not valid" do
      let(:organization_url) { 1234 }
      let(:error) { "could not find an organization with url #{organization_url}" }
      let(:error_sym) { :organization_url }

      it_behaves_like "invalid bulk assign"
    end

    context "when all attributes are present" do
      context "when there are legacy appeals and regional office is passed" do
        let(:regional_office) { "RO17" }
        let(:legacy_appeal) { create(:legacy_appeal, closest_regional_office: regional_office) }
        let!(:no_show_hearing_task_with_legacy_appeal) do
          create(:no_show_hearing_task,
                 appeal: legacy_appeal,
                 assigned_to: organization,
                 created_at: 2.days.ago)
        end

        it "filters by regional office" do
          no_show_hearing_task2.appeal.update(closest_regional_office: regional_office)
          no_show_hearing_task3.appeal.update(closest_regional_office: "RO19")
          count_before = Task.count
          bulk_assignment = BulkTaskAssignment.new(params)
          expect(bulk_assignment.valid?).to eq true
          result = bulk_assignment.process
          expect(Task.count).to eq count_before + 2
          expect(result.count).to eq 2
          task_with_ama_appeal = result.find { |task| task.appeal == no_show_hearing_task2.appeal }
          expect(task_with_ama_appeal.assigned_to).to eq assigned_to
          expect(task_with_ama_appeal.type).to eq "NoShowHearingTask"
          expect(task_with_ama_appeal.assigned_by).to eq assigned_by
          expect(task_with_ama_appeal.parent_id).to eq no_show_hearing_task2.id

          task_with_legacy_appeal = result.find { |task| task.appeal == legacy_appeal }
          expect(task_with_legacy_appeal.assigned_to).to eq assigned_to
          expect(task_with_legacy_appeal.type).to eq "NoShowHearingTask"
          expect(task_with_legacy_appeal.assigned_by).to eq assigned_by
        end
      end

      def create_no_show_hearing_task_for_appeal(appeal)
        create(:no_show_hearing_task, appeal: appeal, assigned_to: organization)
      end

      context "when task has instructions" do
        subject { BulkTaskAssignment.new(params).process }

        let(:instructions1) { ["live long"] }
        let(:instructions2) { ["prosper"] }

        before do
          no_show_hearing_task1.update(instructions: instructions1)
          no_show_hearing_task2.update(instructions: instructions2)
        end

        it "copies instructions to assigned task" do
          count_before = Task.count
          subject
          expect(Task.count).to eq count_before + 2
          expect(subject.count).to eq 2

          user_task_1 = subject.find { |task| task.appeal == no_show_hearing_task1.appeal }
          expect(user_task_1.assigned_to).to eq assigned_to
          expect(user_task_1.type).to eq "NoShowHearingTask"
          expect(user_task_1.assigned_by).to eq assigned_by
          expect(user_task_1.parent_id).to eq no_show_hearing_task1.id
          expect(user_task_1.instructions).to eq no_show_hearing_task1.instructions

          user_task_2 = subject.find { |task| task.appeal == no_show_hearing_task2.appeal }
          expect(user_task_2.assigned_to).to eq assigned_to
          expect(user_task_2.type).to eq "NoShowHearingTask"
          expect(user_task_2.assigned_by).to eq assigned_by
          expect(user_task_2.parent_id).to eq no_show_hearing_task2.id
          expect(user_task_2.instructions).to eq no_show_hearing_task2.instructions
        end
      end

      context "when there are priority appeals" do
        let(:regional_office) { nil }
        let(:task_count) { 20 }
        let(:ama_receipt_date) { 4.days.ago }
        let(:legacy_docket_number) { 3.days.ago.strftime("%y%m%d") }

        let(:cavc_appeal) { create(:appeal, :type_cavc_remand, receipt_date: ama_receipt_date) }
        let(:aod_appeal) { create(:appeal, :advanced_on_docket_due_to_motion, receipt_date: ama_receipt_date) }
        let(:cavc_aod_appeal) do
          create(:appeal, :advanced_on_docket_due_to_motion, :type_cavc_remand, receipt_date: ama_receipt_date)
        end
        let(:aod_legacy_appeal) do
          create(:legacy_appeal, vacols_case: create(:case, :aod, folder: build(:folder, tinum: legacy_docket_number)))
        end
        let(:cavc_legacy_appeal) do
          create(
            :legacy_appeal,
            vacols_case: create(:case, :type_cavc_remand, folder: build(:folder, tinum: legacy_docket_number))
          )
        end
        let(:cavc_aod_legacy_appeal) do
          create(
            :legacy_appeal,
            vacols_case: create(:case, :aod, :type_cavc_remand, folder: build(:folder, tinum: legacy_docket_number))
          )
        end

        before do
          create_no_show_hearing_task_for_appeal(aod_appeal)
          create_no_show_hearing_task_for_appeal(cavc_appeal)
          create_no_show_hearing_task_for_appeal(cavc_aod_appeal)
          create_no_show_hearing_task_for_appeal(aod_legacy_appeal)
          create_no_show_hearing_task_for_appeal(cavc_legacy_appeal)
          create_no_show_hearing_task_for_appeal(cavc_aod_legacy_appeal)

          UpdateCachedAppealsAttributesJob.perform_now
        end

        let(:expected_appeal_ordering) do
          [cavc_aod_appeal, cavc_aod_legacy_appeal].sort_by(&:docket_number) +
            [aod_appeal, aod_legacy_appeal].sort_by(&:docket_number) +
            [cavc_appeal, cavc_legacy_appeal].sort_by(&:docket_number)
        end

        subject { BulkTaskAssignment.new(params).process }

        it "sorts priority appeals first, then by docket_number" do
          prioritized_assigned_tasks = subject
          expect(prioritized_assigned_tasks.first(6).map(&:appeal)).to eq(expected_appeal_ordering)

          appeals_of_returned_tasks = prioritized_assigned_tasks.map(&:appeal)
          expect(appeals_of_returned_tasks).to include(no_show_hearing_task1.appeal)
          expect(appeals_of_returned_tasks).to include(no_show_hearing_task2.appeal)
          expect(appeals_of_returned_tasks).to include(no_show_hearing_task3.appeal)
        end

        context "when task_count param is less than the number of AOD and CAVC appeals" do
          let(:task_count) { 2 }
          it "sorts priority appeals first" do
            expect(subject.map(&:appeal)).to eq(expected_appeal_ordering.first(task_count))
          end
        end
      end
    end
  end
end
