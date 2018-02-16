describe AppealSeries do
  before do
    Timecop.freeze(Time.utc(2015, 1, 30, 12, 0, 0))
  end

  let(:series) { AppealSeries.create(appeals: appeals) }
  let(:appeals) { [latest_appeal] }
  let(:latest_appeal) do
    Generators::Appeal.build(
      type: type,
      nod_date: nod_date,
      soc_date: soc_date,
      ssoc_dates: ssoc_dates,
      form9_date: form9_date,
      certification_date: certification_date,
      decision_date: decision_date,
      disposition: disposition,
      location_code: location_code,
      status: status
    )
  end

  let(:type) { "Original" }
  let(:nod_date) { 3.days.ago }
  let(:soc_date) { 1.day.ago }
  let(:ssoc_dates) { [] }
  let(:form9_date) { 1.day.ago }
  let(:certification_date) { nil }
  let(:decision_date) { nil }
  let(:disposition) { nil }
  let(:location_code) { "77" }
  let(:status) { "Advance" }

  context "#vacols_ids" do
    subject { series.vacols_ids }

    let(:appeals) do
      [
        Generators::Appeal.build(
          vacols_id: "1234567",
          status: "Active",
          last_location_change_date: 1.day.ago
        ),
        Generators::Appeal.build(
          vacols_id: "7654321",
          status: "Active",
          last_location_change_date: 2.days.ago
        )
      ]
    end

    it { is_expected.to eq %w[1234567 7654321] }
  end

  context "#latest_appeal" do
    subject { series.latest_appeal.vacols_id }

    context "when there are multiple active appeals" do
      let(:appeals) do
        [
          Generators::Appeal.build(
            vacols_id: "1234567",
            status: "Active",
            last_location_change_date: 1.day.ago
          ),
          Generators::Appeal.build(
            vacols_id: "7654321",
            status: "Active",
            last_location_change_date: 2.days.ago
          )
        ]
      end

      it { is_expected.to eq "1234567" }
    end

    context "when there are no active appeals" do
      let(:appeals) do
        [
          Generators::Appeal.build(
            vacols_id: "1234567",
            status: "Complete",
            decision_date: 1.day.ago
          ),
          Generators::Appeal.build(
            vacols_id: "7654321",
            status: "Complete",
            decision_date: 2.days.ago
          )
        ]
      end

      it { is_expected.to eq "1234567" }
    end
  end

  context "#location" do
    subject { series.location }

    context "when it is in advance status" do
      it { is_expected.to eq(:aoj) }
    end

    context "when it is in remand status" do
      let(:status) { "Remand" }
      it { is_expected.to eq(:aoj) }
    end

    context "when it is in any other status" do
      let(:status) { "History" }
      it { is_expected.to eq(:bva) }
    end
  end

  context "#program" do
    subject { series.program }

    before do
      latest_appeal.issues << Generators::Issue.build
    end

    context "when there is only one program on appeal" do
      it { is_expected.to eq(:compensation) }
    end

    context "when there are multiple programs on appeal" do
      before do
        latest_appeal.issues << Generators::Issue.build(codes: %w[07 07 02])
      end

      it { is_expected.to eq(:multiple) }
    end
  end

  context "#aoj" do
    subject { series.aoj }

    context "when the first issue on appeal has no aoj" do
      before do
        latest_appeal.issues << Generators::Issue.build(codes: %w[10 01 02])
        latest_appeal.issues << Generators::Issue.build
      end

      it { is_expected.to eq(:vba) }
    end
  end

  context "#status" do
    subject { series.status }

    context "when it is in advance status" do
      it { is_expected.to eq(:pending_certification) }

      context "and it has received one or more ssocs" do
        let(:ssoc_dates) { [1.day.ago] }
        it { is_expected.to eq(:pending_certification_ssoc) }
      end

      context "and it has been certified" do
        let(:certification_date) { 1.day.ago }
        it { is_expected.to eq(:on_docket) }
      end

      context "and it has no form 9" do
        let(:form9_date) { nil }
        it { is_expected.to eq(:pending_form9) }

        context "and it has no soc" do
          let(:soc_date) { nil }
          it { is_expected.to eq(:pending_soc) }
        end
      end
    end

    context "when it is in active status" do
      let(:status) { "Active" }
      it { is_expected.to eq(:decision_in_progress) }

      context "and it is in location 49" do
        let(:location_code) { "49" }
        it { is_expected.to eq(:stayed) }
      end

      context "and it is in location 55" do
        let(:location_code) { "55" }
        it { is_expected.to eq(:at_vso) }
      end

      context "and it is in location 20" do
        let(:location_code) { "20" }
        it { is_expected.to eq(:bva_development) }
      end

      context "and it is in location 18" do
        let(:location_code) { "18" }
        it { is_expected.to eq(:bva_development) }
      end
    end

    context "when it is in history status" do
      let(:status) { "Complete" }

      context "when decided by the board" do
        let(:disposition) { "Allowed" }
        it { is_expected.to eq(:bva_decision) }
      end

      context "when granted by the aoj" do
        let(:disposition) { "Advance Allowed in Field" }
        it { is_expected.to eq(:field_grant) }
      end

      context "when withdrawn" do
        let(:disposition) { "Withdrawn" }
        it { is_expected.to eq(:withdrawn) }
      end

      context "when ftr" do
        let(:disposition) { "Advance Failure to Respond" }
        it { is_expected.to eq(:ftr) }
      end

      context "when ramp" do
        let(:disposition) { "RAMP Opt-in" }
        it { is_expected.to eq(:ramp) }
      end

      context "when death" do
        let(:disposition) { "Dismissed, Death" }
        it { is_expected.to eq(:death) }
      end

      context "when reconsideration by letter" do
        let(:disposition) { "Reconsideration by Letter" }
        it { is_expected.to eq(:reconsideration) }
      end

      context "when any other disposition" do
        let(:disposition) { "Not a real disposition" }
        it { is_expected.to eq(:other_close) }
      end
    end

    context "when it is in remand status" do
      let(:status) { "Remand" }
      let(:decision_date) { 3.days.ago }
      it { is_expected.to eq(:remand) }

      context "and it has received a post-decision ssoc" do
        let(:ssoc_dates) { [1.day.ago] }
        it { is_expected.to eq(:remand_ssoc) }
      end

      context "and it has a pre-decision ssoc" do
        let(:ssoc_dates) { [5.days.ago] }
        it { is_expected.to eq(:remand) }
      end
    end

    context "when it is in motion status" do
      let(:status) { "Motion" }
      it { is_expected.to eq(:motion) }
    end

    context "when it is in cavc status" do
      let(:status) { "CAVC" }
      it { is_expected.to eq(:cavc) }
    end
  end

  context "#status_hash" do
    subject { series.status_hash }

    context "when there is a valid status" do
      it "returns a hash with a type and details" do
        expect(subject[:type]).to eq(:pending_certification)
        expect(subject[:details].is_a?(Hash)).to be_truthy
      end
    end

    context "when there is no known status" do
      let(:status) { "Not a real status" }

      it "returns an empty details hash" do
        expect(subject[:details]).to eq({})
      end
    end

    context "when it is in remand ssoc status" do
      let(:status) { "Remand" }
      let(:decision_date) { 3.days.ago }
      let(:ssoc_dates) { [1.year.ago, 1.day.ago] }

      it "returns a details hash with the most recent ssoc" do
        expect(subject[:type]).to eq(:remand_ssoc)
        expect(subject[:details][:last_soc_date]).to eq(1.day.ago.to_date)
        expect(subject[:details][:return_timeliness]).to eq([1, 2])
        expect(subject[:details][:remand_ssoc_timeliness]).to eq([3, 10])
      end
    end

    context "when it has been decided by the board" do
      let(:status) { "Remand" }
      let(:disposition) { "Allowed" }
      before do
        latest_appeal.issues << Generators::Issue.build(disposition: :allowed)
        latest_appeal.issues << Generators::Issue.build(disposition: :remanded)
        latest_appeal.issues << Generators::Issue.build(disposition: :field_grant)
      end

      it "returns a details hash with the decided issues" do
        expect(subject[:type]).to eq(:remand)
        expect(subject[:details][:remand_timeliness]).to eq([7, 17])
        expect(subject[:details][:issues].length).to eq(2)
        expect(subject[:details][:issues].first[:disposition]).to eq(:allowed)
        expect(subject[:details][:issues].first[:description]).to eq("Service connection, limitation of thigh motion")
      end
    end

    context "when it is at VSO" do
      let(:status) { "Active" }
      let(:location_code) { "55" }

      it "returns a details hash with the vso name" do
        expect(subject[:type]).to eq(:at_vso)
        expect(subject[:details][:vso_name]).to eq("Military Order of the Purple Heart")
      end
    end

    context "when it is pending a form 9" do
      let(:form9_date) { nil }

      it "returns a details hash with the vso name" do
        expect(subject[:type]).to eq(:pending_form9)
        expect(subject[:details][:certification_timeliness]).to eq([2, 12])
        expect(subject[:details][:ssoc_timeliness]).to eq([7, 20])
      end
    end
  end

  context "#alerts" do
    subject { series.alerts }
    let(:form9_date) { nil }

    it "returns list of alerts" do
      expect(!subject.empty?).to be_truthy
      expect(subject.first[:type]).to eq(:form9_needed)
    end
  end

  context "#docket" do
    subject { series.docket }

    before { DocketSnapshot.create }

    context "when the appeal is original and not aod" do
      before { series.appeals.each { |appeal| appeal.aod = false } }

      it "has a docket" do
        expect(subject).to_not be_nil
      end
    end

    context "when the appeal is post-cavc" do
      before { series.appeals.each { |appeal| appeal.aod = false } }
      let(:type) { "Court Remand" }

      it "does not have a docket" do
        expect(subject).to be_nil
      end
    end

    context "when the appeal is aod" do
      it "does not have a docket" do
        expect(subject).to be_nil
      end
    end

    context "when there is no form 9" do
      before { series.appeals.each { |appeal| appeal.aod = false } }
      let(:form9_date) { nil }

      it "does not have a docket" do
        expect(subject).to be_nil
      end
    end
  end

  context "#docket_hash" do
    subject { series.docket_hash }

    context "when the docket is nil" do
      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  context "#description" do
    subject { series.description }

    context "when there is a single issue" do
      before do
        latest_appeal.issues << Generators::Issue.build
      end

      it { is_expected.to eq("Service connection, limitation of thigh motion") }
    end

    context "when that issue is new and materials" do
      before do
        latest_appeal.issues << Generators::Issue.build(codes: %w[02 15 04 5252])
      end

      it { is_expected.to eq("Service connection, limitation of thigh motion") }
    end

    context "when there are multiple issues" do
      before do
        latest_appeal.issues << Generators::Issue.build(codes: %w[02 17 02], vacols_sequence_id: 1)
        latest_appeal.issues << Generators::Issue.build(vacols_sequence_id: 2)
        latest_appeal.issues << Generators::Issue.build(codes: %w[02 15 03 9432], vacols_sequence_id: 3)
      end

      it { is_expected.to eq("Service connection, limitation of thigh motion, and 2 others") }
    end

    context "when those issues do not have commas" do
      before do
        latest_appeal.issues << Generators::Issue.build(codes: %w[02 17 02], vacols_sequence_id: 1)
        latest_appeal.issues << Generators::Issue.build(codes: %w[02 12 05], vacols_sequence_id: 2)
      end

      it { is_expected.to eq("100% rating for individual unemployability and 1 other") }
    end
  end
end
