describe AppealEvents do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:appeal) do
    Generators::Appeal.build(
      vbms_id: "999887777S",
      status: status,
      notification_date: notification_date,
      nod_date: nod_date,
      soc_date: soc_date,
      form9_date: form9_date,
      ssoc_dates: ssoc_dates,
      certification_date: certification_date,
      case_review_date: case_review_date,
      decision_date: decision_date,
      disposition: disposition,
      prior_decision_date: prior_decision_date,
      issues: issues
    )
  end

  let(:status) { "Active" }
  let(:notification_date) { 4.days.ago }
  let(:nod_date) { 3.days.ago }
  let(:soc_date) { 2.days.ago }
  let(:form9_date) { 1.day.ago }
  let(:ssoc_dates) { [] }
  let(:prior_decision_date) { nil }
  let(:certification_date) { nil }
  let(:case_review_date) { nil }
  let(:decision_date) { nil }
  let(:disposition) { nil }
  let(:issues) { [] }

  let(:appeal_events) { AppealEvents.new(appeal: appeal, version: version) }
  let(:version) { nil }

  context "#all" do
    let(:events) { appeal_events.all }

    context "claim event" do
      subject do
        events.find { |event| event.type == :claim_decision && event.date == notification_date }
      end

      context "when notification_date is set" do
        it { is_expected.to_not be_nil }
      end

      context "when nod_date is not set" do
        let(:notification_date) { nil }
        it { is_expected.to be_nil }
      end
    end

    context "nod event" do
      subject do
        events.find { |event| event.type == :nod && event.date == nod_date }
      end

      context "when nod_date is set" do
        it { is_expected.to_not be_nil }
      end

      context "when nod_date is not set" do
        let(:nod_date) { nil }
        it { is_expected.to be_nil }
      end
    end

    context "soc event" do
      subject do
        events.find { |event| event.type == :soc && event.date == soc_date }
      end

      context "when soc_date is set" do
        it { is_expected.to_not be_nil }
      end

      context "when soc_date is not set" do
        let(:soc_date) { nil }
        it { is_expected.to be_nil }
      end
    end

    context "form9 event" do
      subject do
        events.find { |event| event.type == :form9 && event.date == form9_date }
      end

      context "when form9_date is set" do
        it { is_expected.to_not be_nil }
      end

      context "when form9_date is not set" do
        let(:form9_date) { nil }
        it { is_expected.to be_nil }
      end
    end

    context "ssoc events" do
      subject { events.select { |event| event.type == :ssoc } }

      context "when ssoc dates set" do
        let(:ssoc_dates) { [5.days.ago, 6.days.ago] }
        it { expect(subject.length).to eq(2) }
      end

      context "when no ssocs" do
        it { is_expected.to be_empty }
      end
    end

    context "certification event" do
      subject do
        events.find { |event| event.type == :certified && event.date == certification_date }
      end

      context "when certification date is set" do
        let(:certification_date) { Time.zone.today - 10.days }
        it { is_expected.to_not be_nil }
      end

      context "when certification date is not set" do
        it { is_expected.to be_nil }
      end
    end

    context "remand return event" do
      subject do
        events.find { |event| event.type == :remand_return && event.date == 2.days.ago }
      end

      context "when the appeal is complete" do
        let(:status) { "Complete" }
        it { is_expected.to_not be_nil }
      end

      context "when the appeal is open" do
        it { is_expected.to be_nil }
      end
    end

    context "hearing events" do
      # Save appeal so hearings can be associated to it
      before { appeal.save! }

      let!(:held_hearing) do
        Generators::Hearing.create(disposition: :held, date: 4.days.ago, appeal: appeal)
      end

      let!(:cancelled_hearing) do
        Generators::Hearing.build(disposition: :cancelled, date: 3.days.ago, appeal: appeal)
      end

      let!(:hearing_not_closed) do
        Generators::Hearing.create(disposition: nil, appeal: appeal)
      end

      let!(:hearing_another_appeal) do
        Generators::Hearing.build(disposition: :held, date: 2.days.ago)
      end

      let!(:postponed_hearing) do
        Generators::Hearing.build(disposition: :postponed, date: 2.days.ago, appeal: appeal)
      end

      let(:hearing_held_events) do
        events.select { |event| event.type == :hearing_held }
      end

      let(:hearing_cancelled_event) do
        events.find { |event| event.type == :hearing_cancelled && event.date == 3.days.ago }
      end

      it "adds hearing events for all closed hearings associated with the appeal" do
        expect(hearing_held_events.length).to eq(1)
        expect(hearing_cancelled_event.date).to_not be_nil
      end
    end

    context "hearing transcript events" do
      # Save appeal so hearings can be associated to it
      before { appeal.save! }

      let!(:held_hearing) do
        Generators::Hearing.create(disposition: :held, appeal: appeal, transcript_sent_date: 1.day.ago)
      end

      let!(:cancelled_hearing) do
        Generators::Hearing.create(disposition: :cancelled, appeal: appeal, transcript_sent_date: 1.day.ago)
      end

      let(:transcript_events) do
        events.select { |event| event.type == :transcript }
      end

      it "adds transcript events for all held hearings associated with the appeal" do
        expect(transcript_events.length).to eq(1)
      end
    end

    context "decision event" do
      subject do
        events.find { |event| event.type == :field_grant && event.date == decision_date }
      end

      let(:disposition) { "Benefits Granted by AOJ" }

      context "when decision date is set" do
        let(:decision_date) { Time.zone.now }

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
        events.select { |event| event.type == :field_grant && event.date == issue_close_date }.length
      end

      let(:issues) do
        [Generators::Issue.build(disposition: issue_disposition, close_date: issue_close_date)]
      end

      let(:issue_disposition) { "Benefits Granted by AOJ" }
      let(:issue_close_date) { nil }

      context "when close date is set" do
        let(:issue_close_date) { Time.zone.now }

        it { is_expected.to eq(1) }
      end

      context "when no close date" do
        it { is_expected.to eq(0) }
      end

      context "when the issue close is same as decision date" do
        let(:issue_close_date) { Time.zone.now }
        let(:decision_date) { issue_close_date }
        let(:disposition) { issue_disposition }

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
        let!(:ramp_election) { RampElection.create(veteran_file_number: "999887777", notice_date: 30.days.ago) }
        it { is_expected.to_not be_nil }
      end

      context "when the Veteran has not yet been sent a RAMP notice" do
        it { is_expected.to be_nil }
      end
    end
  end

  context "#all (v1)" do
    let(:events) { appeal_events.all }
    let(:version) { 1 }

    context "when the appeal has a prior decision date" do
      let(:prior_decision_date) { 6.months.ago }
      let(:nod_date) { 8.months.ago }
      let(:soc_date) { 7.months.ago }
      let(:form9_date) { 5.months.ago }

      subject { events.map(&:type) }

      it "filters out events that happened before that date" do
        is_expected.to_not include(:nod, :soc)
        is_expected.to include(:form9)
      end
    end

    context "nod event" do
      subject do
        events.find { |event| event.type == :nod && event.date == nod_date }
      end

      context "when nod_date is set" do
        it { is_expected.to_not be_nil }
      end

      context "when nod_date is not set" do
        let(:nod_date) { nil }
        it { is_expected.to be_nil }
      end
    end

    context "soc event" do
      subject do
        events.find { |event| event.type == :soc && event.date == soc_date }
      end

      context "when soc_date is set" do
        it { is_expected.to_not be_nil }
      end

      context "when soc_date is not set" do
        let(:soc_date) { nil }
        it { is_expected.to be_nil }
      end
    end

    context "form9 event" do
      subject do
        events.find { |event| event.type == :form9 && event.date == form9_date }
      end

      context "when form9_date is set" do
        it { is_expected.to_not be_nil }
      end

      context "when form9_date is not set" do
        let(:form9_date) { nil }
        it { is_expected.to be_nil }
      end
    end

    context "ssoc events" do
      subject { events.select { |event| event.type == :ssoc } }

      context "when ssoc dates set" do
        let(:ssoc_dates) { [5.days.ago, 6.days.ago] }
        it { expect(subject.length).to eq(2) }
      end

      context "when an ssoc date falls after certification date" do
        subject { events.select { |event| event.type == :remand_ssoc } }

        let(:ssoc_dates) { [5.days.ago, 10.days.ago] }
        let(:certification_date) { 7.days.ago }

        it { expect(subject.length).to eq(1) }
      end

      context "when no ssocs" do
        it { is_expected.to be_empty }
      end
    end

    context "certification event" do
      subject do
        events.find { |event| event.type == :certified && event.date == certification_date }
      end

      context "when certification date is set" do
        let(:certification_date) { Time.zone.today - 10.days }
        it { is_expected.to_not be_nil }
      end

      context "when certification date is not set" do
        it { is_expected.to be_nil }
      end
    end

    context "activated event" do
      subject do
        events.find { |event| event.type == :activated && event.date == case_review_date }
      end

      context "when case_review_date is set" do
        let(:case_review_date) { Time.zone.today - 13.days }
        it { is_expected.to_not be_nil }
      end

      context "when case_review_date isn't set" do
        it { is_expected.to be_nil }
      end
    end

    context "hearing events" do
      # Save appeal so hearings can be associated to it
      before { appeal.save! }

      let!(:held_hearing) do
        Generators::Hearing.create(disposition: :held, date: 4.days.ago, appeal: appeal)
      end

      let!(:cancelled_hearing) do
        Generators::Hearing.build(disposition: :cancelled, date: 3.days.ago, appeal: appeal)
      end

      let!(:hearing_not_closed) do
        Generators::Hearing.create(disposition: nil, appeal: appeal)
      end

      let!(:hearing_another_appeal) do
        Generators::Hearing.build(disposition: :held, date: 2.days.ago)
      end

      let!(:postponed_hearing) do
        Generators::Hearing.build(disposition: :postponed, date: 2.days.ago, appeal: appeal)
      end

      let(:hearing_held_events) do
        events.select { |event| event.type == :hearing_held }
      end

      let(:hearing_cancelled_event) do
        events.find { |event| event.type == :hearing_cancelled && event.date == 3.days.ago }
      end

      it "adds hearing events for all closed hearings associated with the appeal" do
        expect(hearing_held_events.length).to eq(1)
        expect(hearing_cancelled_event.date).to_not be_nil
      end
    end

    context "decision event" do
      subject do
        events.find { |event| event.type == :field_grant && event.date == decision_date }
      end

      let(:disposition) { "Benefits Granted by AOJ" }

      context "when decision date is set" do
        let(:decision_date) { Time.zone.now }

        context "when disposition is valid" do
          it { is_expected.to_not be_nil }
        end
      end

      context "when no decision date" do
        it { is_expected.to be_nil }
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
  end
end
