# frozen_string_literal: true

describe MpiUpdatePersonEvent do
  let(:api_key) { ApiKey.create!(consumer_name: "Test API Key") }
  let(:invalid_update_type) { "invalid_update_type" }
  let(:valid_update_types) do
    {
      no_veteran: "NO_VETERAN",
      already_deceased: "ALREADY_DECEASED",
      missing_deceased_info: "MISSING_DECEASED_INFO",
      successful: "SUCCESSFUL",
      error: "ERROR"
    }
  end

  context "validation" do
    it "fails with no api_key or update_type" do
      update = MpiUpdatePersonEvent.new

      expect(update.valid?).to eq(false)
      expect(update.errors.details).to have_key(:api_key)
      expect(update.errors.details).to have_key(:update_type)
    end

    it "fails with an api_key but no update_type" do
      update = MpiUpdatePersonEvent.new(api_key: api_key)

      expect(update.valid?).to eq(false)
      expect(update.errors.details).to have_key(:update_type)
    end

    it "fails with an api_key and invalid update_type" do
      expect { MpiUpdatePersonEvent.new(api_key: api_key, update_type: invalid_update_type) }
        .to raise_error(ArgumentError)
    end

    # creates an array of events, then reject any where .valid? is true and count the result
    it "succeeds with an api_key and each valid update_type" do
      updates = []
      i = 0
      valid_update_types.each do |update_type_sym, _update_type_text|
        updates[i] = MpiUpdatePersonEvent.new(api_key: api_key, update_type: update_type_sym)
        i += 1
      end
      updates.reject!(&:valid?)

      expect(updates.count).to eq(0)
    end
  end
end
