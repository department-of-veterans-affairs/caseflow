describe Hearing do
  before do
    Timecop.freeze(Time.utc(2017, 2, 2))
    Time.zone = "America/Chicago"
  end

  context ".load_from_vacols" do
    subject { Hearing.load_from_vacols(hearing_hash) }
    let(:appeal) { Generators::Appeal.create }
    let(:user) { Generators::User.create }
    let(:date) { AppealRepository.normalize_vacols_date(7.days.from_now) }
    let(:hearing_hash) do
      OpenStruct.new(
        user_id: user.vacols_id,
        hearing_venue: "SO62",
        hearing_date: date,
        folder_nr: appeal.vacols_id,
        hearing_type: "V",
        hearing_pkseq: "12345678",
        hearing_disp: "N"
      )
    end

    it "assigns values properly" do
      expect(subject.venue[:city]).to eq("San Antonio")
      expect(subject.type).to eq(:video)
      expect(subject.vacols_record).to eq(hearing_hash)
      expect(subject.date).to eq(date)
      expect(subject.appeal.id).to eq(appeal.id)
      expect(subject.user.id).to eq(user.id)
      expect(subject.disposition).to eq(:no_show)
    end
  end

  context ".update" do
    subject { hearing.update(hearing_hash) }
    let(:hearing) { Generators::Hearing.build }
    let(:issue) { hearing.appeal.issues.first }
    let(:hearing_hash) do
      {
        worksheet_military_service: "Vietnam 1968 - 1970",
        issues_attributes: [
          {
            hearing_worksheet_status: :remand,
            hearing_worksheet_vha: true
          }
        ]
      }
    end

    it "updates nested attributes (issues)" do
      expect(hearing.issues.count).to eq(0)
      subject # do update
      expect(hearing.issues.count).to eq(1)

      expect(hearing.issues.first.hearing_worksheet_status).to eq("remand")
      expect(hearing.issues.first.hearing_worksheet_vha).to be_truthy

      # test that a 2nd save updates the same record, rather than create new one
      hearing_issue_id = hearing.issues.first.id
      hearing_hash[:issues_attributes][0][:hearing_worksheet_status] = :deny
      hearing_hash[:issues_attributes][0][:id] = hearing_issue_id

      hearing.update(hearing_hash)

      expect(hearing.issues.count).to eq(1)
      expect(hearing.issues.first.id).to eq(hearing_issue_id)
      expect(hearing.issues.first.hearing_worksheet_status).to eq("deny")
    end
  end
end
