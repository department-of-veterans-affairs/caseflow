# frozen_string_literal: true

describe Idt::Token do
  before do
    Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
  end

  let(:css_id) { "TEST_ID" }
  let(:key_token_pair) { Idt::Token.generate_one_time_key_and_proposed_token }
  let(:freeze_time) { Time.utc(2020, 8, 30, 19, 0, 20) }
  # rubocop:disable Metrics/LineLength
  let(:invalid_token) { "9373a256a2ac3c3bd320adeeb8a1e4d996ef064d1332357954410f25740bf0c17b6565e152760c461a85587e6a6845457f955ccfa20a8e462a77b776eb10b72c" }
  # rubocop:enable Metrics/LineLength

  context "#generate_one_time_key_and_proposed_token" do
    it "generates tokens and keys" do
      expect(key_token_pair[0].length).to eq(128)
      expect(key_token_pair[1].length).to eq(128)
    end
  end

  context "#activate_proposed_token" do
    it "successfully activates tokens with valid one time keys" do
      key, token = key_token_pair
      expect(Idt::Token.activate_proposed_token(key, css_id)).to eq(true)
      expect(Idt::Token.active?(token)).to eq(true)
    end

    it "raises an error when invalid one time key is used" do
      expect { Idt::Token.activate_proposed_token(invalid_token, css_id) }
        .to raise_error(Caseflow::Error::InvalidOneTimeKey)
    end

    it "raises on the second attempted use of a one time key" do
      key, _token = key_token_pair
      expect(Idt::Token.activate_proposed_token(key, css_id)).to eq(true)

      expect { Idt::Token.activate_proposed_token(key, css_id) }
        .to raise_error(Caseflow::Error::InvalidOneTimeKey)
    end
  end

  context "#active?" do
    it "returns true for valid tokens" do
      key, token = key_token_pair
      Idt::Token.activate_proposed_token(key, css_id)
      expect(Idt::Token.active?(token)).to eq(true)
    end

    it "returns false for invalid tokens" do
      expect(Idt::Token.active?(invalid_token)).to eq(false)
    end

    it "returns false after a token expires" do
      key, token = key_token_pair
      Idt::Token.activate_proposed_token(key, css_id)
      Idt::Token.client.expire("valid_tokens_key" + token, 1)
      expect(Idt::Token.active?(token)).to eq(true)
      sleep 2
      expect(Idt::Token.active?(token)).to eq(false)
    end
  end
end
