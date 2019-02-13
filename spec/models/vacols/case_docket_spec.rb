describe VACOLS::CaseDocket do
  before do
    FeatureToggle.enable!(:test_facols)
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  let!(:nod_stage_appeal) { create(:case, bfmpro: "ADV") }

  let(:judge) { create(:user) }
  let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge.css_id) }

  let(:another_judge) { create(:user) }
  let!(:another_vacols_judge) { create(:staff, :judge_role, sdomainid: another_judge.css_id) }

  let(:nonpriority_ready_case_bfbox) { nil }
  let(:nonpriority_ready_case_docket_number) { "1801001" }
  let!(:nonpriority_ready_case) do
    create(:case,
           bfd19: 1.year.ago,
           bfac: "3",
           bfmpro: "ACT",
           bfcurloc: "81",
           bfdloout: 1.day.ago,
           bfbox: nonpriority_ready_case_bfbox,
           folder: build(:folder, tinum: nonpriority_ready_case_docket_number, titrnum: "123456789S"))
  end

  let(:original_docket_number) { nonpriority_ready_case_docket_number }
  let(:original_judge) { judge.vacols_attorney_id }
  let!(:original) do
    create(:case,
           bfd19: 1.year.ago,
           bfac: "1",
           bfmpro: "HIS",
           bfcurloc: "99",
           bfattid: "111",
           bfmemid: original_judge,
           folder: build(:folder, tinum: original_docket_number, titrnum: "123456789S"))
  end

  let(:another_nonpriority_ready_case_docket_number) { "1801002" }
  let!(:another_nonpriority_ready_case) do
    create(:case,
           bfd19: 1.year.ago,
           bfac: "1",
           bfmpro: "ACT",
           bfcurloc: "83",
           bfdloout: 1.day.ago,
           folder: build(:folder, tinum: another_nonpriority_ready_case_docket_number, titrnum: "123456789S"))
  end

  let!(:nonpriority_unready_case) do
    create(:case,
           bfd19: 1.year.ago,
           bfac: "1",
           bfmpro: "ACT",
           bfcurloc: "57",
           bfdloout: 1.day.ago)
  end

  let(:aod_ready_case_bfbox) { nil }
  let(:aod_ready_case_docket_number) { "1801003" }
  let(:aod_ready_case_ready_time) { 3.days.ago }
  let!(:aod_ready_case) do
    create(:case,
           :aod,
           bfd19: 1.year.ago,
           bfac: "3",
           bfmpro: "ACT",
           bfcurloc: "81",
           bfdloout: aod_ready_case_ready_time,
           bfbox: aod_ready_case_bfbox,
           folder: build(:folder, tinum: aod_ready_case_docket_number, titrnum: "123456789S"))
  end

  let(:postcavc_ready_case_docket_number) { "1801004" }
  let!(:postcavc_ready_case) do
    create(:case,
           :aod,
           bfd19: 1.year.ago,
           bfac: "7",
           bfmpro: "ACT",
           bfcurloc: "83",
           bfdloout: 2.days.ago,
           folder: build(:folder, tinum: postcavc_ready_case_docket_number, titrnum: "123456789S"))
  end

  let!(:aod_unready_case) do
    create(:case,
           :aod,
           bfd19: 1.year.ago,
           bfac: "1",
           bfmpro: "ACT",
           bfcurloc: "55")
  end

  context ".counts_by_priority_and_readiness" do
    subject { VACOLS::CaseDocket.counts_by_priority_and_readiness }
    it "creates counts grouped by priority and readiness" do
      expect(subject).to match_array([
                                       { "n" => 1, "priority" => 1, "ready" => 0 },
                                       { "n" => 2, "priority" => 1, "ready" => 1 },
                                       { "n" => 1, "priority" => 0, "ready" => 0 },
                                       { "n" => 2, "priority" => 0, "ready" => 1 }
                                     ])
    end
  end

  context ".nod_count" do
    subject { VACOLS::CaseDocket.nod_count }
    it "counts nod stage appeals" do
      expect(subject).to eq(1)
    end
  end

  context ".age_of_n_oldest_priority_appeals" do
    subject { VACOLS::CaseDocket.age_of_n_oldest_priority_appeals(2) }
    it "returns the sorted ages of the n oldest priority appeals" do
      expect(subject).to eq([aod_ready_case_ready_time, 2.days.ago].map(&:to_date))
    end

    context "when an appeal is tied to a judge" do
      let(:original_docket_number) { aod_ready_case_docket_number }
      let!(:hearing) do
        create(:case_hearing,
               :disposition_held,
               folder_nr: original.bfkey,
               hearing_date: 5.days.ago,
               board_member: judge.vacols_attorney_id)
      end

      it "does not include the hearing appeal" do
        expect(subject).to eq([2.days.ago.to_date])
      end
    end
  end

  context ".nonpriority_decisions_per_year" do
    subject { VACOLS::CaseDocket.nonpriority_decisions_per_year }

    before do
      10.times do
        create(:case,
               bfddec: 6.months.ago,
               bfac: "1",
               bfdc: "1")
      end

      create(:case,
             bfddec: 13.months.ago,
             bfac: "1",
             bfdc: "1")
    end

    it "counts decisions in the last year" do
      expect(subject).to eq(10)
    end
  end

  context ".distribute_nonpriority_appeals" do
    let(:genpop) { "any" }
    let(:range) { nil }
    let(:limit) { 10 }

    subject { VACOLS::CaseDocket.distribute_nonpriority_appeals(judge, genpop, range, limit) }

    it "distributes ready genpop cases" do
      expect(subject.count).to eq(2)
      expect(nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
      expect(another_nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
    end

    it "does not distribute non-ready or priority cases" do
      expect(nonpriority_unready_case.reload.bfcurloc).to eq("57")
      expect(aod_ready_case.reload.bfcurloc).to eq("81")
      expect(postcavc_ready_case.reload.bfcurloc).to eq("83")
    end

    context "when limited" do
      let(:limit) { 1 }
      it "only distributes cases to the limit" do
        expect(subject.count).to eq(1)
        expect(nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
        expect(another_nonpriority_ready_case.reload.bfcurloc).to eq("83")
      end
    end

    context "when range is specified" do
      let(:range) { 1 }
      it "only distributes cases within the range" do
        expect(subject.count).to eq(1)
        expect(nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
        expect(another_nonpriority_ready_case.reload.bfcurloc).to eq("83")
      end

      context "when the docket number is pre-y2k" do
        let(:another_nonpriority_ready_case_docket_number) { "9901002" }
        it "correctly orders the docket" do
          expect(subject.count).to eq(1)
          expect(nonpriority_ready_case.reload.bfcurloc).to eq("81")
          expect(another_nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
        end
      end
    end

    context "when a case is tied to a judge by a hearing on a prior appeal" do
      let(:hearing_judge) { judge.vacols_attorney_id }
      let!(:hearing) do
        create(:case_hearing,
               :disposition_held,
               folder_nr: original.bfkey,
               hearing_date: 5.days.ago,
               board_member: hearing_judge)
      end

      let!(:another_hearing) do
        create(:case_hearing,
               :disposition_held,
               folder_nr: another_nonpriority_ready_case.bfkey,
               hearing_date: 5.days.ago,
               board_member: another_judge.vacols_attorney_id)
      end

      context "when genpop is no" do
        let(:genpop) { "not_genpop" }
        it "distributes the case" do
          expect(subject.count).to eq(1)
          expect(nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
          expect(another_nonpriority_ready_case.reload.bfcurloc).to eq("83")
        end
      end

      context "when genpop is any" do
        it "distributes the case" do
          expect(subject.count).to eq(1)
          expect(nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
          expect(another_nonpriority_ready_case.reload.bfcurloc).to eq("83")
        end
      end

      context "when genpop is yes" do
        let(:genpop) { "only_genpop" }
        it "does not distribute the case" do
          expect(subject.count).to eq(0)
          expect(nonpriority_ready_case.reload.bfcurloc).to eq("81")
          expect(another_nonpriority_ready_case.reload.bfcurloc).to eq("83")
        end
      end

      context "when the case has been made genpop" do
        let(:hearing_judge) { "1111" }
        let(:genpop) { "only_genpop" }

        before do
          nonpriority_ready_case.update(bfhines: "GP")
        end

        it "distributes the case" do
          expect(subject.count).to eq(1)
          expect(nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
          expect(another_nonpriority_ready_case.reload.bfcurloc).to eq("83")
        end
      end
    end

    context "when the case is set aside for a specialty case team" do
      let(:nonpriority_ready_case_bfbox) { "01" }

      it "does not distribute the case" do
        expect(nonpriority_ready_case.reload.bfcurloc).to eq("81")
      end
    end

    context "when the case has pending mail" do
      let(:mltype) { "01" }
      let!(:mail) { create(:mail, mlfolder: nonpriority_ready_case.bfkey, mltype: mltype) }

      it "does not distribute the case" do
        expect(subject.count).to eq(1)
        expect(nonpriority_ready_case.reload.bfcurloc).to eq("81")
      end

      context "when the mail should not block distribution" do
        let(:mltype) { "02" }

        it "distributes the case" do
          expect(subject.count).to eq(2)
          expect(nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
        end
      end
    end

    context "when the case has a pending diary" do
      let(:code) { "POA" }
      let!(:diary) { create(:diary, tsktknm: nonpriority_ready_case.bfkey, tskactcd: code) }

      it "does not distribute the case" do
        expect(subject.count).to eq(1)
        expect(nonpriority_ready_case.reload.bfcurloc).to eq("81")
      end

      context "when the diary should not block distribution" do
        let(:code) { "IHP" }

        it "distributes the case" do
          expect(subject.count).to eq(2)
          expect(nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
        end
      end
    end
  end

  context ".distribute_priority_appeals" do
    let(:genpop) { "any" }
    let(:limit) { 10 }

    subject { VACOLS::CaseDocket.distribute_priority_appeals(judge, genpop, limit) }

    it "distributes ready genpop cases" do
      expect(subject.count).to eq(2)
      expect(aod_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
      expect(postcavc_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
    end

    it "does not distribute non-ready or nonpriority cases" do
      expect(aod_unready_case.reload.bfcurloc).to eq("55")
      expect(nonpriority_ready_case.reload.bfcurloc).to eq("81")
    end

    context "when limited" do
      let(:limit) { 1 }
      it "only distributes cases to the limit" do
        expect(subject.count).to eq(1)
        expect(aod_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
        expect(postcavc_ready_case.reload.bfcurloc).to eq("83")
      end
      context "when the expected order is reversed" do
        let(:aod_ready_case_ready_time) { 1.day.ago }
        it "orders by ready time, not docket date" do
          expect(subject.count).to eq(1)
          expect(aod_ready_case.reload.bfcurloc).to eq("81")
          expect(postcavc_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
        end
      end
    end

    context "when a case is tied to a judge by a hearing on a prior appeal" do
      let(:original_docket_number) { aod_ready_case_docket_number }
      let(:hearing_judge) { judge.vacols_attorney_id }
      let!(:hearing) do
        create(:case_hearing,
               :disposition_held,
               folder_nr: original.bfkey,
               hearing_date: 5.days.ago,
               board_member: hearing_judge)
      end

      let!(:another_hearing) do
        create(:case_hearing,
               :disposition_held,
               folder_nr: postcavc_ready_case.bfkey,
               hearing_date: 5.days.ago,
               board_member: another_judge.vacols_attorney_id)
      end

      context "when genpop is no" do
        let(:genpop) { "not_genpop" }
        it "distributes the case" do
          expect(subject.count).to eq(1)
          expect(aod_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
          expect(postcavc_ready_case.reload.bfcurloc).to eq("83")
        end
      end

      context "when genpop is any" do
        it "distributes the case" do
          expect(subject.count).to eq(1)
          expect(aod_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
          expect(postcavc_ready_case.reload.bfcurloc).to eq("83")
        end
      end

      context "when genpop is yes" do
        let(:genpop) { "only_genpop" }
        it "does not distribute the case" do
          expect(subject.count).to eq(0)
          expect(aod_ready_case.reload.bfcurloc).to eq("81")
          expect(postcavc_ready_case.reload.bfcurloc).to eq("83")
        end
      end

      context "when the case has been made genpop" do
        let(:hearing_judge) { "1111" }
        let(:genpop) { "only_genpop" }

        before do
          aod_ready_case.update(bfhines: "GP")
        end

        it "distributes the case" do
          expect(subject.count).to eq(1)
          expect(aod_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
          expect(postcavc_ready_case.reload.bfcurloc).to eq("83")
        end
      end
    end

    context "when an aod case is tied to the same judge as last decided the case" do
      let(:original_docket_number) { aod_ready_case_docket_number }
      let(:genpop) { "not_genpop" }

      it "distributes the case" do
        subject
        expect(aod_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
      end

      context "when a different judge decided the case" do
        let(:original_judge) { "1111" }
        it "does not distribute the case" do
          subject
          expect(aod_ready_case.reload.bfcurloc).to eq("81")
        end
      end

      context "when distributing genpop cases" do
        let(:genpop) { "only_genpop" }

        context "when a placeholder judge code is used" do
          let(:original_judge) { "000" }

          it "distributes the case" do
            subject
            expect(aod_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
          end
        end

        context "when the case has been made genpop" do
          before do
            aod_ready_case.update(bfhines: "GP")
          end

          it "distributes the case" do
            subject
            expect(aod_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
          end
        end
      end
    end

    context "when the case is set aside for a specialty case team" do
      let(:aod_ready_case_bfbox) { "01" }

      it "does not distribute the case" do
        expect(aod_ready_case.reload.bfcurloc).to eq("81")
      end
    end

    context "when the case has pending mail" do
      let(:mltype) { "01" }
      let!(:mail) { create(:mail, mlfolder: aod_ready_case.bfkey, mltype: mltype) }

      it "does not distribute the case" do
        expect(subject.count).to eq(1)
        expect(aod_ready_case.reload.bfcurloc).to eq("81")
      end

      context "when the mail should not block distribution" do
        let(:mltype) { "02" }

        it "distributes the case" do
          expect(subject.count).to eq(2)
          expect(aod_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
        end
      end
    end

    context "when the case has a pending diary" do
      let(:code) { "POA" }
      let!(:diary) { create(:diary, tsktknm: aod_ready_case.bfkey, tskactcd: code) }

      it "does not distribute the case" do
        expect(subject.count).to eq(1)
        expect(aod_ready_case.reload.bfcurloc).to eq("81")
      end

      context "when the diary should not block distribution" do
        let(:code) { "IHP" }

        it "distributes the case" do
          expect(subject.count).to eq(2)
          expect(aod_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
        end
      end
    end
  end
end
