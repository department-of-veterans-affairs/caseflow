describe AttorneyQueue do
  before { WorkQueue.repository = Fakes::QueueRepository }

  context ".tasks_with_appeals" do
    let(:user) { User.find_or_create_by(css_id: "DNYGLVR", station_id: "LANCASTER") }

    before do
      Fakes::QueueRepository.appeal_records = [
        Generators::Appeal.build(
          vacols_id: "2222",
          date_assigned: "2013-05-17 00:00:00 UTC".to_datetime,
          date_due: "2018-02-13 00:00:00 UTC".to_datetime,
          docket_date: "2014-03-25 00:00:00 UTC".to_datetime
        ),
        Generators::Appeal.build(
          vacols_id: "3333",
          date_assigned: "2013-05-17 00:00:00 UTC".to_datetime,
          date_due: "2018-02-13 00:00:00 UTC".to_datetime,
          docket_date: "2014-03-25 00:00:00 UTC".to_datetime
        )
      ]
    end

    subject { AttorneyQueue.tasks_with_appeals(user.id) }

    it "returns tasks" do
      expect(subject[0].length).to eq(2)
      expect(subject[0][0].class).to eq(VacolsAssignment)
    end

    it "returns appeals" do
      expect(subject[1].length).to eq(2)
      expect(subject[1][0].class).to eq(Appeal)
    end
  end
end
