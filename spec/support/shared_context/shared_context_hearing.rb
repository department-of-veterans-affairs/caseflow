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