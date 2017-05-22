describe Hearing do
  before do
    Timecop.freeze(Time.utc(2017, 2, 2))
    Time.zone = "America/Chicago"
  end

  context ".load_from_vacols" do
    subject { Hearing.load_from_vacols(hearing_hash, user.vacols_id) }
    let(:appeal) { Generators::Appeal.create }
    let(:user) { Generators::User.create }
    let(:date) { AppealRepository.normalize_vacols_date(7.days.from_now) }
    let(:hearing_hash) do
      OpenStruct.new(
        hearing_venue: "SO62",
        hearing_date: date,
        folder_nr: appeal.vacols_id,
        hearing_type: "V",
        hearing_pkseq: "12345678"
      )
    end

    it "assigns values properly" do
      expect(subject.venue[:city]).to eq("San Antonio")
      expect(subject.type).to eq(:video)
      expect(subject.vacols_record).to eq(hearing_hash)
      expect(subject.date).to eq(date)
      expect(subject.appeal.id).to eq(appeal.id)
      expect(subject.user.id).to eq(user.id)
    end
  end
end
