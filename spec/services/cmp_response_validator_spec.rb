# frozen_string_literal: true

describe CmpResponseValidator do
  subject(:described) { described_class.new }

  describe "#validate_cmp_document_request" do
    it "accepts valid data" do
      data = { dateOfReceipt: Time.current.strftime(Date::DATE_FORMATS[:csv_date]) }

      expect(described.validate_cmp_document_request(data)).to eq(true)
    end

    it "rejects invalid data" do
      data = { dateOfReceipt: "202020202020" }

      expect(described.validate_cmp_document_request(data)).to eq(false)
    end
  end

  describe "#validate_cmp_mail_packet_request" do
    it "accepts valid data" do
      data = { vaDor: Time.current.strftime(Date::DATE_FORMATS[:csv_date]) }

      expect(described.validate_cmp_mail_packet_request(data)).to eq(true)
    end

    it "rejects invalid data" do
      data = { vaDor: "202020202020" }

      expect(described.validate_cmp_mail_packet_request(data)).to eq(false)
    end
  end
end
