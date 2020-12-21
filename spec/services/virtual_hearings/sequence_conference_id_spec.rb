# frozen_string_literal: true

describe VirtualHearings::SequenceConferenceId do
  context ".next" do
    subject { described_class.next }

    it "returns values in sequence" do
      first_value = subject
      second_value = subject
      expect(first_value.to_i).to eq(second_value.to_i - 1)
    end

    it "returns a seven character string starting with '0'" do
      check_value = subject
      expect(check_value.class).to eq String
      expect(check_value.length).to eq 7
      expect(check_value[0]).to eq "0"
    end
  end
end
