# frozen_string_literal: true

require "rails_helper"

describe Api::V3::ClaimantPreintake do
  context "claimant" do
    it "should work with valid hash" do
      c = Api::V3::ClaimantPreintake.new(
        "data" => {
          "type" => "Claimant",
          "id" => "1234",
          "meta" => {
            "payeeCode" => "10"
          }
        }
      )
      expect(c.participant_id).to be 1234
      expect(c.payee_code).to be "10"
    end
    it "extra key should fail" do
      expect do
        Api::V3::ClaimantPreintake.new(
          "data" => {
            "type" => "Claimant",
            "id" => "1234",
            "meta" => {
              "payeeCode" => "10"
            },
            "extra": 44
          }
        )
      end.to raise_error ArgumentError
    end
  end
end
