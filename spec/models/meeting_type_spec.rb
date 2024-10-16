# frozen_string_literal: true

describe MeetingType, :postgres do
  let(:user) { create(:user, css_id: "NEW_USER") }

  it "Only a valid service_names can be used" do
    expect { described_class.create!(service_name: "Invalid name") }.to raise_error do |error|
      expect(error).to be_a ArgumentError

      expect(error.to_s).to eq "'Invalid name' is not a valid service_name"
    end
  end
end
