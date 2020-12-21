# frozen_string_literal: true

describe VirtualHearings::SequenceConferenceId do
  context ".next" do
    it "returns values in sequence" do
      first_value = described_class.next
      second_value = described_class.next
      expect(first_value.to_i).to eq(second_value.to_i - 1)
    end

    it "returns a seven character string starting with '0'" do
      check_value = described_class.next
      expect(check_value.class).to eq String
      expect(check_value.length).to eq 7
      expect(check_value[0]).to eq "0"
    end

    it "cycles when the last number is reached" do
      sequence_name = VirtualHearings::SequenceConferenceId::SEQUENCE_NAME
      ActiveRecord::Base.connection.execute "SELECT setval('#{sequence_name}', 9999998)"
      first_value = described_class.next
      expect(first_value).to eq "9999999"
      second_value = described_class.next
      expect(second_value).to eq "0000001"
    end
  end
end
