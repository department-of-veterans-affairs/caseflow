describe HearingRepository do
  before do
    @old_repo = Hearing.repository
    Hearing.repository = HearingRepository
    allow(HearingRepository).to receive(:load_vacols_data).and_return(nil)
  end

  after { Hearing.repository = @old_repo }

  let(:vacols_record) do
    OpenStruct.new(
      hearing_venue: "RO17",
      hearing_date: 10.days.ago,
      hearing_disp: "H",
      notes1: "Veteran will bring witness",
      hearing_type: "V",
      folder_nr: "1235839",
      vdkey: "12334",
      aod: "G",
      holddays: "30",
      tranreq: "N",
      addon: "Y",
      board_member: "1234",
      mduser: "1234",
      mdtime: 10.days.ago,
      sattyid: "123"
    )
  end

  let(:hearing) { Hearing.new }

  context ".set_vacols_values" do
    subject { HearingRepository.set_vacols_values(hearing, vacols_record) }

    it "sets vacols attr accessors" do
      expect(subject.vacols_record).to eq(vacols_record)
      expect(subject.disposition).to eq(:held)
      expect(subject.aod).to eq(:granted)
      expect(subject.hold_open).to eq("30")
      expect(subject.transcript_requested).to eq(false)
      expect(subject.add_on).to eq(true)
      expect(subject.notes).to eq(vacols_record.notes1)
      expect(subject.type).to eq(:video)
    end
  end
end
