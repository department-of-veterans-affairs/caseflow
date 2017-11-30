describe AppealAlerts do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end
  let(:series) { AppealSeries.create(appeals: [appeal]) }
  let(:appeal) do
    Generators::Appeal.build(
      status: status,
      notification_date: 1.year.ago,
      soc_date: soc_date,
      form9_date: form9_date,
      certification_date: certification_date,
      decision_date: decision_date,
      disposition: disposition
    )
  end

  let(:status) { "Advance" }
  let(:soc_date) { 5.days.ago }
  let(:form9_date) { nil }
  let(:certification_date) { nil }
  let(:decision_date) { nil }
  let(:disposition) { nil }

  let(:alerts) { AppealAlerts.new(appeal_series: series).all }

  context "#all" do
    context "form9_needed alert" do
      it "includes an alert" do
        expect(alerts.find { |alert| alert[:type] == :form9_needed }).to_not be_nil
      end
    end

    context "scheduled_hearing alert" do
      # Save appeal so hearings can be associated to it
      before { appeal.save! }
      let(:certification_date) { 3.days.ago }
      let!(:hearing) do
        Generators::Hearing.create(
          appeal_id: appeal.id,
          date: 1.day.from_now
        )
      end

      it "includes an alert" do
        expect(alerts.find { |alert| alert[:type] == :scheduled_hearing }).to_not be_nil
      end
    end

    context "hearing_no_show alert" do
      # Save appeal so hearings can be associated to it
      before { appeal.save! }
      let(:certification_date) { 3.days.ago }
      let!(:hearing) do
        Generators::Hearing.create(
          appeal_id: appeal.id,
          date: hearing_date,
          disposition: :no_show
        )
      end
      let(:hearing_date) { 1.day.ago }

      it "includes an alert" do
        expect(alerts.find { |alert| alert[:type] == :hearing_no_show }).to_not be_nil
      end

      context "when more than 15 days ago" do
        let(:hearing_date) { 16.days.ago }

        it "does not include an alert" do
          expect(alerts.find { |alert| alert[:type] == :hearing_no_show }).to be_nil
        end
      end
    end

    context "held_for_evidence alert" do
      # Save appeal so hearings can be associated to it
      before { appeal.save! }
      let(:certification_date) { 3.days.ago }
      let!(:hearing) do
        Generators::Hearing.create(
          appeal_id: appeal.id,
          date: hearing_date,
          disposition: :held,
          hold_open: 30
        )
      end
      let(:hearing_date) { 1.day.ago }

      it "includes an alert" do
        expect(alerts.find { |alert| alert[:type] == :held_for_evidence }).to_not be_nil
      end

      context "when older than the hold_open time" do
        let(:hearing_date) { 31.days.ago }

        it "does not include an alert" do
          expect(alerts.find { |alert| alert[:type] == :held_for_evidence }).to be_nil
        end
      end
    end

    context "cavc_option alert" do
      let(:status) { "Complete" }
      let(:decision_date) { 1.day.ago }
      let(:disposition) { "Allowed" }

      it "includes an alert" do
        expect(alerts.find { |alert| alert[:type] == :cavc_option }).to_not be_nil
      end

      context "when older than 120 days" do
        let(:decision_date) { 121.days.ago }

        it "does not include an alert" do
          expect(alerts.find { |alert| alert[:type] == :held_for_evidence }).to be_nil
        end
      end

      context "when not a Board decision" do
        let(:disposition) { "Benefits Granted by AOJ" }

        it "does not include an alert" do
          expect(alerts.find { |alert| alert[:type] == :held_for_evidence }).to be_nil
        end
      end
    end
  end
end
