# frozen_string_literal: true

describe ApiKey, :postgres do
  context ".create!" do
    subject { ApiKey.create!(consumer_name: "CaseSlow") }

    it "creates a key and digest" do
      expect(subject.key_string.length > 30).to be_truthy
      expect(subject.reload.key_digest).to be_truthy
    end
  end

  context ".authorize" do
    subject { ApiKey.authorize(key_string) }
    let(:api_key) { ApiKey.create!(consumer_name: "CaseSlow") }

    context "when key is not authorized" do
      let(:key_string) { api_key.key_string + "A" }
      it { is_expected.to be_falsey }
    end

    context "when key is authorized" do
      let(:key_string) { api_key.key_string }
      it { is_expected.to have_attributes(consumer_name: "CaseSlow") }
    end
  end
end
