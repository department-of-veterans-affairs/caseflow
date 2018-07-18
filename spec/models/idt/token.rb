describe Idt::Token do 
  before do
    Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
  end

  let(:key_token_pair) { Idt::Token.generate_proposed_token_and_one_time_key }
  let(:invalid_token) { "34fb4ei8jfjd123098nc6gd53hd73jh46" }

  context "#generate_proposed_token_and_one_time_key" do
    it "generates tokens and keys" do
      expect(key_token_pair[0].length).to eq(32)
      expect(key_token_pair[1].length).to eq(32)
    end
  end

  context "#activate_proposed_token" do
    it "successfully activates tokens with valid one time keys" do
      key, token = key_token_pair
      expect(Idt::Token.activate_proposed_token(key)).to eq(true)
      expect(Idt::Token.active?(token)).to eq(true)
    end

    it "raises an error when invalid one time key is used" do
      expect { Idt::Token.activate_proposed_token(invalid_token) }
          .to raise_error(Caseflow::Error::InvalidOneTimeKey)
    end    

    it "raises on the second attempted use of a one time key" do
      key, token = key_token_pair
      expect(Idt::Token.activate_proposed_token(key)).to eq(true)

      expect { Idt::Token.activate_proposed_token(key) }
          .to raise_error(Caseflow::Error::InvalidOneTimeKey)
    end
  end

  context "#active?" do
    it "returns true for valid tokens" do
      key, token = key_token_pair
      Idt::Token.activate_proposed_token(key)
      expect(Idt::Token.active?(token)).to eq(true)
    end

    it "returns false for invalid tokens" do
      expect(Idt::Token.active?(invalid_token)).to eq(false)
    end

    it "returns false after a token expires" do
      # todo: add test for this
    end
  end
end