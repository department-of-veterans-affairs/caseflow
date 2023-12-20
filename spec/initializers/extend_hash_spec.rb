# frozen_string_literal: true

describe Hash do
  context "#find_all_values_for" do
    let(:nested_hash) do
      {
        key: "first level value",
        key2: {
          key: "second level value"
        },
        key3: {
          key4: {
            key: ["an array"]
          }
        }
      }
    end

    it "returns an array with values matching the key" do
      expect(nested_hash.find_all_values_for(:key)).to include("first level value", "second level value", ["an array"])
    end

    it "returns empty array for key not found" do
      expect(nested_hash.find_all_values_for(:not_found)).to eq([])
    end
  end
end
