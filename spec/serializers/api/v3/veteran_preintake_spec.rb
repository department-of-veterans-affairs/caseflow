# frozen_string_literal: true

require "rails_helper"

describe Api::V3::VeteranPreintake do
  context "veteran" do
    it "should work with valid hash" do
      c = Api::V3::VeteranPreintake.new(
        "data" => {
          "type" => "Veteran",
          "id" => "123456789"
        }
      )
      expect(c.file_number).to be "123456789"
    end
    it "extra key should fail" do
      expect do
        Api::V3::VeteranPreintake.new(
          "data" => {
            "type" => "Veteran",
            "id" => "1234",
            "meta" => {
              "payeeCode" => "10"
            }
          }
        )
      end.to raise_error ArgumentError
    end
  end
end
