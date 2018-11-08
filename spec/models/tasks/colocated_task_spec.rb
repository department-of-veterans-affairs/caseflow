describe ColocatedTask do
  let(:attorney) { User.create(css_id: "CFS456", station_id: User::BOARD_STATION_ID) }
  let!(:staff) { create(:staff, :attorney_role, sdomainid: attorney.css_id) }
  let(:vacols_case) { create(:case) }
  let!(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }

  before do
    RequestStore.store[:current_user] = attorney
  end

  context ".create_many_from_params" do
    context "when all fields are present and it is a legacy appeal" do
      subject do
        ColocatedTask.create_many_from_params([{
                                                assigned_by: attorney,
                                                action: :aoj,
                                                appeal: appeal
                                              },
                                               { assigned_by: attorney,
                                                 action: :poa_clarification,
                                                 appeal: appeal }], attorney)
      end

      it "creates a co-located task successfully and updates VACOLS location" do
        expect(subject.first.valid?).to be true
        expect(subject.first.reload.status).to eq "assigned"
        expect(subject.first.assigned_at).to_not eq nil
        expect(subject.first.assigned_by).to eq attorney
        expect(subject.first.action).to eq "aoj"
        expect(subject.first.assigned_to).to eq User.find_by(css_id: "BVATEST1")

        expect(subject.second.valid?).to be true
        expect(subject.second.reload.status).to eq "assigned"
        expect(subject.second.assigned_at).to_not eq nil
        expect(subject.second.assigned_by).to eq attorney
        expect(subject.second.action).to eq "poa_clarification"
        expect(subject.second.assigned_to).to eq User.find_by(css_id: "BVATEST1")

        expect(vacols_case.reload.bfcurloc).to eq "CASEFLOW"

        record = ColocatedTask.create_many_from_params([{ assigned_by: attorney, action: :aoj, appeal: appeal }],
                                                       attorney)
        expect(record.first.assigned_to).to eq User.find_by(css_id: "BVATEST2")

        record = ColocatedTask.create_many_from_params([{ assigned_by: attorney, action: :aoj, appeal: appeal }],
                                                       attorney)
        expect(record.first.assigned_to).to eq User.find_by(css_id: "BVATEST3")

        # should start from index 0
        record = ColocatedTask.create_many_from_params([{ assigned_by: attorney, action: :aoj, appeal: appeal }],
                                                       attorney)
        expect(record.first.assigned_to).to eq User.find_by(css_id: "BVATEST1")
      end
    end

    context "when all fields are present and it is an ama appeal" do
      subject do
        ColocatedTask.create_many_from_params([{
                                                assigned_by: attorney,
                                                action: :aoj,
                                                parent: create(:ama_attorney_task),
                                                appeal: create(:appeal)
                                              }], attorney)
      end

      it "creates a co-located task successfully and does not update VACOLS location" do
        expect(subject.first.valid?).to be true
        expect(subject.first.reload.status).to eq "assigned"
        expect(subject.first.assigned_at).to_not eq nil
        expect(subject.first.assigned_by).to eq attorney
        expect(subject.first.action).to eq "aoj"
        expect(subject.first.assigned_to).to eq User.find_by(css_id: "BVATEST1")

        expect(AppealRepository).to_not receive(:update_location!)
      end
    end

    context "when appeal is missing" do
      subject do
        ColocatedTask.create_many_from_params([{
                                                assigned_by: attorney,
                                                action: :aoj
                                              }], attorney)
      end
      it "does not create a co-located task" do
        expect(subject.first.valid?).to be false
        expect(subject.first.errors.full_messages).to eq ["Appeal can't be blank"]
      end
    end

    context "when assigned by is not an attorney" do
      let(:judge) { FactoryBot.create(:user) }

      before do
        FactoryBot.create(:staff, :judge_role, sdomainid: judge.css_id)
        FeatureToggle.enable!(:judge_assignment_to_attorney, users: [judge.css_id])
      end

      subject do
        ColocatedTask.create_many_from_params([{
                                                assigned_by: judge,
                                                action: :aoj,
                                                appeal: appeal
                                              }], judge)
      end
      it "does not create a co-located task" do
        expect(subject.first.valid?).to be false
        expect(subject.first.errors.full_messages).to eq ["Assigned by has to be an attorney"]
      end
    end

    context "when action is not valid" do
      subject do
        ColocatedTask.create_many_from_params([{
                                                assigned_by: attorney,
                                                action: :test,
                                                appeal: appeal
                                              }], attorney)
      end
      it "does not create a co-located task" do
        expect(subject.first.valid?).to be false
        expect(subject.first.errors.full_messages).to eq ["Action is not included in the list"]
      end
    end
  end

  context ".update" do
    let(:colocated_admin_action) { create(:colocated_task) }

    context "when status is updated to on-hold" do
      it "should validate on-hold duration" do
        colocated_admin_action.update(status: "on_hold")
        expect(colocated_admin_action.valid?).to eq false
        expect(colocated_admin_action.errors.messages[:on_hold_duration]).to eq ["has to be specified"]

        colocated_admin_action.update(status: "in_progress")
        expect(colocated_admin_action.valid?).to eq true

        colocated_admin_action.update(status: "on_hold", on_hold_duration: 60)
        expect(colocated_admin_action.valid?).to eq true
      end
    end

    context "when status is updated to completed" do
      let!(:staff) { create(:staff, :attorney_role, sdomainid: attorney.css_id) }
      let(:colocated_admin_action) do
        ColocatedTask.create_many_from_params([{
                                                appeal: appeal,
                                                appeal_type: "LegacyAppeal",
                                                assigned_by: attorney,
                                                assigned_to: create(:user),
                                                action: action
                                              }], attorney).first
      end

      context "when more than one task per appeal and not all colocated tasks are completed" do
        let(:action) { :poa_clarification }

        let!(:colocated_admin_action2) do
          ColocatedTask.create_many_from_params([{
                                                  appeal: appeal,
                                                  appeal_type: "LegacyAppeal",
                                                  assigned_by: attorney,
                                                  assigned_to: create(:user),
                                                  action: :poa_clarification
                                                }], attorney).first
        end

        it "should not update location to assignor in vacols" do
          colocated_admin_action.update(status: "completed")
          expect(vacols_case.reload.bfcurloc).to_not eq staff.slogid
        end
      end

      context "when completing a translation task" do
        let(:action) { :translation }
        it "should update location to translation in vacols" do
          expect(vacols_case.bfcurloc).to_not eq staff.slogid
          colocated_admin_action.update!(status: "completed")
          expect(vacols_case.reload.bfcurloc).to eq LegacyAppeal::LOCATION_CODES[:translation]
        end
      end

      context "when completing a schedule hearing task" do
        let(:action) { :schedule_hearing }
        it "should update location to schedule hearing in vacols" do
          expect(vacols_case.bfcurloc).to_not eq staff.slogid
          colocated_admin_action.update!(status: "completed")
          expect(vacols_case.reload.bfcurloc).to eq LegacyAppeal::LOCATION_CODES[:schedule_hearing]
        end
      end

      context "when all colocated tasks are completed for this appeal" do
        let(:judge) { create(:user) }
        let!(:staff2) { create(:staff, :judge_role, sdomainid: judge.css_id) }
        let(:action) { :poa_clarification }

        let!(:task2) do
          AttorneyTask.create!(
            appeal: appeal,
            appeal_type: "LegacyAppeal",
            assigned_by: judge,
            assigned_to: attorney
          )
        end

        it "should update location to assignor in vacols" do
          expect(vacols_case.bfcurloc).to_not eq staff.slogid
          colocated_admin_action.update!(status: "completed")
          expect(vacols_case.reload.bfcurloc).to eq staff.slogid
        end
      end
    end

    context "when status is updated" do
      it "should reset timestamps only if status has changed" do
        time1 = Time.utc(2015, 1, 1, 12, 0, 0)
        Timecop.freeze(time1)
        colocated_admin_action.update(status: "in_progress")
        expect(colocated_admin_action.reload.started_at).to eq time1

        time2 = Time.utc(2015, 1, 3, 12, 0, 0)
        Timecop.freeze(time2)
        colocated_admin_action.update(status: "in_progress")
        # time should not change
        expect(colocated_admin_action.reload.started_at).to eq time1

        time3 = Time.utc(2015, 1, 5, 12, 0, 0)
        Timecop.freeze(time3)
        colocated_admin_action.update(status: "on_hold", on_hold_duration: 30)
        expect(colocated_admin_action.reload.started_at).to eq time1
        expect(colocated_admin_action.placed_on_hold_at).to eq time3

        time4 = Time.utc(2015, 1, 6, 12, 0, 0)
        Timecop.freeze(time4)
        colocated_admin_action.update(status: "on_hold", on_hold_duration: 30)
        # neither dates should change
        expect(colocated_admin_action.reload.started_at).to eq time1
        expect(colocated_admin_action.placed_on_hold_at).to eq time3

        time5 = Time.utc(2015, 1, 7, 12, 0, 0)
        Timecop.freeze(time5)
        colocated_admin_action.update(status: "in_progress")
        # go back to in-progres - should reset date
        expect(colocated_admin_action.reload.started_at).to eq time5
        expect(colocated_admin_action.placed_on_hold_at).to eq time3

        time6 = Time.utc(2015, 1, 8, 12, 0, 0)
        Timecop.freeze(time6)
        colocated_admin_action.update(status: "completed")
        # go back to in-progres - should reset date
        expect(colocated_admin_action.reload.started_at).to eq time5
        expect(colocated_admin_action.placed_on_hold_at).to eq time3
        expect(colocated_admin_action.completed_at).to eq time6

        time7 = Time.utc(2015, 1, 9, 12, 0, 0)
        Timecop.freeze(time7)
        colocated_admin_action.update(status: "assigned")
        # go back to in-progres - should reset date
        expect(colocated_admin_action.reload.started_at).to eq time5
        expect(colocated_admin_action.placed_on_hold_at).to eq time3
        expect(colocated_admin_action.completed_at).to eq time6
      end
    end
  end

  describe ".available_actions_unwrapper" do
    let(:colocated_task) { ColocatedTask.find(FactoryBot.create(:colocated_task, assigned_by: attorney).id) }
    let(:colocated_user) { FactoryBot.create(:user) }
    before { FactoryBot.create(:staff, :colocated_role, user: colocated_user) }

    it "should vary depending on status of task" do
      expect(colocated_task.available_actions_unwrapper(colocated_user).count).to_not eq(0)

      colocated_task.update!(status: Constants.TASK_STATUSES.completed)
      expect(colocated_task.available_actions_unwrapper(colocated_user).count).to eq(0)
    end
  end
end
