describe Hearings::MasterRecord do
  context "#to_hash" do
    subject { master_record.to_hash }
    let(:master_record) do
      Hearings::MasterRecord.new(scheduled_for: Time.zone.local(2015, 4, 5),
                                 request_type: "T",
                                 regional_office_key: "RO07",
                                 master_record: true)
    end

    it "should return attributes" do
      expect(subject[:scheduled_for]).to eq Time.zone.local(2015, 4, 5)
      expect(subject[:request_type]).to eq "T"
      expect(subject[:regional_office_name]).to eq "Buffalo, NY"
      expect(subject[:master_record]).to eq true
    end
  end
end
