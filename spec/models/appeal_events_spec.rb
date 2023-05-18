# frozen_string_literal: true

describe AppealEvents, :all_dbs do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
  let(:vacols_case) { create(:case) }

  let(:appeal_events) { AppealEvents.new(appeal: appeal, version: version) }
  let(:version) { nil }

  context "#all" do
    let(:events) { appeal_events.all }

    context "claim event" do
      let(:notification_date) { 4.days.ago }

      subject do
        events.find do |event|
          event.type == :claim_decision &&
            event.date == AppealRepository.normalize_vacols_date(notification_date)
        end
      end

      context "when notification_date is set" do
        let(:vacols_case) { create(:case, bfdrodec: notification_date) }
        it { is_expected.to_not be_nil }
      end

      context "when nod_date is not set" do
        it { is_expected.to be_nil }
      end
    end

    context "nod event" do
      let(:nod_date) { 3.days.ago }

      subject do
        events.find { |event| event.type == :nod && event.date == AppealRepository.normalize_vacols_date(nod_date) }
      end

      context "when nod_date is set" do
        let(:vacols_case) { create(:case, bfdnod: nod_date) }
        it { is_expected.to_not be_nil }
      end

      context "when nod_date is not set" do
        it { is_expected.to be_nil }
      end
    end

    context "soc event" do
      let(:soc_date) { 2.days.ago }

      subject do
        events.find { |event| event.type == :soc && event.date == AppealRepository.normalize_vacols_date(soc_date) }
      end

      context "when soc_date is set" do
        let(:vacols_case) { create(:case, bfdsoc: soc_date) }
        it { is_expected.to_not be_nil }
      end

      context "when soc_date is not set" do
        it { is_expected.to be_nil }
      end
    end

    context "form9 event" do
      let(:form9_date) { 1.day.ago }

      subject do
        events.find { |event| event.type == :form9 && event.date == AppealRepository.normalize_vacols_date(form9_date) }
      end

      context "when form9_date is set" do
        let(:vacols_case) { create(:case, bfd19: form9_date) }
        it { is_expected.to_not be_nil }
      end

      context "when form9_date is not set" do
        it { is_expected.to be_nil }
      end
    end

    context "ssoc events" do
      subject { events.select { |event| event.type == :ssoc } }

      context "when ssoc dates set" do
        let(:vacols_case) { create(:case_with_ssoc, number_of_ssoc: 2) }
        it { expect(subject.length).to eq(2) }
      end

      context "when no ssocs" do
        it { is_expected.to be_empty }
      end
    end

    context "certification event" do
      let(:certification_date) { 2.days.ago }

      subject do
        events.find do |event|
          event.type == :certified && event.date == certification_date.to_date
        end
      end

      context "when certification date is set" do
        let(:vacols_case) { create(:case, :certified, certification_date: certification_date) }
        it { is_expected.to_not be_nil }
      end

      context "when certification date is not set" do
        it { is_expected.to be_nil }
      end
    end

    context "remand return event" do
      subject do
        events.find do |event|
          event.type == :remand_return
        end
      end

      context "when the appeal is complete" do
        let(:vacols_case) { create(:case, :status_complete, remand_return_date: 2.days.ago) }
        it { is_expected.to_not be_nil }
      end

      context "when the appeal is open" do
        let(:vacols_case) { create(:case, :status_active, remand_return_date: 2.days.ago) }
        it { is_expected.to be_nil }
      end
    end

    context "hearing events" do
      # Save appeal so hearings can be associated to it
      before { appeal.save! }

      let!(:held_hearing) do
        build(:case_hearing, :disposition_held, transent: 1.day.ago)
      end

      let!(:cancelled_hearing) do
        build(:case_hearing, :disposition_cancelled, transent: 1.day.ago)
      end

      let!(:hearings) do
        [
          build(:case_hearing, :disposition_held, hearing_date: 4.days.ago),
          build(:case_hearing, :disposition_no_show, hearing_date: 3.days.ago),
          build(:case_hearing),
          build(:case_hearing, :disposition_postponed, hearing_date: 2.days.ago)
        ]
      end

      let!(:hearing_for_another_appeal) { build(:case_hearing, :disposition_no_show, hearing_date: 2.days.ago) }

      let(:hearing_held_events) do
        events.select { |event| event.type == :hearing_held }
      end

      let(:no_show_hearing_events) do
        events.select { |event| event.type == :hearing_no_show }
      end

      let(:vacols_case) { create(:case, case_hearings: hearings) }

      it "adds hearing events for all closed hearings associated with the appeal" do
        expect(hearing_held_events.length).to eq(1)
        expect(no_show_hearing_events.length).to eq(1)
      end
    end

    context "hearing transcript events" do
      # Save appeal so hearings can be associated to it
      before { appeal.save! }

      let!(:held_hearing) do
        build(:case_hearing, :disposition_held, transent: 1.day.ago)
      end

      let!(:cancelled_hearing) do
        build(:case_hearing, :disposition_cancelled, transent: 1.day.ago)
      end

      let(:transcript_events) do
        events.select { |event| event.type == :transcript }
      end

      let(:vacols_case) { create(:case, case_hearings: [held_hearing, cancelled_hearing]) }

      it "adds transcript events for all held hearings associated with the appeal" do
        expect(transcript_events.length).to eq(1)
      end
    end

    context "decision event" do
      let(:decision_date) { nil }

      subject do
        events.find do |event|
          event.type == :field_grant && event.date == AppealRepository.normalize_vacols_date(decision_date)
        end
      end

      context "when decision date is set" do
        let(:decision_date) { Time.zone.now }
        let(:vacols_case) { create(:case, :disposition_granted_by_aoj, bfddec: decision_date) }

        context "when disposition is valid" do
          it { is_expected.to_not be_nil }
        end
      end

      context "when no decision date" do
        it { is_expected.to be_nil }
      end
    end

    context "issue event" do
      subject do
        events.select do |event|
          event.type == :field_grant && event.date == AppealRepository.normalize_vacols_date(issue_close_date)
        end.length
      end

      let(:issues) do
        [create(:case_issue, :disposition_granted_by_aoj, issdcls: issue_close_date)]
      end

      let(:issue_close_date) { nil }

      context "when close date is set" do
        let(:issue_close_date) { Time.zone.now }
        let(:vacols_case) { create(:case, case_issues: issues) }

        it { is_expected.to eq(1) }
      end

      context "when no close date" do
        it { is_expected.to eq(0) }
      end

      context "when the issue close is same as decision date" do
        let(:issue_close_date) { Time.zone.now }
        let(:decision_date) { Time.zone.now }
        let(:vacols_case) { create(:case, :disposition_granted_by_aoj, bfddec: decision_date, case_issues: issues) }

        it { is_expected.to eq(1) }
      end
    end

    context "cavc decision event" do
      subject do
        events.select { |event| event.type == :cavc_decision && event.date == cavc_date }
      end

      let(:cavc_date) { 6.months.ago }

      context "when appeal has cavc decisions" do
        let!(:cavc_decisions) do
          2.times { Generators::CAVCDecision.build(appeal: appeal, decision_date: cavc_date) }
        end

        it "creates one event per cavc decision date" do
          expect(subject.length).to eq(1)
        end
      end

      context "when appeal doesn't have a cavc decision" do
        it { is_expected.to be_empty }
      end
    end

    context "ramp notice event" do
      subject do
        events.find { |event| event.type == :ramp_notice && event.date == 30.days.ago.to_date }
      end

      context "when the Veteran has been sent a RAMP notice" do
        let!(:ramp_election) do
          RampElection.create(veteran_file_number: appeal.veteran_file_number, notice_date: 30.days.ago)
        end
        it { is_expected.to_not be_nil }
      end

      context "when the Veteran has not yet been sent a RAMP notice" do
        it { is_expected.to be_nil }
      end
    end
  end
end
