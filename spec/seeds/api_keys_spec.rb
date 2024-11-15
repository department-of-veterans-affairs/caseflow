# frozen_string_literal: true

describe Seeds::ApiKeys do
  describe "#seed!" do
    subject { described_class.new.seed! }
    let(:consumer_name) { "appeals_consumer" }
    let(:key_digest) { "z1VxSVb2iae07+bYq8ZjQZs3ll4ZgSeVIUC9O5u+HfA=" }

    it "creates appeals consumer api key" do
      expect { subject }.to_not raise_error
      expect(subject).to have_attributes(consumer_name: consumer_name, key_digest: key_digest)
    end
  end
end
