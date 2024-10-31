# frozen_string_literal: true

describe VACOLS::CaseDocket, :all_dbs do
  before do
    FeatureToggle.enable!(:test_facols)
    FeatureToggle.enable!(:acd_disable_legacy_lock_ready_appeals)
    FeatureToggle.enable!(:acd_distribute_by_docket_date)
    FeatureToggle.enable!(:acd_cases_tied_to_judges_no_longer_with_board)
    FeatureToggle.enable!(:acd_exclude_from_affinity)
    create(:case_distribution_lever, :cavc_affinity_days)
    create(:case_distribution_lever, :cavc_aod_affinity_days)
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  let!(:nod_stage_appeal) { create(:case, bfmpro: "ADV") }

  let(:judge) { create(:user) }
  let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge.css_id) }

  let(:another_judge) { create(:user) }
  let!(:another_vacols_judge) { create(:staff, :judge_role, sdomainid: another_judge.css_id) }

  let(:inactive_judge) { create(:user, :inactive) }
  let!(:inactive_vacols_judge) { create(:staff, :judge_role, svlj: "V", sdomainid: inactive_judge.css_id) }

  let(:caseflow_attorney) { create(:user) }
  let!(:vacols_attorney) { create(:staff, :attorney_role, sdomainid: caseflow_attorney.css_id) }

  let(:nonpriority_ready_case_bfbox) { nil }
  let(:nonpriority_ready_case_docket_number) { "1801001" }
  let!(:nonpriority_ready_case) do
    create(:case,
           bfd19: 1.year.ago,
           bfac: "1",
           bfmpro: "ACT",
           bfcurloc: "81",
           bfdloout: 3.days.ago,
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
    create(
      :case,
      bfd19: 11.months.ago,
      bfac: "1",
      bfmpro: "ACT",
      bfcurloc: "83",
      bfdloout: 2.days.ago,
      folder: build(:folder, tinum: another_nonpriority_ready_case_docket_number, titrnum: "123456789S")
    ).tap { |vacols_case| create(:mail, :blocking, :completed, mlfolder: vacols_case.bfkey) }
  end

  let(:third_nonpriority_ready_case_docket_number) { "1801005" }
  let(:third_nonpriority_ready_case) do
    create(:case,
           bfd19: 10.months.ago,
           bfac: "1",
           bfmpro: "ACT",
           bfcurloc: "83",
           bfdloout: 1.day.ago,
           folder: build(:folder, tinum: third_nonpriority_ready_case_docket_number, titrnum: "123456789S"))
  end
  let(:inactive_original_judge) { inactive_judge.vacols_attorney_id }
  let(:inactive_original_case) do
    create(:case,
           bfd19: 1.year.ago,
           bfac: "1",
           bfmpro: "HIS",
           bfcurloc: "99",
           bfattid: "111",
           bfmemid: inactive_original_judge,
           folder: build(:folder, tinum: third_nonpriority_ready_case_docket_number, titrnum: "123456789S"))
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
           bfac: "1",
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
           bfd19: 11.months.ago,
           bfac: "7",
           bfmpro: "ACT",
           bfcurloc: "83",
           bfdloout: 2.days.ago,
           folder: build(:folder, tinum: postcavc_ready_case_docket_number, titrnum: "123456789S"))
  end

  let!(:aod_case_unready_due_to_location) do
    create(:case,
           :aod,
           bfd19: 1.year.ago,
           bfac: "1",
           bfmpro: "ACT",
           bfcurloc: "55")
  end

  let!(:aod_case_unready_due_to_blocking_mail) do
    create(:case,
           :aod,
           bfd19: 1.year.ago,
           bfac: "1",
           bfmpro: "ACT",
           bfcurloc: "81").tap { |vacols_case| create(:mail, :blocking, :incomplete, mlfolder: vacols_case.bfkey) }
  end

  context ".counts_by_priority_and_readiness" do
    # this should not be included in the count
    let!(:aoj_appeal) { create(:legacy_aoj_appeal) }

    subject { VACOLS::CaseDocket.counts_by_priority_and_readiness }
    it "creates counts grouped by priority and readiness" do
      expect(subject).to match_array([
                                       { "n" => 2, "priority" => 1, "ready" => 0 },
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

  context ".genpop_priority_count" do
    subject { VACOLS::CaseDocket.genpop_priority_count }
    it "counts genpop priority appeals" do
      expect(subject).to eq(2)
    end

    context "with affinitized appeals" do
      let!(:aod_cavc_ready_case_within_affinity) do
        create(:legacy_cavc_appeal,
               judge: vacols_judge,
               attorney: vacols_attorney,
               aod: true,
               tied_to: false,
               affinity_start_date: 3.days.ago)
      end

      let!(:cavc_ready_case_within_affinity) do
        create(:legacy_cavc_appeal,
               judge: vacols_judge,
               attorney: vacols_attorney,
               tied_to: false,
               affinity_start_date: 3.days.ago)
      end

      it "correctly filters out appeals based on the lever filters" do
        expect(subject).to eq(2)
      end
    end
  end

  context ".age_of_n_oldest_genpop_priority_appeals" do
    subject { VACOLS::CaseDocket.age_of_n_oldest_genpop_priority_appeals(2) }
    it "returns the sorted ages of the n oldest priority appeals" do
      expect(subject).to eq([aod_ready_case.bfdloout, postcavc_ready_case.bfdloout])
    end

    context "when an appeal is tied to a judge" do
      let(:original_docket_number) { aod_ready_case_docket_number }
      let!(:hearing) do
        create(:case_hearing,
               :disposition_held,
               folder_nr: original.bfkey,
               hearing_date: 5.days.ago.to_date,
               board_member: judge.vacols_attorney_id)
      end

      it "does not include the hearing appeal" do
        expect(subject).to eq([postcavc_ready_case.bfdloout])
      end
    end
  end

  context ".age_of_oldest_priority_appeal" do
    subject { VACOLS::CaseDocket.age_of_oldest_priority_appeal }

    it "returns the oldest priority appeal ready at date" do
      expect(subject).to eq(aod_ready_case.bfdloout)
    end

    context "when an appeal is tied to a judge" do
      let(:original_docket_number) { aod_ready_case_docket_number }
      let!(:hearing) do
        create(:case_hearing,
               :disposition_held,
               folder_nr: original.bfkey,
               hearing_date: 5.days.ago.to_date,
               board_member: judge.vacols_attorney_id)
      end

      it "does not affect the results of the call" do
        expect(subject).to eq(aod_ready_case.bfdloout)
      end
    end
  end

  context ".nonpriority_decisions_per_year" do
    subject { VACOLS::CaseDocket.nonpriority_decisions_per_year }

    before do
      4.times do
        create(:case,
               bfddec: 6.months.ago,
               bfac: "1",
               bfdc: "1")
      end

      4.times do
        create(:case,
               bfddec: 6.months.ago,
               bfac: "1",
               bfdc: "3")
      end

      2.times do
        create(:case,
               bfddec: 6.months.ago,
               bfac: "1",
               bfdc: "4")
      end

      create(:case,
             bfddec: 13.months.ago,
             bfac: "1",
             bfdc: "1")

      create(:case,
             bfddec: 6.months.ago,
             bfac: "7",
             bfdc: "5")

      create(:case,
             :aod,
             bfddec: 6.months.ago,
             bfac: "1",
             bfdc: "3")
    end

    it "counts decisions in the last year" do
      expect(subject).to eq(10)
    end
  end

  context ".nonpriority_hearing_cases_for_judge_count" do
    subject { VACOLS::CaseDocket.nonpriority_hearing_cases_for_judge_count(judge) }

    let(:hearing_judge) { judge.vacols_attorney_id }
    let(:first_case) { nonpriority_ready_case }
    let(:second_case) { another_nonpriority_ready_case }
    let(:third_case) { third_nonpriority_ready_case }

    before do
      create(
        :case_hearing,
        :disposition_held,
        folder_nr: first_case.bfkey,
        hearing_date: 5.days.ago.to_date,
        board_member: hearing_judge
      )

      create(
        :case_hearing,
        :disposition_held,
        folder_nr: second_case.bfkey,
        hearing_date: 5.days.ago.to_date,
        board_member: hearing_judge
      )
    end

    context "when there are only priority cases linked to the judge" do
      let(:first_case) { aod_ready_case }
      let(:second_case) { aod_ready_case }

      it "returns no cases" do
        expect(subject).to eq 0
      end
    end

    context "when there are only non priority cases linked to another judge" do
      let(:hearing_judge) { another_judge.vacols_attorney_id }

      it "returns no cases" do
        expect(subject).to eq 0
      end
    end

    context "when there are ready non priority hearings linked to the judge" do
      it "returns the number of ready non priority hearings" do
        expect(subject).to eq 2
      end
    end

    context "when there are ready non priority hearings linked to the judge and inactive judge" do
      before do
        FeatureToggle.enable!(:acd_cases_tied_to_judges_no_longer_with_board)
        third_nonpriority_ready_case
        inactive_original_case
        create(
          :case_hearing,
          :disposition_held,
          folder_nr: third_case.bfkey,
          hearing_date: 5.days.ago.to_date,
          board_member: inactive_judge.vacols_attorney_id
        )
      end

      it "returns the number of ready non priority hearings" do
        allow(Rails.cache).to receive(:fetch).with("case_distribution_ineligible_judges")
          .and_return([{ sattyid: inactive_vacols_judge.sattyid }])
        allow(DatabaseRequestCounter).to receive(:increment_counter).and_return(3)

        expect(subject).to eq 3
      end
    end
  end

  context ".distribute_nonpriority_appeals" do
    let(:genpop) { "any" }
    let(:range) { nil }
    let(:limit) { 10 }
    let(:bust_backlog) { false }

    before do
      FeatureToggle.enable!(:acd_cases_tied_to_judges_no_longer_with_board)
      nonpriority_ready_case.reload
      another_nonpriority_ready_case.reload
      third_nonpriority_ready_case.reload
    end

    subject { VACOLS::CaseDocket.distribute_nonpriority_appeals(judge, genpop, range, limit, bust_backlog) }

    it "distributes ready genpop cases" do
      expect(subject.count).to eq(3)
      expect(nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
      expect(another_nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
      expect(third_nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
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
        expect(subject.first["bfkey"]).to eq nonpriority_ready_case.bfkey
        expect(nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
        expect(another_nonpriority_ready_case.reload.bfcurloc).to eq("83")
        expect(third_nonpriority_ready_case.reload.bfcurloc).to eq("83")
      end
    end

    context "when range is specified" do
      let(:range) { 1 }

      # We do not provide a range if this feature toggle is enabled
      before { FeatureToggle.disable!(:acd_distribute_by_docket_date) }

      it "only distributes cases within the range" do
        expect(subject.count).to eq(1)
        expect(subject.first["bfkey"]).to eq nonpriority_ready_case.bfkey
        expect(nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
        expect(another_nonpriority_ready_case.reload.bfcurloc).to eq("83")
        expect(third_nonpriority_ready_case.reload.bfcurloc).to eq("83")
      end

      context "when the docket number is pre-y2k" do
        let(:another_nonpriority_ready_case_docket_number) { "9901002" }
        it "correctly orders the docket" do
          expect(subject.count).to eq(1)
          expect(subject.first["bfkey"]).to eq another_nonpriority_ready_case.bfkey
          expect(nonpriority_ready_case.reload.bfcurloc).to eq("81")
          expect(another_nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
          expect(third_nonpriority_ready_case.reload.bfcurloc).to eq("83")
        end
      end
    end

    context "when a case is tied to a judge by a hearing on a prior appeal" do
      let(:hearing_judge) { judge.vacols_attorney_id }
      let(:another_hearing_judge) { another_judge.vacols_attorney_id }
      let!(:hearing) do
        create(:case_hearing,
               :disposition_held,
               folder_nr: original.bfkey,
               hearing_date: 5.days.ago.to_date,
               board_member: hearing_judge)
      end

      let!(:another_hearing) do
        create(:case_hearing,
               :disposition_held,
               folder_nr: another_nonpriority_ready_case.bfkey,
               hearing_date: 5.days.ago.to_date,
               board_member: another_hearing_judge)
      end

      context "when genpop is no" do
        let(:genpop) { "not_genpop" }
        it "distributes the case" do
          expect(subject.count).to eq(1)
          expect(subject.first["bfkey"]).to eq nonpriority_ready_case.bfkey
          expect(nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
          expect(another_nonpriority_ready_case.reload.bfcurloc).to eq("83")
          expect(third_nonpriority_ready_case.reload.bfcurloc).to eq("83")
        end
      end

      context "when genpop is any" do
        it "distributes the case" do
          expect(subject.count).to eq(2)
          expect(nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
          expect(another_nonpriority_ready_case.reload.bfcurloc).to eq("83")
          expect(third_nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
        end
      end

      context "when genpop is yes" do
        let(:genpop) { "only_genpop" }
        it "does distribute the case only tied to inactive judge" do
          expect(subject.count).to eq(1)
          expect(subject.first["bfkey"]).to eq third_nonpriority_ready_case.bfkey
          expect(third_nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
          expect(nonpriority_ready_case.reload.bfcurloc).to eq("81")
          expect(another_nonpriority_ready_case.reload.bfcurloc).to eq("83")
        end
      end

      context "when bust backlog is specified" do
        let(:limit) { 2 }
        let(:bust_backlog) { true }
        let(:another_hearing_judge) { judge.vacols_attorney_id }

        # We don't use bust backlog if this feature toggle is enabled
        before { FeatureToggle.disable!(:acd_distribute_by_docket_date) }

        context "when the judge does not have 30 cases in their backlog" do
          it "does not distribute any appeals" do
            expect(subject.count).to eq(0)
            expect(nonpriority_ready_case.reload.bfcurloc).to eq("81")
            expect(another_nonpriority_ready_case.reload.bfcurloc).to eq("83")
          end
        end

        context "when the judge's backlog is full" do
          let(:number_of_cases_over_backlog) { 1 }

          before do
            allow(VACOLS::CaseDocket).to receive(:nonpriority_hearing_cases_for_judge_count).with(judge)
              .and_return(VACOLS::CaseDocket::HEARING_BACKLOG_LIMIT + number_of_cases_over_backlog)
          end

          it "only distributes the one case to get back down to 30" do
            expect(subject.count).to eq(number_of_cases_over_backlog)
            expect(subject.first["bfkey"]).to eq nonpriority_ready_case.bfkey
            expect(nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
            expect(another_nonpriority_ready_case.reload.bfcurloc).to eq("83")
          end
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
        expect(subject.count).to eq(2)
        expect(nonpriority_ready_case.reload.bfcurloc).to eq("81")
      end

      context "when the mail should not block distribution" do
        let(:mltype) { "02" }

        it "distributes the case" do
          expect(subject.count).to eq(3)
          expect(nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
        end
      end
    end

    context "when the case has a pending diary" do
      let(:code) { "POA" }
      let!(:diary) { create(:diary, tsktknm: nonpriority_ready_case.bfkey, tskactcd: code) }

      it "does not distribute the case" do
        expect(subject.count).to eq(2)
        expect(nonpriority_ready_case.reload.bfcurloc).to eq("81")
      end

      context "when the diary should not block distribution" do
        let(:code) { "IHP" }

        it "distributes the case" do
          expect(subject.count).to eq(3)
          expect(nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
          expect(third_nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
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
      expect(aod_case_unready_due_to_location.reload.bfcurloc).to eq("55")
      expect(nonpriority_ready_case.reload.bfcurloc).to eq("81")
    end

    context "when limited" do
      let(:limit) { 1 }
      it "only distributes cases to the limit" do
        expect(subject.count).to eq(1)
        expect(aod_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
        expect(postcavc_ready_case.reload.bfcurloc).to eq("83")
      end
    end

    context "when a case is tied to a judge by a hearing on a prior appeal" do
      let(:original_docket_number) { aod_ready_case_docket_number }
      let(:hearing_judge) { judge.vacols_attorney_id }
      let(:another_hearing_judge) { another_judge.vacols_attorney_id }
      let!(:hearing) do
        create(:case_hearing,
               :disposition_held,
               folder_nr: original.bfkey,
               hearing_date: 5.days.ago.to_date,
               board_member: hearing_judge)
      end

      let!(:another_hearing) do
        create(:case_hearing,
               :disposition_held,
               folder_nr: postcavc_ready_case.bfkey,
               hearing_date: 5.days.ago.to_date,
               board_member: another_hearing_judge)
      end

      context "when genpop is no" do
        let(:genpop) { "not_genpop" }
        it "distributes the case" do
          expect(subject.count).to eq(1)
          expect(aod_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
          expect(postcavc_ready_case.reload.bfcurloc).to eq("83")
        end

        context "when limit is nil" do
          let(:limit) { nil }
          let(:another_hearing_judge) { judge.vacols_attorney_id }

          it "distributes all cases tied to the judge" do
            expect(subject.count).to eq(2)
            expect(aod_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
            expect(postcavc_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
          end
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
    end

    context "when an aod case is tied to the same judge as last decided the case" do
      let(:original_docket_number) { aod_ready_case_docket_number }
      let(:genpop) { "not_genpop" }

      it "does not distribute the case" do
        subject
        expect(aod_ready_case.reload.bfcurloc).to eq("81")
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

    context "when CaseDistributionLever" do
      before do
        VACOLS::Case.where(bfcurloc: %w[81 83]).map { |c| c.update!(bfcurloc: "testing") }
        Rails.cache.fetch("case_distribution_ineligible_judges", expires_in: 1.day) { ineligible_judges_list }
      end

      let(:aff_judge_caseflow) { create(:user) }
      let!(:aff_judge) { create(:staff, :judge_role, sdomainid: aff_judge_caseflow.css_id) }

      let(:other_judge_caseflow) { create(:user) }
      let!(:other_judge) { create(:staff, :judge_role, sdomainid: other_judge_caseflow.css_id) }

      let(:tied_judge_caseflow) { create(:user) }
      let!(:tied_judge) { create(:staff, :judge_role, sdomainid: tied_judge_caseflow.css_id) }

      let(:inel_judge_caseflow) { create(:user) }
      let!(:inel_judge) { create(:staff, :judge_role, svlj: "V", sdomainid: inel_judge_caseflow.css_id) }

      let(:excl_judge_caseflow) { create(:user, :judge_with_appeals_excluded_from_affinity) }
      let!(:excl_judge) { create(:staff, :judge_role, sdomainid: excl_judge_caseflow.css_id) }

      let(:attorney_caseflow) { create(:user) }
      let!(:attorney) { create(:staff, :attorney_role, sdomainid: attorney_caseflow.css_id) }

      let(:ineligible_judges_list) do
        list = []
        [[inel_judge_caseflow, inel_judge], [attorney_caseflow, attorney]].each do |user, staff|
          list.push({
                      sattyid: staff.sattyid,
                      sdomaini: staff.sdomainid,
                      svlj: staff.svlj,
                      id: user.id,
                      css_id: user.css_id
                    })
        end
        list
      end

      context ".cavc_affinity_days lever is active" do
        # cavc affinity cases:
        # no hearing held but has previous decision
        let!(:c1) do
          create(:legacy_cavc_appeal, judge: aff_judge, attorney: attorney, tied_to: false)
        end
        let!(:c2) do
          create(:legacy_cavc_appeal, judge: aff_judge, attorney: attorney,
                                      tied_to: false, affinity_start_date: 3.days.ago)
        end
        let!(:c3) do
          create(:legacy_cavc_appeal, judge: aff_judge, attorney: attorney,
                                      tied_to: false, appeal_affinity: false)
        end
        # hearing held with previous decision where judge is not the same
        let!(:c4) do
          c4 = create(:legacy_cavc_appeal, judge: other_judge, attorney: attorney)
          c4.update!(bfmemid: aff_judge.sattyid)
          c4
        end
        let!(:c5) do
          c5 = create(:legacy_cavc_appeal, judge: other_judge, attorney: attorney,
                                           affinity_start_date: 3.days.ago)
          c5.update!(bfmemid: aff_judge.sattyid)
          c5
        end
        let!(:c6) do
          c6 = create(:legacy_cavc_appeal, judge: other_judge, attorney: attorney, appeal_affinity: false)
          c6.update!(bfmemid: aff_judge.sattyid)
          c6
        end
        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        let!(:c7) { create(:legacy_cavc_appeal, judge: tied_judge, attorney: attorney) }
        let!(:c8) do
          create(:legacy_cavc_appeal, judge: tied_judge, attorney: attorney, affinity_start_date: 3.days.ago)
        end
        let!(:c9) { create(:legacy_cavc_appeal, judge: tied_judge, attorney: attorney, appeal_affinity: false) }
        # hearing held but no previous deciding judge where hearing judge is active
        let!(:c10) do
          c10 = create(:legacy_cavc_appeal, judge: tied_judge, attorney: attorney)
          c10.update!(bfmemid: nil)
          c10
        end
        # no hearing held, no previous deciding judge
        let!(:c11) do
          c11 = create(:legacy_cavc_appeal, judge: aff_judge, attorney: attorney,
                                            tied_to: false)
          c11.update!(bfmemid: nil)
          c11
        end
        # excluded judge cases:
        # no hearing held but has previous decision
        let!(:c12) { create(:legacy_cavc_appeal, judge: excl_judge, attorney: attorney, tied_to: false) }
        let!(:c13) do
          create(:legacy_cavc_appeal, judge: excl_judge, attorney: attorney,
                                      tied_to: false, affinity_start_date: 3.days.ago)
        end
        let!(:c14) do
          create(:legacy_cavc_appeal, judge: excl_judge, attorney: attorney,
                                      tied_to: false, appeal_affinity: false)
        end
        # hearing held with previous decision where judge is not the same
        let!(:c15) do
          c15 = create(:legacy_cavc_appeal, judge: other_judge, attorney: attorney)
          c15.update!(bfmemid: excl_judge.sattyid)
          c15
        end
        let!(:c16) do
          c16 = create(:legacy_cavc_appeal, judge: other_judge, attorney: attorney,
                                            affinity_start_date: 3.days.ago)
          c16.update!(bfmemid: excl_judge.sattyid)
          c16
        end
        let!(:c17) do
          c17 = create(:legacy_cavc_appeal, judge: other_judge, attorney: attorney, appeal_affinity: false)
          c17.update!(bfmemid: excl_judge.sattyid)
          c17
        end
        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        let!(:c18) { create(:legacy_cavc_appeal, judge: excl_judge, attorney: attorney) }
        let!(:c19) do
          create(:legacy_cavc_appeal, judge: excl_judge, attorney: attorney, affinity_start_date: 3.days.ago)
        end
        let!(:c20) do
          create(:legacy_cavc_appeal, judge: excl_judge, attorney: attorney, appeal_affinity: false)
        end
        # ineligible judge cases:
        # no hearing held but has previous decision
        let!(:c21) { create(:legacy_cavc_appeal, judge: inel_judge, attorney: attorney, tied_to: false) }
        let!(:c22) do
          create(:legacy_cavc_appeal, judge: inel_judge, attorney: attorney,
                                      tied_to: false, affinity_start_date: 3.days.ago)
        end
        let!(:c23) do
          create(:legacy_cavc_appeal, judge: inel_judge, attorney: attorney,
                                      tied_to: false, appeal_affinity: false)
        end
        # hearing held with previous decision where judge is not the same
        let!(:c24) do
          c24 = create(:legacy_cavc_appeal, judge: other_judge, attorney: attorney)
          c24.update!(bfmemid: inel_judge.sattyid)
          c24
        end
        let!(:c25) do
          c25 = create(:legacy_cavc_appeal, judge: other_judge, attorney: attorney,
                                            affinity_start_date: 3.days.ago)
          c25.update!(bfmemid: inel_judge.sattyid)
          c25
        end
        let!(:c26) do
          c26 = create(:legacy_cavc_appeal, judge: other_judge, attorney: attorney, appeal_affinity: false)
          c26.update!(bfmemid: inel_judge.sattyid)
          c26
        end
        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        let!(:c27) { create(:legacy_cavc_appeal, judge: inel_judge, attorney: attorney) }
        let!(:c28) do
          create(:legacy_cavc_appeal, judge: inel_judge, attorney: attorney,  affinity_start_date: 3.days.ago)
        end
        let!(:c29) do
          create(:legacy_cavc_appeal, judge: inel_judge, attorney: attorney,  appeal_affinity: false)
        end
        # hearing held but no previous deciding judge where hearing judge is ineligible
        let!(:c30) do
          c30 = create(:legacy_cavc_appeal, judge: inel_judge, attorney: attorney)
          c30.update!(bfmemid: nil)
          c30
        end
        # hearing held with previous decision where judge is not the same but hearing judge is ineligible
        let!(:c31) do
          c31 = create(:legacy_cavc_appeal, judge: inel_judge, attorney: attorney)
          c31.update!(bfmemid: other_judge.sattyid)
          c31
        end
        let!(:c32) do
          c32 = create(:legacy_cavc_appeal, judge: inel_judge, attorney: attorney,
                                            affinity_start_date: 3.days.ago)
          c32.update!(bfmemid: other_judge.sattyid)
          c32
        end
        let!(:c33) do
          c33 = create(:legacy_cavc_appeal, judge: inel_judge, attorney: attorney, appeal_affinity: false)
          c33.update!(bfmemid: other_judge.sattyid)
          c33
        end
        # hearing held by excluded judge with no previous decision (tied to excl judge)
        let!(:c34) do
          c34 = create(:legacy_cavc_appeal, judge: excl_judge, attorney: attorney)
          c34.update!(bfmemid: nil)
          c34
        end

        it "distributes CAVC cases correctly based on lever value", :aggregate_failures do
          cavc_lever = CaseDistributionLever.find_by_item(Constants.DISTRIBUTION.cavc_affinity_days)

          # {FOR LEVER BEING A VALUE:}
          cavc_lever.update!(value: 14)
          CaseDistributionLever.clear_distribution_lever_cache
          expect(VACOLS::CaseDocket.distribute_priority_appeals(judge, "any", 100, true).map { |c| c["bfkey"] }.sort)
            .to match_array(
              [c1, c4, c11, c12, c13, c14, c15, c16, c17, c21, c22,
               c23, c24, c25, c26, c27, c28, c29, c30, c31]
              .map { |c| (c["bfkey"].to_i + 1).to_s }.sort
            )
          # {FOR LEVER BEING INFINITE:}
          cavc_lever.update!(value: "infinite")
          CaseDistributionLever.clear_distribution_lever_cache
          expect(
            VACOLS::CaseDocket.distribute_priority_appeals(judge, "any", 100, true).map { |c| c["bfkey"] }.sort
          )
            .to match_array(
              [c11, c12, c13, c14, c15, c16, c17, c21, c22, c23, c24, c25, c26, c27, c28, c29, c30]
              .map { |c| (c["bfkey"].to_i + 1).to_s }.sort
            )

          # ensure that excluded judge recieves their tied cases which would not go to default judge
          expect(VACOLS::CaseDocket.distribute_priority_appeals(excl_judge_caseflow, "any", 100, true)
              .map { |c| c["bfkey"] }.sort)
            .to match_array([
              c11, c12, c13, c14, c15, c16, c17, c18, c19, c20, c21, c22, c23, c24,
              c25, c26, c27, c28, c29, c30, c34
            ]
            .map { |c| (c["bfkey"].to_i + 1).to_s }.sort)

          # {FOR LEVER BEING OMIT:}
          cavc_lever.update!(value: "omit")
          CaseDistributionLever.clear_distribution_lever_cache
          expect(VACOLS::CaseDocket.distribute_priority_appeals(judge, "any", 100, true).map { |c| c["bfkey"] }.sort)
            .to match_array([
              c1, c2, c3, c4, c5, c6, c11, c12, c13, c14, c15, c16,
              c17, c21, c22, c23, c24, c25, c26, c27, c28, c29, c30, c31, c32, c33
            ]
            .map { |c| (c["bfkey"].to_i + 1).to_s }.sort)
        end
      end

      context ".cavc_aod_affinity_days lever is active" do
        # cavc aod affinity cases:
        # no hearing held but has previous decision
        let!(:ca1) { create(:legacy_cavc_appeal, judge: aff_judge, attorney: attorney, aod: true, tied_to: false) }
        let!(:ca2) do
          create(:legacy_cavc_appeal,
                 judge: aff_judge, attorney: attorney, aod: true, tied_to: false, affinity_start_date: 3.days.ago)
        end
        let!(:ca3) do
          create(:legacy_cavc_appeal,
                 judge: aff_judge, attorney: attorney, aod: true, tied_to: false, appeal_affinity: false)
        end
        # hearing held with previous decision where judge is not the same
        let!(:ca4) do
          ca4 = create(:legacy_cavc_appeal, judge: other_judge, attorney: attorney, aod: true)
          ca4.update!(bfmemid: aff_judge.sattyid)
          ca4
        end
        let!(:ca5) do
          ca5 = create(:legacy_cavc_appeal,
                       judge: other_judge, attorney: attorney, aod: true, affinity_start_date: 3.days.ago)
          ca5.update!(bfmemid: aff_judge.sattyid)
          ca5
        end
        let!(:ca6) do
          ca6 = create(:legacy_cavc_appeal, judge: other_judge, attorney: attorney, aod: true, appeal_affinity: false)
          ca6.update!(bfmemid: aff_judge.sattyid)
          ca6
        end
        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        let!(:ca7) { create(:legacy_cavc_appeal, judge: tied_judge, attorney: attorney, aod: true) }
        let!(:ca8) do
          create(:legacy_cavc_appeal,
                 judge: tied_judge, attorney: attorney, aod: true, affinity_start_date: 3.days.ago)
        end
        let!(:ca9) do
          create(:legacy_cavc_appeal, judge: tied_judge, attorney: attorney, aod: true, appeal_affinity: false)
        end
        # hearing held but no previous deciding judge where hearing judge is active
        let!(:ca10) do
          ca10 = create(:legacy_cavc_appeal, judge: tied_judge, attorney: attorney, aod: true)
          ca10.update!(bfmemid: nil)
          ca10
        end
        # no hearing held, no previous deciding judge
        let!(:ca11) do
          ca11 = create(:legacy_cavc_appeal, judge: aff_judge, attorney: attorney, aod: true, tied_to: false)
          ca11.update!(bfmemid: nil)
          ca11
        end
        # excluded judge cases:
        # no hearing held but has previous decision
        let!(:ca12) { create(:legacy_cavc_appeal, judge: excl_judge, attorney: attorney, aod: true, tied_to: false) }
        let!(:ca13) do
          create(:legacy_cavc_appeal,
                 judge: excl_judge, attorney: attorney, aod: true, tied_to: false, affinity_start_date: 3.days.ago)
        end
        let!(:ca14) do
          create(:legacy_cavc_appeal,
                 judge: excl_judge, attorney: attorney, aod: true, tied_to: false, appeal_affinity: false)
        end
        # hearing held with previous decision where judge is not the same
        let!(:ca15) do
          ca15 = create(:legacy_cavc_appeal, judge: other_judge, attorney: attorney, aod: true)
          ca15.update!(bfmemid: excl_judge.sattyid)
          ca15
        end
        let!(:ca16) do
          ca16 = create(:legacy_cavc_appeal,
                        judge: other_judge, attorney: attorney, aod: true, affinity_start_date: 3.days.ago)
          ca16.update!(bfmemid: excl_judge.sattyid)
          ca16
        end
        let!(:ca17) do
          ca17 = create(:legacy_cavc_appeal, judge: other_judge, attorney: attorney, aod: true, appeal_affinity: false)
          ca17.update!(bfmemid: excl_judge.sattyid)
          ca17
        end
        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        let!(:ca18) { create(:legacy_cavc_appeal, judge: excl_judge, attorney: attorney, aod: true) }
        let!(:ca19) do
          create(:legacy_cavc_appeal,
                 judge: excl_judge, attorney: attorney, aod: true, affinity_start_date: 3.days.ago)
        end
        let!(:ca20) do
          create(:legacy_cavc_appeal, judge: excl_judge, attorney: attorney, aod: true, appeal_affinity: false)
        end
        # ineligible judge cases:
        # no hearing held but has previous decision
        let!(:ca21) { create(:legacy_cavc_appeal, judge: inel_judge, attorney: attorney, aod: true, tied_to: false) }
        let!(:ca22) do
          create(:legacy_cavc_appeal,
                 judge: inel_judge, attorney: attorney, aod: true, tied_to: false, affinity_start_date: 3.days.ago)
        end
        let!(:ca23) do
          create(:legacy_cavc_appeal,
                 judge: inel_judge, attorney: attorney, aod: true, tied_to: false, appeal_affinity: false)
        end
        # hearing held with previous decision where judge is not the same
        let!(:ca24) do
          ca24 = create(:legacy_cavc_appeal, judge: other_judge, attorney: attorney, aod: true)
          ca24.update!(bfmemid: inel_judge.sattyid)
          ca24
        end
        let!(:ca25) do
          ca25 = create(:legacy_cavc_appeal,
                        judge: other_judge, attorney: attorney, aod: true, affinity_start_date: 3.days.ago)
          ca25.update!(bfmemid: inel_judge.sattyid)
          ca25
        end
        let!(:ca26) do
          ca26 = create(:legacy_cavc_appeal, judge: other_judge, attorney: attorney, aod: true, appeal_affinity: false)
          ca26.update!(bfmemid: inel_judge.sattyid)
          ca26
        end
        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        let!(:ca27) { create(:legacy_cavc_appeal, judge: inel_judge, attorney: attorney, aod: true) }
        let!(:ca28) do
          create(:legacy_cavc_appeal,
                 judge: inel_judge, attorney: attorney, aod: true, affinity_start_date: 3.days.ago)
        end
        let!(:ca29) do
          create(:legacy_cavc_appeal, judge: inel_judge, attorney: attorney, aod: true, appeal_affinity: false)
        end
        # hearing held but no previous deciding judge where hearing judge is ineligible
        let!(:ca30) do
          ca30 = create(:legacy_cavc_appeal, judge: inel_judge, attorney: attorney, aod: true)
          ca30.update!(bfmemid: nil)
          ca30
        end
        # hearing held with previous decision where judge is not the same but hearing judge is ineligible
        let!(:ca31) do
          ca31 = create(:legacy_cavc_appeal, judge: inel_judge, attorney: attorney, aod: true)
          ca31.update!(bfmemid: other_judge.sattyid)
          ca31
        end
        let!(:ca32) do
          ca32 = create(:legacy_cavc_appeal, judge: inel_judge, attorney: attorney, aod: true,
                                             affinity_start_date: 3.days.ago)
          ca32.update!(bfmemid: other_judge.sattyid)
          ca32
        end
        let!(:ca33) do
          ca33 = create(:legacy_cavc_appeal, judge: inel_judge, attorney: attorney, aod: true, appeal_affinity: false)
          ca33.update!(bfmemid: other_judge.sattyid)
          ca33
        end
        # hearing held by excluded judge with no previous decision (tied to excl judge)
        let!(:ca34) do
          ca34 = create(:legacy_cavc_appeal, judge: excl_judge, attorney: attorney, aod: true)
          ca34.update!(bfmemid: nil)
          ca34
        end

        it "distributes CAVC AOD cases correctly based on lever value", :aggregate_failures do
          cavc_aod_lever = CaseDistributionLever.find_by_item(Constants.DISTRIBUTION.cavc_aod_affinity_days)

          # {FOR LEVER HAVING A VALUE:}
          cavc_aod_lever.update!(value: 14)
          CaseDistributionLever.clear_distribution_lever_cache
          expect(VACOLS::CaseDocket.distribute_priority_appeals(judge, "any", 100, true).map { |c| c["bfkey"] }.sort)
            .to match_array([
              ca1, ca4, ca11, ca12, ca13, ca14, ca15, ca16, ca17, ca21, ca22, ca23, ca24, ca25,
              ca26, ca27, ca28, ca29, ca30, ca31
            ]
              .map { |c| (c["bfkey"].to_i + 1).to_s }.sort)
          # {FOR LEVER BEING INFINITE:}
          cavc_aod_lever.update!(value: "infinite")
          CaseDistributionLever.clear_distribution_lever_cache
          expect(VACOLS::CaseDocket.distribute_priority_appeals(judge, "any", 100, true).map { |c| c["bfkey"] }.sort)
            .to match_array([
              ca11, ca12, ca13, ca14, ca15, ca16, ca17, ca21, ca22, ca23, ca24,
              ca25, ca26, ca27, ca28, ca29, ca30
            ]
              .map { |c| (c["bfkey"].to_i + 1).to_s }.sort)

          # ensure that excluded judge recieves their tied cases which would not go to default judge
          expect(VACOLS::CaseDocket.distribute_priority_appeals(excl_judge_caseflow, "any", 100, true)
              .map { |c| c["bfkey"] }.sort)
            .to match_array([
              ca11, ca12, ca13, ca14, ca15, ca16, ca17, ca18, ca19, ca20, ca21, ca22, ca23, ca24,
              ca25, ca26, ca27, ca28, ca29, ca30, ca34
            ]
              .map { |c| (c["bfkey"].to_i + 1).to_s }.sort)

          # {FOR LEVER BEING OMIT:}
          cavc_aod_lever.update!(value: "omit")
          CaseDistributionLever.clear_distribution_lever_cache
          expect(VACOLS::CaseDocket.distribute_priority_appeals(judge, "any", 100, true).map { |c| c["bfkey"] }.sort)
            .to match_array([
              ca1, ca2, ca3, ca4, ca5, ca6, ca11, ca12, ca13, ca14, ca15, ca16, ca17, ca21, ca22,
              ca23, ca24, ca25, ca26, ca27, ca28, ca29, ca30, ca31, ca32, ca33
            ]
              .map { |c| (c["bfkey"].to_i + 1).to_s }.sort)
        end
      end

      context "for cases where a hearing has been held after the original decision date" do
        let(:new_hearing_judge) { create(:user, :judge, :with_vacols_judge_record) }

        # original hearing held by tied_judge, decided by tied_judge, new hearing held by new_hearing_judge
        let!(:case_1) do
          c = create(:legacy_cavc_appeal, judge: tied_judge, attorney: attorney, tied_to: true)
          create_case_hearing(c, new_hearing_judge)
          c
        end
        # original hearing held by tied_judge, decided by other_judge, new hearing held by new_hearing_judge
        let!(:case_2) do
          c = create(:legacy_cavc_appeal, judge: tied_judge, attorney: attorney, tied_to: true)
          c.update!(bfmemid: other_judge.sattyid)
          create_case_hearing(c, new_hearing_judge)
          c
        end
        # no original hearing, decided by other_judge, new hearing held by new_hearing_judge
        let!(:case_3) do
          c = create(:legacy_cavc_appeal, judge: other_judge, attorney: attorney, tied_to: false)
          create_case_hearing(c, new_hearing_judge)
          c
        end
        # original hearing held by tied_judge, no original deciding judge, new hearing held by new_hearing_judge
        let!(:case_4) do
          c = create(:legacy_cavc_appeal, judge: tied_judge, attorney: attorney, tied_to: true)
          c.update!(bfmemid: nil)
          create_case_hearing(c, new_hearing_judge)
          c
        end
        # no original hearing, no original deciding judge, new hearing held by new_hearing_judge
        let!(:case_5) do
          c = create(:legacy_cavc_appeal, judge: tied_judge, attorney: attorney, tied_to: false)
          c.update!(bfmemid: nil)
          create_case_hearing(c, new_hearing_judge)
          c
        end
        # original hearing held by tied_judge, decided by tied_judge, no new hearing
        let!(:case_6) { create(:legacy_cavc_appeal, judge: tied_judge, attorney: attorney, tied_to: true) }
        # original hearing held by tied_judge, decided by other_judge, no new hearing
        let!(:case_7) do
          c = create(:legacy_cavc_appeal, judge: tied_judge,
                                          attorney: attorney, tied_to: true, affinity_start_date: 3.days.ago)
          c.update!(bfmemid: other_judge.sattyid)
          c
        end
        # no original hearing, decided by other_judge, no new hearing
        let!(:case_8) do
          create(:legacy_cavc_appeal, judge: other_judge, attorney: attorney, tied_to: false,
                                      affinity_start_date: 3.days.ago)
        end
        # original hearing held by tied_judge, no original deciding judge, no new hearing
        let!(:case_9) do
          c = create(:legacy_cavc_appeal, judge: tied_judge, attorney: attorney, tied_to: true)
          c.update!(bfmemid: nil)
          c
        end
        # no original hearing, no original deciding judge, no new hearing
        let!(:case_10) do
          c = create(:legacy_cavc_appeal, judge: tied_judge, attorney: attorney, tied_to: false)
          c.update!(bfmemid: nil)
          c
        end
        # original hearing held by tied_judge, decided by tied_judge, new hearing held by inel_judge
        # this should have affinity to the original deciding judge because new hearing judge is ineligible
        let!(:case_11) do
          c = create(:legacy_cavc_appeal,
                     judge: tied_judge, attorney: attorney, tied_to: true, affinity_start_date: Time.zone.now)
          create_case_hearing(c, inel_judge_caseflow)
          c
        end
        # original hearing held by inel_judge, decided by inel_judge, no new hearing
        let!(:case_12) { create(:legacy_cavc_appeal, judge: inel_judge, attorney: attorney, tied_to: true) }
        # original hearing held by tied_judge, decided by tied_judge, new hearing held by inel_judge
        # this would have affinity to the original deciding judge but is out of affinity window
        let!(:case_13) do
          c = create(:legacy_cavc_appeal, judge: tied_judge, attorney: attorney, tied_to: true)
          create_case_hearing(c, inel_judge_caseflow)
          c
        end

        it "cases are tied to the judge who held a hearing after the previous case was decided", :aggregate_failures do
          # For case distribution levers set to a value
          CaseDistributionLever.clear_distribution_lever_cache
          new_hearing_judge_cases = VACOLS::CaseDocket.distribute_priority_appeals(new_hearing_judge, "any", 100, true)
          tied_judge_cases = VACOLS::CaseDocket.distribute_priority_appeals(tied_judge_caseflow, "any", 100, true)
          other_judge_cases = VACOLS::CaseDocket.distribute_priority_appeals(other_judge_caseflow, "any", 100, true)

          expect(new_hearing_judge_cases.map { |c| c["bfkey"] }.sort)
            .to match_array([
              case_1, case_2, case_3, case_4, case_5, case_10, case_12, case_13
            ].map { |c| (c["bfkey"].to_i + 1).to_s }.sort)

          expect(tied_judge_cases.map { |c| c["bfkey"] }.sort)
            .to match_array([
              case_6, case_9, case_10, case_11, case_12, case_13
            ].map { |c| (c["bfkey"].to_i + 1).to_s }.sort)

          expect(other_judge_cases.map { |c| c["bfkey"] }.sort)
            .to match_array([
              case_7, case_8, case_10, case_12, case_13
            ].map { |c| (c["bfkey"].to_i + 1).to_s }.sort)

          # For case distribution levers set to infinite
          CaseDistributionLever.find_by(item: "cavc_affinity_days").update!(value: "infinite")
          CaseDistributionLever.find_by(item: "cavc_aod_affinity_days").update!(value: "infinite")
          CaseDistributionLever.clear_distribution_lever_cache

          new_hrng_judge_infinite = VACOLS::CaseDocket.distribute_priority_appeals(new_hearing_judge, "any", 100, true)
          tied_judge_infinite = VACOLS::CaseDocket.distribute_priority_appeals(tied_judge_caseflow, "any", 100, true)
          other_judge_infinite = VACOLS::CaseDocket.distribute_priority_appeals(other_judge_caseflow, "any", 100, true)

          expect(new_hrng_judge_infinite.map { |c| c["bfkey"] }.sort)
            .to match_array([
              case_1, case_2, case_3, case_4, case_5, case_10, case_12
            ].map { |c| (c["bfkey"].to_i + 1).to_s }.sort)

          expect(tied_judge_infinite.map { |c| c["bfkey"] }.sort)
            .to match_array([
              case_6, case_9, case_10, case_11, case_12, case_13
            ].map { |c| (c["bfkey"].to_i + 1).to_s }.sort)

          expect(other_judge_infinite.map { |c| c["bfkey"] }.sort)
            .to match_array([
              case_7, case_8, case_10, case_12
            ].map { |c| (c["bfkey"].to_i + 1).to_s }.sort)

          # For case distribution levers set to omit
          CaseDistributionLever.find_by(item: "cavc_affinity_days").update!(value: "omit")
          CaseDistributionLever.find_by(item: "cavc_aod_affinity_days").update!(value: "omit")
          CaseDistributionLever.clear_distribution_lever_cache

          new_hearing_judge_omit = VACOLS::CaseDocket.distribute_priority_appeals(new_hearing_judge, "any", 100, true)
          tied_judge_omit = VACOLS::CaseDocket.distribute_priority_appeals(tied_judge_caseflow, "any", 100, true)
          other_judge_omit = VACOLS::CaseDocket.distribute_priority_appeals(other_judge_caseflow, "any", 100, true)

          expect(new_hearing_judge_omit.map { |c| c["bfkey"] }.sort)
            .to match_array([
              case_1, case_2, case_3, case_4, case_5, case_7, case_8, case_10, case_11, case_12, case_13
            ].map { |c| (c["bfkey"].to_i + 1).to_s }.sort)

          expect(tied_judge_omit.map { |c| c["bfkey"] }.sort)
            .to match_array([
              case_6, case_7, case_8, case_9, case_10, case_11, case_12, case_13
            ].map { |c| (c["bfkey"].to_i + 1).to_s }.sort)

          expect(other_judge_omit.map { |c| c["bfkey"] }.sort)
            .to match_array([
              case_7, case_8, case_10, case_11, case_12, case_13
            ].map { |c| (c["bfkey"].to_i + 1).to_s }.sort)
        end
      end

      context "when the genpop value is 'not_genpop'" do
        # appeals with no hearing and no previous deciding judge (genpop)
        let!(:aod_case_1) { create(:case, :aod, :type_original, :ready_for_distribution) }
        let!(:cavc_case_1) do
          c = create(:legacy_cavc_appeal, judge: aff_judge, attorney: attorney, tied_to: false)
          c.update!(bfmemid: nil)
          c
        end
        let!(:aod_cavc_case_1) do
          c = create(:legacy_cavc_appeal, judge: aff_judge, attorney: attorney, aod: true, tied_to: false)
          c.update!(bfmemid: nil)
          c
        end
        # appeals where hearing held by original deciding judge (not genpop)
        let!(:aod_case_2) do
          create(:case, :aod, :type_original, :tied_to_judge, :ready_for_distribution, tied_judge: judge)
        end
        let!(:cavc_case_2) { create(:legacy_cavc_appeal, judge: vacols_judge, attorney: attorney) }
        let!(:aod_cavc_case_2) { create(:legacy_cavc_appeal, judge: other_judge, attorney: attorney, aod: true) }
        # appeals where hearing held by different judge than original deciding judge
        # before the decision and within affinity window (not genpop)
        let!(:cavc_case_3) do
          c = create(:legacy_cavc_appeal, judge: other_judge, attorney: attorney, affinity_start_date: 3.days.ago)
          c.update!(bfmemid: aff_judge.sattyid)
          c
        end
        let!(:aod_cavc_case_3) do
          c = create(:legacy_cavc_appeal,
                     judge: other_judge, attorney: attorney, aod: true, affinity_start_date: 3.days.ago)
          c.update!(bfmemid: vacols_judge.sattyid)
          c
        end
        # appeals where hearing held by judge after original decision w/ different original judge (not genpop)
        let!(:cavc_case_4) do
          c = create(:legacy_cavc_appeal, judge: tied_judge, attorney: attorney, tied_to: true)
          create_case_hearing(c, other_judge_caseflow)
          c
        end
        let!(:aod_cavc_case_4) do
          c = create(:legacy_cavc_appeal, judge: tied_judge, attorney: attorney, tied_to: true, aod: true)
          create_case_hearing(c, judge)
          c
        end
        # appeals where prev deciding judge ineligible and hearing before decision (genpop)
        let!(:cavc_case_5) { create(:legacy_cavc_appeal, judge: inel_judge, attorney: attorney) }
        let!(:aod_cavc_case_5) { create(:legacy_cavc_appeal, judge: inel_judge, attorney: attorney, aod: true) }
        # appeals where prev deciding judge excluded and is not the hearing vlj and hearing before decision (genpop)
        let!(:cavc_case_6) do
          c = create(:legacy_cavc_appeal, judge: other_judge, attorney: attorney)
          c.update!(bfmemid: excl_judge.sattyid)
          c
        end
        let!(:aod_cavc_case_6) do
          c = create(:legacy_cavc_appeal, judge: other_judge, attorney: attorney, aod: true)
          c.update!(bfmemid: excl_judge.sattyid)
          c
        end
        # appeals w/ no held hearings, active prev deciding judge,
        # affinity start date and value < lever days ago (not genpop for other judge)
        let!(:cavc_case_7) do
          create(:legacy_cavc_appeal,
                 judge: other_judge, attorney: attorney, tied_to: false, affinity_start_date: 3.days.ago)
        end
        let!(:aod_cavc_case_7) do
          create(:legacy_cavc_appeal,
                 judge: other_judge, attorney: attorney, tied_to: false, aod: true, affinity_start_date: 3.days.ago)
        end
        # appeals w/ no held hearings, active prev deciding judge,
        # affinity start date and value < lever days ago (not genpop for requesting judge unless omit)
        let!(:cavc_case_8) do
          create(:legacy_cavc_appeal,
                 judge: vacols_judge, attorney: attorney, tied_to: false, affinity_start_date: 3.days.ago)
        end
        let!(:aod_cavc_case_8) do
          create(:legacy_cavc_appeal,
                 judge: vacols_judge, attorney: attorney, tied_to: false, aod: true, affinity_start_date: 3.days.ago)
        end
        # appeals w/ no held hearings, active prev deciding judge,
        # affinity start date and value > lever days ago (genpop unless lever infinite)
        let!(:cavc_case_9) do
          create(:legacy_cavc_appeal,
                 judge: vacols_judge, attorney: attorney, tied_to: false, affinity_start_date: 2.months.ago)
        end
        let!(:aod_cavc_case_9) do
          create(:legacy_cavc_appeal,
                 judge: vacols_judge, attorney: attorney, tied_to: false, aod: true, affinity_start_date: 2.months.ago)
        end

        it "only distributes non-genpop appeals", :aggregate_failures do
          # with levers set to a value
          CaseDistributionLever.clear_distribution_lever_cache

          judge_cases =
            VACOLS::CaseDocket.distribute_priority_appeals(judge, "not_genpop", 100, true)

          expect(judge_cases.map { |c| c["bfkey"] }.sort)
            .to match_array([
              cavc_case_2, aod_cavc_case_3, aod_cavc_case_4, cavc_case_8, aod_cavc_case_8
            ].map { |c| (c["bfkey"].to_i + 1).to_s }.push(aod_case_2.bfkey).sort)

          # For case distribution levers set to infinite
          CaseDistributionLever.find_by(item: "cavc_affinity_days").update!(value: "infinite")
          CaseDistributionLever.find_by(item: "cavc_aod_affinity_days").update!(value: "infinite")
          CaseDistributionLever.clear_distribution_lever_cache

          judge_cases =
            VACOLS::CaseDocket.distribute_priority_appeals(judge, "not_genpop", 100, true)

          expect(judge_cases.map { |c| c["bfkey"] }.sort)
            .to match_array([
              cavc_case_2, aod_cavc_case_3, aod_cavc_case_4, cavc_case_8, aod_cavc_case_8, cavc_case_9, aod_cavc_case_9
            ].map { |c| (c["bfkey"].to_i + 1).to_s }.push(aod_case_2.bfkey).sort)

          # For case distribution levers set to omit
          CaseDistributionLever.find_by(item: "cavc_affinity_days").update!(value: "omit")
          CaseDistributionLever.find_by(item: "cavc_aod_affinity_days").update!(value: "omit")
          CaseDistributionLever.clear_distribution_lever_cache

          judge_cases =
            VACOLS::CaseDocket.distribute_priority_appeals(judge, "not_genpop", 100, true)

          expect(judge_cases.map { |c| c["bfkey"] }.sort)
            .to match_array([
              cavc_case_2, aod_cavc_case_4
            ].map { |c| (c["bfkey"].to_i + 1).to_s }.push(aod_case_2.bfkey).sort)
        end
      end
    end
  end

  context "legacy_das_deprecation FeatureToggle enabled" do
    before do
      FeatureToggle.enable!(:legacy_das_deprecation)
    end

    after do
      FeatureToggle.disable!(:legacy_das_deprecation)
    end

    it "sets the case location to 'CASEFLOW'" do
      VACOLS::CaseDocket.distribute_nonpriority_appeals(judge, "any", nil, 2, false)
      expect(nonpriority_ready_case.reload.bfcurloc).to eq(LegacyAppeal::LOCATION_CODES[:caseflow])
    end
  end

  context "removal of BFHINES check" do
    let(:genpop) { "any" }
    let(:limit) { 10 }
    let(:original_docket_number) { aod_ready_case_docket_number }
    let!(:hearing) do
      create(:case_hearing,
             :disposition_held,
             folder_nr: original.bfkey,
             hearing_date: 5.days.ago.to_date,
             board_member: judge.vacols_attorney_id)
    end

    subject { VACOLS::CaseDocket.distribute_priority_appeals(judge, genpop, limit) }

    context "when BFHINES is nil" do
      before do
        aod_ready_case.update(bfhines: nil)
      end

      it "distributes the case with passed in judge" do
        subject
        expect(aod_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
      end
    end

    context "when BFHINES is GP" do
      before do
        aod_ready_case.update(bfhines: "GP")
      end

      it "distributes the case with passed in judge" do
        subject
        expect(aod_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
      end
    end

    context "when BFHINES is a value other than GP" do
      before do
        aod_ready_case.update(bfhines: "42")
      end

      it "distributes the case with passed in judge" do
        subject
        expect(aod_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
      end
    end
  end

  def create_case_hearing(original_case, hearing_judge)
    create(:case_hearing, :disposition_held, folder_nr: (original_case.bfkey.to_i + 1).to_s,
                                             hearing_date: Time.zone.today, user: hearing_judge)
  end
end
