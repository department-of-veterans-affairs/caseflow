# frozen_string_literal: true

describe VirtualHearingUserAlertBuilder do
  let(:veteran) { create(:veteran, first_name: "Serrif", last_name: "Gnest") }
  let(:appeal) { create(:appeal, :hearing_docket, veteran: veteran) }
  let(:hearing) { create(:hearing, appeal: appeal) }
  let!(:virtual_hearing) do
    create(
      :virtual_hearing,
      hearing: hearing,
      judge_email: judge_email,
      representative_email: representative_email
    )
  end
  let(:judge_email) { "judge@va.gov" }
  let(:representative_email) { "representative@va.gov" }

  subject do
    described_class
      .new(
        change_type: change_type,
        alert_type: alert_type,
        hearing: hearing.reload, # reload because virtual hearing is created after the hearing
        virtual_hearing_updates: virtual_hearing_updates
      )
      .call
  end

  context "change type is CHANGED_TO_VIRTUAL" do
    let(:change_type) { "CHANGED_TO_VIRTUAL" }

    # Confirmation email needs to be sent to all recipients, so the flags will all be set to
    # false.
    let(:virtual_hearing_updates) do
      {
        appellant_email_sent: false,
        representative_email_sent: false,
        judge_email_sent: false
      }
    end

    context "alert type is info" do
      let(:alert_type) { :info }

      context "no POA email" do
        let(:representative_email) { nil }

        it "has expected title and message" do
          expect(subject.title).to eq(
            COPY::VIRTUAL_HEARING_PROGRESS_ALERTS[change_type]["TITLE"] % "Serrif Gnest"
          )
          expect(subject.message).to eq(
            format(
              COPY::VIRTUAL_HEARING_PROGRESS_ALERTS[change_type]["MESSAGE"],
              recipients: "Veteran and VLJ"
            )
          )
        end
      end

      context "has POA email" do
        it "has expected title and message" do
          expect(subject.title).to eq(
            COPY::VIRTUAL_HEARING_PROGRESS_ALERTS[change_type]["TITLE"] % "Serrif Gnest"
          )
          expect(subject.message).to eq(
            format(
              COPY::VIRTUAL_HEARING_PROGRESS_ALERTS[change_type]["MESSAGE"],
              recipients: "Veteran, POA / Representative, and VLJ"
            )
          )
        end
      end
    end
  end

  context "change type is CHANGED_FROM_VIRTUAL" do
    let(:change_type) { "CHANGED_FROM_VIRTUAL" }

    # Cancellation email needs to be sent to the appellant and representative.
    let(:virtual_hearing_updates) do
      {
        appellant_email_sent: false,
        representative_email_sent: false
      }
    end

    context "alert type is success" do
      let(:alert_type) { :success }

      context "no POA email" do
        let(:representative_email) { nil }

        it "has expected title and message" do
          expect(subject.title).to eq(
            COPY::VIRTUAL_HEARING_SUCCESS_ALERTS[change_type]["TITLE"] % "Serrif Gnest"
          )
          expect(subject.message).to eq(
            format(
              COPY::VIRTUAL_HEARING_SUCCESS_ALERTS[change_type]["MESSAGE"],
              recipients_except_vlj: "Veteran"
            )
          )
        end
      end

      context "has POA email" do
        it "has expected title and message" do
          expect(subject.title).to eq(
            COPY::VIRTUAL_HEARING_SUCCESS_ALERTS[change_type]["TITLE"] % "Serrif Gnest"
          )
          expect(subject.message).to eq(
            format(
              COPY::VIRTUAL_HEARING_SUCCESS_ALERTS[change_type]["MESSAGE"],
              recipients_except_vlj: "Veteran and POA / Representative"
            )
          )
        end
      end
    end
  end

  context "change type is CHANGED_EMAIL" do
    let(:change_type) { "CHANGED_EMAIL" }

    context "alert type is info" do
      let(:alert_type) { :info }

      context "only changed appellant email" do
        let(:virtual_hearing_updates) do
          {
            appellant_email_sent: false
          }
        end

        it "has expected title and message" do
          expect(subject.title).to eq(
            COPY::VIRTUAL_HEARING_PROGRESS_ALERTS[change_type]["TITLE"] % "Serrif Gnest"
          )
          expect(subject.message).to eq(
            format(
              COPY::VIRTUAL_HEARING_PROGRESS_ALERTS[change_type]["MESSAGE"],
              recipients: "Veteran"
            )
          )
        end
      end

      context "only changed POA email" do
        let(:virtual_hearing_updates) do
          {
            representative_email_sent: false
          }
        end

        it "has expected title and message" do
          expect(subject.title).to eq(
            COPY::VIRTUAL_HEARING_PROGRESS_ALERTS[change_type]["TITLE"] % "Serrif Gnest"
          )
          expect(subject.message).to eq(
            format(
              COPY::VIRTUAL_HEARING_PROGRESS_ALERTS[change_type]["MESSAGE"],
              recipients: "POA / Representative"
            )
          )
        end
      end

      context "changed both POA and appellant emails" do
        let(:virtual_hearing_updates) do
          {
            appellant_email_sent: false,
            representative_email_sent: false
          }
        end

        it "has expected title and message" do
          expect(subject.title).to eq(
            COPY::VIRTUAL_HEARING_PROGRESS_ALERTS[change_type]["TITLE"] % "Serrif Gnest"
          )
          expect(subject.message).to eq(
            format(
              COPY::VIRTUAL_HEARING_PROGRESS_ALERTS[change_type]["MESSAGE"],
              recipients: "Veteran and POA / Representative"
            )
          )
        end
      end
    end
  end

  context "change type is CHANGED_HEARING_TIME" do
    let(:change_type) { "CHANGED_HEARING_TIME" }

    context "alert type is info" do
      let(:alert_type) { :info }

      context "no POA email" do
        let(:representative_email) { nil }

        let(:virtual_hearing_updates) do
          {
            appellant_email_sent: false
          }
        end

        it "has expected title and message" do
          expect(subject.title).to eq(
            COPY::VIRTUAL_HEARING_PROGRESS_ALERTS[change_type]["TITLE"] % "Serrif Gnest"
          )
          expect(subject.message).to eq(
            format(
              COPY::VIRTUAL_HEARING_PROGRESS_ALERTS[change_type]["MESSAGE"],
              recipients: "Veteran"
            )
          )
        end
      end

      context "has POA email" do
        let(:virtual_hearing_updates) do
          {
            appellant_email_sent: false,
            representative_email_sent: false
          }
        end

        it "has expected title and message" do
          expect(subject.title).to eq(
            COPY::VIRTUAL_HEARING_PROGRESS_ALERTS[change_type]["TITLE"] % "Serrif Gnest"
          )
          expect(subject.message).to eq(
            format(
              COPY::VIRTUAL_HEARING_PROGRESS_ALERTS[change_type]["MESSAGE"],
              recipients: "Veteran and POA / Representative"
            )
          )
        end
      end
    end
  end
end
