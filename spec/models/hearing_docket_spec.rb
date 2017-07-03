describe HearingDocket do
  before do
    Timecop.freeze(Time.utc(2017, 2, 2))
    Time.zone = "America/Chicago"
  end

  let!(:appeal) do
    Generators::Appeal.create(vbms_id: "333222333S")
  end

  let!(:hearing) do
    Generators::Hearing.create(appeal: appeal)
  end

  let(:docket) do
    HearingDocket.new(
      date: 7.days.from_now,
      type: :video,
      regional_office_name: hearing.regional_office_name,
      hearings: [
        hearing
      ]
    )
  end

  context "#to_hash" do
    subject { docket.to_hash.symbolize_keys }

    it "returns a hash" do
      expect(subject.class).to eq(Hash)
      expect(subject[:date]).to eq(docket.date)
      expect(subject[:hearings_hash].length).to eq(1)
      expect(subject[:type]).to eq(:video)
      expect(subject[:regional_office_name]).to eq(hearing.regional_office_name)
    end
  end

  context "#attributes" do
    subject { docket.attributes }
    it "returns a hash" do
      expect(subject.class).to eq(Hash)
    end
  end
end
