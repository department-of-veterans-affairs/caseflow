# frozen_string_literal: true

RSpec.configure { |rspec| rspec.shared_context_metadata_behavior = :apply_to_host_groups }

RSpec.shared_context "shared context hearing", shared_context: :appealrepo do
  shared_context "when there is a virtual hearing" do
    let!(:email_event) do
      create(
        :sent_hearing_email_event,
        email_address: email_address,
        recipient_role: recipient_role,
        hearing: hearing
      )
    end

    let!(:virtual_hearing) do
      VirtualHearing.create!(
        hearing: hearing,
        appellant_email: appellant_email,
        appellant_tz: appellant_tz,
        judge_email: judge_email,
        representative_email: representative_email,
        representative_tz: representative_tz,
        created_by: User.system_user
      )
    end

    it "backfills virtual hearing data and returns recipient", :aggregate_failures do
      expect(hearing.reload.email_recipients.empty?).to eq(true)
      expect(subject).not_to eq(nil)
      expect(subject.email_address).to eq(email_address)
      expect(subject.timezone).to eq(timezone)

      expect(email_event.reload.email_recipient).to eq(subject)
    end
  end
end

RSpec.shared_context "returns existing recipient", shared_context: :appealrepo do
  let!(:email_recipient) do
    create(
      :hearing_email_recipient,
      type,
      hearing: hearing,
      email_address: email_address,
      timezone: timezone
    )
  end

  it "returns exisiting recipient" do
    expect(subject).to eq(email_recipient)
  end
end

RSpec.shared_context "judge_recipient", shared_context: :appealrepo do
  context "#judge_recipient" do
    let(:type) { :judge_hearing_email_recipient }
    let(:judge_email) { "test3@email.com" }
    let(:email_address) { judge_email }
    let(:timezone) { nil }
    let(:recipient_role) { HearingEmailRecipient::RECIPIENT_ROLES[:judge] }

    subject { hearing.reload.judge_recipient }

    include_context "when there is a virtual hearing"
    context "when there is an exisiting recipient" do
      include_context "returns existing recipient"
    end
  end
end
