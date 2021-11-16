# frozen_string_literal: true

describe VirtualHearings::ResendVirtualHearingEmailsService do
  let(:sample_bad_email) {
    "This is a bad email it contains care.va.gov which is the bad url"
  }
  let(:start_date) { '2021-01-01' }
  let(:end_date) { '2021-01-10' }
  describe ".call" do 
    before do
      allow_any_instance_of(VirtualHearings::ResendVirtualHearingEmailsService)
        .to_receive(:get_gov_delivery_message_body)
        .and_return(sample_bad_email)
    end
    it "resends emails for bad emails" do
      create(:sent_hearing_email_event)
      VirtualHearings::ResendVirtualHearingEmailsService.call(start_date: start_date, end_date: end_date)
    end
  end
  describe ".is_bad_email?" do
    it "returns true if contains care.va.gov" do
      expect(VirtualHearings::ResendVirtualHearingEmailsService.is_bad_email?(sample_bad_email)).to eq(true)
    end
    it "returns false if does not contain care.va.gov" do
      expect(VirtualHearings::ResendVirtualHearingEmailsService.is_bad_email?("test email")).to eq(false)
    end
  end
end