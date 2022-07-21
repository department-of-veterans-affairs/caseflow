# frozen_string_literal: true

describe Hearings::SendEmail do
  let(:nyc_ro_eastern) { "RO06" }
  let(:judge_email_sent) { false }
  let(:representative_email_sent) { false }
  let(:appellant_email_sent) { false }
  let(:veteran) { create(:veteran) }
  let(:appeal) { create(:appeal, veteran_file_number: veteran.file_number) }
  let(:hearing) do
    create(
      :hearing,
      appeal: appeal,
      regional_office: nyc_ro_eastern
    )
  end
  let!(:virtual_hearing) do
    create(
      :virtual_hearing,
      hearing: hearing,
      judge_email_sent: judge_email_sent,
      representative_email_sent: representative_email_sent,
      appellant_email_sent: appellant_email_sent
    )
  end
  let(:email_type) { nil }
  let(:judge_recipient_info) do
    EmailRecipientInfo.new(
      name: "TEST",
      title: HearingEmailRecipient::RECIPIENT_TITLES[:judge],
      hearing_email_recipient: hearing.judge_recipient
    )
  end
  let(:appellant_recipient_info) do
    EmailRecipientInfo.new(
      name: "TEST",
      title: HearingEmailRecipient::RECIPIENT_TITLES[:appellant],
      hearing_email_recipient: hearing.appellant_recipient
    )
  end
  let(:representative_recipient_info) do
    EmailRecipientInfo.new(
      name: "TEST",
      title: HearingEmailRecipient::RECIPIENT_TITLES[:representative],
      hearing_email_recipient: hearing.representative_recipient
    )
  end
  let(:send_email_job) do
    Hearings::SendEmail.new(virtual_hearing: virtual_hearing, type: email_type)
  end

  describe ".call" do
    subject do
      send_email_job.call
    end

    before do
      allow(send_email_job).to receive(:judge_recipient_info).and_return(judge_recipient_info)
      allow(send_email_job).to receive(:representative_recipient_info).and_return(representative_recipient_info)
    end

    context "there is no representative recipient" do
      let!(:virtual_hearing) do
        create(
          :virtual_hearing,
          hearing: hearing,
          representative_email: nil,
          judge_email_sent: judge_email_sent,
          appellant_email_sent: appellant_email_sent
        )
      end

      it "does not error" do
        expect { subject }.to_not raise_error
      end
    end

    context "appellant_recipient name is populated correctly" do
      context "veteran is appellant" do
        it "uses the full name of the veteran" do
          recipient = send_email_job.send(:appellant_recipient_info)
          expect(recipient.name).to eq appeal.veteran_full_name
        end
      end

      context "veteran is not appellant" do
        let(:veteran) { create(:veteran, first_name: "veteranfirst", last_name: "veteranlast") }
        let(:appeal) do
          create(
            :appeal,
            :hearing_docket,
            number_of_claimants: 1,
            veteran_is_not_claimant: true
          )
        end

        it "uses the full name of the appellant, not the veteran" do
          recipient = send_email_job.send(:appellant_recipient_info)
          expect(recipient.name).to eq appeal.appellant_fullname_readable
          expect(recipient.name).not_to eq appeal.veteran_full_name
        end
      end
    end

    context "veteran name is populated" do
      before do
        allow(send_email_job).to receive(:appellant_recipient_info).and_return(appellant_recipient_info)
      end

      context "a cancellation email" do
        let(:email_type) { :cancellation }

        it "calls HearingMailer.cancellation for everyone but the judge", :aggregate_failures do
          # YES for veteran and representative
          expect(HearingMailer)
            .to receive(:cancellation)
            .once
            .with(email_recipient_info: appellant_recipient_info, virtual_hearing: virtual_hearing)

          expect(HearingMailer)
            .to receive(:cancellation)
            .once
            .with(email_recipient_info: representative_recipient_info, virtual_hearing: virtual_hearing)

          # NO for judge
          expect(HearingMailer)
            .to_not receive(:cancellation)
            .with(email_recipient_info: judge_recipient_info, virtual_hearing: virtual_hearing)

          subject
        end
      end
    end

    context "veteran name is not populated" do
      let(:veteran) do
        create(
          :veteran,
          first_name: nil,
          last_name: nil,
          file_number: "12345678"
        )
      end

      before do
        Fakes::BGSService.store_veteran_record(
          veteran.file_number,
          ptcpnt_id: veteran.participant_id.to_s,
          first_name: "Bgsfirstname",
          last_name: "Bgslastname"
        )
      end

      it "fetches veteran from BGS" do
        expect(virtual_hearing.hearing.appeal.veteran)
          .to receive(:update_cached_attributes!)
          .once
          .and_call_original

        subject

        veteran.reload
        expect(veteran.first_name).to eq "Bgsfirstname"
        expect(veteran.last_name).to eq "Bgslastname"
      end
    end
  end
end
