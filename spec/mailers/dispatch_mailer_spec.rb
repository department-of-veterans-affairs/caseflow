# frozen_string_literal: true

describe DispatchMailer do
  let(:appeal) { create(:appeal) }
  let(:email_address) { "test@test.test" }
  let(:email_subject) do
    "Dispatched Decision for #{appeal.appellant_or_veteran_name} is ready for review – Do Not Reply"
  end
  let(:appeal_link) do
    "https://appeals.cf.ds.va.gov/queue/appeals/#{appeal.external_id}"
  end

  context "with email address" do
    subject { DispatchMailer.dispatch(email_address: email_address, appeal: appeal) }
    describe "#dispatch" do
      it "has the correct from" do
        expect(subject.from).to include("BoardofVeteransAppealsDecisions@messages.va.gov")
      end

      it "has the correct subject line" do
        expect(subject.subject).to eq(email_subject)
      end

      it "has the correct body" do
        expect(subject.body).to include("A decision has been dispatched for #{appeal.appellant_or_veteran_name}.")
      end

      it "has the correct appeal link" do
        expect(subject.body).to include(appeal_link)
      end

      it "sends an email" do
        expect { subject.deliver_now! }.to change { ActionMailer::Base.deliveries.count }.by 1
      end
    end
  end

  context "without email address" do
    subject { DispatchMailer.dispatch(email_address: nil, appeal: appeal) }
    describe "#dispatch" do
      it "raises exception" do
        expect { subject.deliver_now! }.to raise_error do |error|
          expect(error).to be_a(ArgumentError)
        end
      end
    end
  end
end
