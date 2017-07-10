describe AppealEvents do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:appeal) do
    Generators::Appeal.build(
      nod_date: nod_date,
      soc_date: soc_date,
      form9_date: form9_date,
      ssoc_dates: ssoc_dates,
      certification_date: certification_date,
      case_review_date: case_review_date,
      decision_date: decision_date,
      disposition: disposition,
      prior_decision_date: prior_decision_date
    )
  end

  let(:nod_date) { 3.days.ago }
  let(:soc_date) { 2.days.ago }
  let(:form9_date) { 1.day.ago }
  let(:ssoc_dates) { [] }
  let(:prior_decision_date) { nil }
  let(:certification_date) { nil }
  let(:case_review_date) { nil }
  let(:decision_date) { nil }
  let(:disposition) { nil }

  let(:appeal_events) { AppealEvents.new(appeal: appeal) }

  context "#all" do
    let(:events) { appeal_events.all }

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

      let!(:canceled_hearing) do
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

        context "when disposition is invalid" do
          let(:disposition) { "Invalid, Yikes" }
          it { is_expected.to be_nil }
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
