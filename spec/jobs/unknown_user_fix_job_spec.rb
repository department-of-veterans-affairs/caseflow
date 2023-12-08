# frozen_string_literal: true

describe UnknownUserFixJob, :postgres do
  let!(:unknown_error) { "UnknownUser" }
  let!(:riu) do
    create(:request_issues_update, created_at: Time.zone.parse("2020-01-31"), error: unknown_error)
  end

  subject { described_class.new }

  context "given a date" do
    it "clears errors before the date" do
      subject.perform
      expect(riu.reload.error).to be_nil
    end
    it "does not clear errors after the date" do
      subject.perform("2001-12-21")
      expect(riu.reload.error).to eq(unknown_error)
    end
    it "does nothing if no error is present" do
      riu.update(error: nil)
      subject.perform
      expect(riu.reload.error).to eq(nil)
    end
    it "stops if the given date cannot be parsed" do
      expect { subject.perform("12-21-2001") }.to raise_error(ArgumentError, "Incorrect date format, use 'YYYY-mm-dd'")
      expect(riu.reload.error).to eq(unknown_error)

      expect { subject.perform("Hello!") }.to raise_error(ArgumentError, "Incorrect date format, use 'YYYY-mm-dd'")
      expect(riu.reload.error).to eq(unknown_error)

      expect { subject.perform(42) }.to raise_error(ArgumentError, "Incorrect date format, use 'YYYY-mm-dd'")
      expect(riu.reload.error).to eq(unknown_error)
    end
  end

  context "when created_at is nil" do
    it "does not clear the error" do
      riu.update(created_at: nil)
      subject.perform
      expect(riu.error).to eq(unknown_error)
    end
  end
end
