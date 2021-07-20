# frozen_string_literal: true

describe VirtualHearingRepository, :all_dbs do
  let(:regional_office) { "RO42" }
  let(:hearing_date) { Time.zone.now }
  let(:ama_disposition) { nil }
  let(:hearing_day) do
    create(
      :hearing_day,
      regional_office: regional_office,
      scheduled_for: hearing_date,
      request_type: HearingDay::REQUEST_TYPES[:video]
    )
  end

  let(:hearing) do
    create(:hearing, regional_office: regional_office, hearing_day: hearing_day, disposition: ama_disposition)
  end

  context ".ready_for_deletion" do
    let!(:virtual_hearing) { create(:virtual_hearing, :initialized, status: :active, hearing: hearing) }

    subject { VirtualHearingRepository.ready_for_deletion }

    context "for an AMA hearing" do
      context "that was held" do
        let(:hearing_date) { Time.zone.now - 1.day }

        it "returns the virtual hearing" do
          expect(subject).to eq [virtual_hearing]
        end
      end

      context "that was postponed" do
        let(:ama_disposition) { Constants.HEARING_DISPOSITION_TYPES.postponed }

        it "returns the virtual hearing" do
          expect(subject).to eq [virtual_hearing]
        end
      end

      context "that was cancelled" do
        let(:ama_disposition) { Constants.HEARING_DISPOSITION_TYPES.cancelled }

        it "returns the virtual hearing" do
          expect(subject).to eq [virtual_hearing]
        end
      end

      context "for pending virtual hearing" do
        let(:virtual_hearing) { create(:virtual_hearing, hearing: hearing) }

        it "does not return the virtual hearing" do
          expect(subject).to eq []
        end
      end

      context "for cancelled virtual hearing" do
        let(:virtual_hearing) { create(:virtual_hearing, :initialized, status: :cancelled, hearing: hearing) }

        it "returns the virtual hearing" do
          expect(subject).to eq [virtual_hearing]
        end
      end

      context "for a virtual hearing created with new link generation" do
        let(:virtual_hearing) { create(:virtual_hearing, :link_generation_initialized, hearing: hearing) }

        it "does not return the virtual hearing" do
          expect(subject).to eq []
        end
      end

      context "on the day of" do
        it "does not return the virtual hearing" do
          expect(subject).to eq []
        end
      end
    end

    context "for a Legacy hearing" do
      let(:legacy_dispositon) { nil }
      let(:hearing) do
        create(
          :legacy_hearing,
          regional_office: regional_office,
          hearing_day_id: hearing_day.id,
          case_hearing: create(:case_hearing, hearing_disp: legacy_dispositon)
        )
      end

      context "that was held" do
        let(:hearing_date) { Time.zone.now - 1.day }

        it "returns the virtual hearing" do
          expect(subject).to eq [virtual_hearing]
        end
      end

      context "that was postponed" do
        let(:legacy_dispositon) { "P" }

        it "returns the virtual hearing" do
          expect(subject).to eq [virtual_hearing]
        end
      end

      context "that was cancelled" do
        let(:legacy_dispositon) { VACOLS::CaseHearing::HEARING_DISPOSITION_CODES[:cancelled] }

        it "returns the virtual hearing" do
          expect(subject).to eq [virtual_hearing]
        end
      end

      context "for cancelled virtual hearing" do
        let(:virtual_hearing) { create(:virtual_hearing, :initialized, status: :cancelled, hearing: hearing) }

        it "returns the virtual hearing" do
          expect(subject).to eq [virtual_hearing]
        end
      end

      context "for pending virtual hearing" do
        let(:virtual_hearing) { create(:virtual_hearing, hearing: hearing) }

        it "does not return the virtual hearing" do
          expect(subject).to eq []
        end
      end

      context "for a virtual hearing created with new link generation" do
        let(:virtual_hearing) { create(:virtual_hearing, :link_generation_initialized, hearing: hearing) }

        it "does not return the virtual hearing" do
          expect(subject).to eq []
        end
      end

      context "on the day of" do
        it "does not return the virtual hearing" do
          expect(subject).to eq []
        end
      end
    end
  end

  context ".cancelled_with_pending_emails" do
    subject { VirtualHearingRepository.cancelled_with_pending_emails }

    let!(:cancelled_vh_with_only_pending_judge_emails) do
      create(
        :virtual_hearing,
        :all_emails_sent,
        status: :cancelled,
        hearing: create(:hearing)
      )
    end

    let!(:cancelled_vh_with_all_pending_emails) do
      create(
        :virtual_hearing,
        :initialized,
        status: :cancelled,
        hearing: create(:hearing)
      )
    end

    let!(:cancelled_vh_with_only_pending_rep_email) do
      create(
        :virtual_hearing,
        :initialized,
        status: :cancelled,
        hearing: create(:hearing)
      )
    end

    it "returns correct virtual hearings" do
      expect(subject.map(&:id)).to contain_exactly(
        cancelled_vh_with_all_pending_emails.id, cancelled_vh_with_only_pending_rep_email.id
      )
    end
  end

  context ".with_pending_conference_or_emails" do
    subject { VirtualHearingRepository.with_pending_conference_or_emails }

    context "virtual hearings created with new link generation" do
      let!(:vh_with_pending_link) do
        create(:virtual_hearing, hearing: create(:hearing))
      end
      let!(:vh_with_all_pending_emails) do
        create(
          :virtual_hearing,
          :link_generation_initialized,
          status: :active,
          hearing: create(:hearing)
        )
      end
      let!(:vh_in_good_state) do
        create(
          :virtual_hearing,
          :link_generation_initialized,
          :all_emails_sent,
          hearing: create(:hearing)
        )
      end

      it "returns correct virtual hearings" do
        expect(subject.map(&:id)).to contain_exactly(
          vh_with_pending_link.id, vh_with_all_pending_emails.id
        )
      end
    end

    context "virtual hearings not created with new link generation" do
      let!(:vh_with_pending_conference) do
        create(:virtual_hearing, hearing: create(:hearing))
      end

      let!(:vh_with_all_pending_emails) do
        create(:virtual_hearing, :initialized, status: :active, hearing: create(:hearing))
      end

      let!(:vh_in_good_state) do
        create(
          :virtual_hearing,
          :initialized,
          :all_emails_sent,
          status: :active,
          hearing: create(:hearing)
        )
      end

      it "returns correct virtual hearings" do
        expect(subject.map(&:id)).to contain_exactly(
          vh_with_pending_conference.id, vh_with_all_pending_emails.id
        )
      end
    end
  end

  context ".maybe_ready_for_reminder_email" do
    let!(:virtual_hearing) { create(:virtual_hearing, :initialized, status: :active, hearing: hearing) }

    subject { described_class.maybe_ready_for_reminder_email }

    shared_examples "include or exclude hearings depending on the number of days out from the hearing" do
      context "within 7 days" do
        let(:hearing_date) { Time.zone.now + 7.days }

        it "returns the virtual hearing" do
          expect(subject).to eq([virtual_hearing])
        end
      end

      context "is in 10 days" do
        let(:hearing_date) { Time.zone.now + 10.days }

        it "returns nothing" do
          expect(subject).to be_empty
        end
      end
    end

    context "for an AMA hearing" do
      context "active virtual hearing" do
        include_examples "include or exclude hearings depending on the number of days out from the hearing"
      end

      %w[postponed cancelled no_show held].each do |disposition|
        context "#{disposition} virtual hearing" do
          let(:ama_disposition) { disposition }

          it "returns nothings" do
            expect(subject).to be_empty
          end
        end
      end
    end

    context "for a Legacy hearing" do
      let(:legacy_dispositon) { nil }
      let(:hearing) do
        create(
          :legacy_hearing,
          regional_office: regional_office,
          hearing_day_id: hearing_day.id,
          case_hearing: create(:case_hearing, hearing_disp: legacy_dispositon)
        )
      end

      context "active virtual hearing" do
        include_examples "include or exclude hearings depending on the number of days out from the hearing"
      end

      %w[P C N H].each do |disposition_code|
        context "#{VACOLS::CaseHearing::HEARING_DISPOSITIONS[disposition_code.to_sym]} virtual hearing" do
          let(:ama_disposition) { disposition_code }

          it "returns nothings" do
            expect(subject).to be_empty
          end
        end
      end
    end
  end
end
