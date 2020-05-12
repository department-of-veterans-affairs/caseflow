# frozen_string_literal: true

describe BgsAddressService do
  describe "#participant_id_from_cache_key" do
    it "extracts a participant ID from a cache key" do
      participant_id = "123456"
      cache_key = BgsAddressService.cache_key_for_participant_id(participant_id)
      expect(BgsAddressService.participant_id_from_cache_key(cache_key)).to eq(participant_id)
    end
  end

  describe "#fetch_cached_addresses" do
    it "retrieves only cached addresses" do
      addresses = {
        "123" => {"address": "address one"},
        "456" => {"address": "address two"}
      }
      addresses.each do |pid, value|
        Rails.cache.write(BgsAddressService.cache_key_for_participant_id(pid), value)
      end
      expect(BgsAddressService.fetch_cached_addresses(["123", "456", "789"])).to eq(addresses)
    end
  end
end
