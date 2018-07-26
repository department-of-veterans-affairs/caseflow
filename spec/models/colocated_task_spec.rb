describe ColocatedTask do
  let(:attorney) { User.create(css_id: "CFS456", station_id: User::BOARD_STATION_ID) }
  let!(:staff) { create(:staff, :attorney_role, sdomainid: attorney.css_id) }
  let(:vacols_case) { create(:case) }
  let!(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }

  before do
    RequestStore.store[:current_user] = attorney
    FeatureToggle.enable!(:test_facols)
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  context ".create" do
    context "when all fields are present" do
      subject do
        ColocatedTask.create([{
                               assigned_by: attorney,
                               title: :aoj,
                               appeal: appeal
                             },
                              { assigned_by: attorney,
                                title: :poa_clarification,
                                appeal: appeal }])
      end

      it "creates a co-located task successfully" do
        expect(subject.first.valid?).to be true
        expect(subject.first.reload.status).to eq "assigned"
        expect(subject.first.assigned_at).to_not eq nil
        expect(subject.first.assigned_by).to eq attorney
        expect(subject.first.title).to eq "aoj"
        expect(subject.first.assigned_to).to eq User.find_by(css_id: "BVATEST1")

        expect(subject.second.valid?).to be true
        expect(subject.second.reload.status).to eq "assigned"
        expect(subject.second.assigned_at).to_not eq nil
        expect(subject.second.assigned_by).to eq attorney
        expect(subject.second.title).to eq "poa_clarification"
        expect(subject.second.assigned_to).to eq User.find_by(css_id: "BVATEST1")

        expect(vacols_case.reload.bfcurloc).to eq "CASEFLOW"

        record = ColocatedTask.create(assigned_by: attorney, title: :aoj, appeal: appeal)
        expect(record.first.assigned_to).to eq User.find_by(css_id: "BVATEST2")

        record = ColocatedTask.create(assigned_by: attorney, title: :aoj, appeal: appeal)
        expect(record.first.assigned_to).to eq User.find_by(css_id: "BVATEST3")

        # should start from index 0
        record = ColocatedTask.create(assigned_by: attorney, title: :aoj, appeal: appeal)
        expect(record.first.assigned_to).to eq User.find_by(css_id: "BVATEST1")
      end
    end

    context "when appeal is missing" do
      subject do
        ColocatedTask.create(
          assigned_by: attorney,
          title: :aoj
        )
      end
      it "does not create a co-located task" do
        expect(subject.first.valid?).to be false
        expect(subject.first.errors.full_messages).to eq ["Appeal can't be blank"]
      end
    end

    context "when assigned by is not an attorney" do
      before do
        allow_any_instance_of(User).to receive(:vacols_roles).and_return(["judge"])
      end

      subject do
        ColocatedTask.create(
          assigned_by: attorney,
          title: :aoj,
          appeal: appeal
        )
      end
      it "does not create a co-located task" do
        expect(subject.first.valid?).to be false
        expect(subject.first.errors.full_messages).to eq ["Assigned by has to be an attorney"]
      end
    end

    context "when title is not valid" do
      subject do
        ColocatedTask.create(
          assigned_by: attorney,
          title: :test,
          appeal: appeal
        )
      end
      it "does not create a co-located task" do
        expect(subject.first.valid?).to be false
        expect(subject.first.errors.full_messages).to eq ["Title is not included in the list"]
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
      let(:colocated_admin_action) do
        create(:colocated_task, appeal: appeal, appeal_type: appeal_type, assigned_by: attorney)
      end

      context "when more than one task per appeal and not all tasks are completed" do
        let(:appeal_type) { "LegacyAppeal" }

        let!(:colocated_admin_action2) do
          create(:colocated_task, appeal: appeal, appeal_type: appeal_type, assigned_by: attorney)
        end

        it "should not update location in vacols" do
          colocated_admin_action.update(status: "completed")
          expect(vacols_case.reload.bfcurloc).to_not eq staff.slogid
        end
      end

      context "when legacy appeal" do
        let(:appeal_type) { "LegacyAppeal" }

        it "should update location in vacols" do
          expect(vacols_case.bfcurloc).to_not eq staff.slogid
          colocated_admin_action.update(status: "completed")
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
      end
    end
  end
end
