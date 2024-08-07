# frozen_string_literal: true

describe VACOLS::AojCaseDocket, :all_dbs do
  before do
    FeatureToggle.enable!(:test_facols)
    FeatureToggle.enable!(:acd_disable_legacy_lock_ready_appeals)
    FeatureToggle.enable!(:acd_distribute_by_docket_date)
    FeatureToggle.enable!(:acd_cases_tied_to_judges_no_longer_with_board)
    FeatureToggle.enable!(:acd_exclude_from_affinity)
    create(:case_distribution_lever, :cavc_affinity_days)
    create(:case_distribution_lever, :cavc_aod_affinity_days)
    create(:case_distribution_lever, :aoj_aod_affinity_days)
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

  let(:nonpriority_ready_case_bfbox) { nil }
  let(:nonpriority_ready_case_docket_number) { "1801001" }
  let!(:nonpriority_ready_case) do
    create(:case,
           bfd19: 1.year.ago,
           bfac: "3",
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
           bfac: "3",
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
      bfac: "3",
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
           bfac: "3",
           bfmpro: "ACT",
           bfcurloc: "83",
           bfdloout: 1.day.ago,
           folder: build(:folder, tinum: third_nonpriority_ready_case_docket_number, titrnum: "123456789S"))
  end
  let(:inactive_original_judge) { inactive_judge.vacols_attorney_id }
  let(:inactive_original_case) do
    create(:case,
           bfd19: 1.year.ago,
           bfac: "3",
           bfmpro: "HIS",
           bfcurloc: "99",
           bfattid: "111",
           bfmemid: inactive_original_judge,
           folder: build(:folder, tinum: third_nonpriority_ready_case_docket_number, titrnum: "123456789S"))
  end

  let!(:nonpriority_unready_case) do
    create(:case,
           bfd19: 1.year.ago,
           bfac: "3",
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

  # {Priority Ready}
  let(:postcavc_ready_case_docket_number) { "1801004" }
  let!(:postcavc_ready_case) do
    create(:case,
           :aod,
           bfd19: 11.months.ago,
           bfac: "3",
           bfmpro: "ACT",
           bfcurloc: "83",
           bfdloout: 2.days.ago,
           folder: build(:folder, tinum: postcavc_ready_case_docket_number, titrnum: "123456789S"))
  end

  # {Priority Unready}
  let!(:aod_case_unready_due_to_location) do
    create(:case,
           :aod,
           bfd19: 1.year.ago,
           bfac: "3",
           bfmpro: "ACT",
           bfcurloc: "55")
  end

  # {Priority Unready}
  let!(:aod_case_unready_due_to_blocking_mail) do
    create(:case,
           :aod,
           bfd19: 1.year.ago,
           bfac: "3",
           bfmpro: "ACT",
           bfcurloc: "81").tap { |vacols_case| create(:mail, :blocking, :incomplete, mlfolder: vacols_case.bfkey) }
  end

  context ".counts_by_priority_and_readiness" do
    subject { VACOLS::AojCaseDocket.counts_by_priority_and_readiness }
    it "creates counts grouped by priority and readiness" do
      expect(subject).to match_array([
                                       { "n" => 2, "priority" => 1, "ready" => 0 },
                                       { "n" => 2, "priority" => 1, "ready" => 1 },
                                       { "n" => 1, "priority" => 0, "ready" => 0 },
                                       { "n" => 2, "priority" => 0, "ready" => 1 }
                                     ])
    end
  end

  context ".age_of_oldest_priority_appeal" do
    subject { VACOLS::AojCaseDocket.age_of_oldest_priority_appeal }

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

  context ".nonpriority_hearing_cases_for_judge_count" do
    subject { VACOLS::AojCaseDocket.nonpriority_hearing_cases_for_judge_count(judge) }

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

    subject { VACOLS::AojCaseDocket.distribute_nonpriority_appeals(judge, genpop, range, limit, bust_backlog) }

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
            allow(VACOLS::AojCaseDocket).to receive(:nonpriority_hearing_cases_for_judge_count).with(judge)
              .and_return(VACOLS::AojCaseDocket::HEARING_BACKLOG_LIMIT + number_of_cases_over_backlog)
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

    subject { VACOLS::AojCaseDocket.distribute_priority_appeals(judge, genpop, limit) }

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
          expect(subject.count).to eq(1)
          expect(aod_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
          expect(postcavc_ready_case.reload.bfcurloc).to eq("83")
        end
      end
    end

    context "when an aod case is tied to the same judge as last decided the case" do
      let(:original_docket_number) { aod_ready_case_docket_number }
      let(:genpop) { "not_genpop" }

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

  context "legacy_das_deprecation FeatureToggle enabled" do
    before do
      FeatureToggle.enable!(:legacy_das_deprecation)
    end

    after do
      FeatureToggle.disable!(:legacy_das_deprecation)
    end

    it "sets the case location to 'CASEFLOW'" do
      VACOLS::AojCaseDocket.distribute_nonpriority_appeals(judge, "any", nil, 2, false)
      expect(nonpriority_ready_case.reload.bfcurloc).to eq(LegacyAppeal::LOCATION_CODES[:caseflow])
    end
  end

  # rubocop:disable Layout/LineLength
  context "when CaseDistributionLever" do
    before do
      VACOLS::Case.where(bfcurloc: %w[81 83]).map { |c| c.update!(bfcurloc: "testing") }
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

    context ".aoj_aod_affinity_days lever is active" do
      # aoj aod affinity cases:
      # no hearing held but has previous decision
      let!(:ca1) { create(:legacy_aoj_appeal, :aod, judge: aff_judge, attorney: attorney, tied_to: false) }
      let!(:ca2) { create(:legacy_aoj_appeal, :aod, judge: aff_judge, attorney: attorney, tied_to: false, affinity_start_date: 3.days.ago) }
      let!(:ca3) { create(:legacy_aoj_appeal, :aod, judge: aff_judge, attorney: attorney, tied_to: false, appeal_affinity: false) }
      # hearing held with previous decision where judge is not the same
      let!(:ca4) do
        ca4 = create(:legacy_aoj_appeal, :aod, judge: other_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: ca4.bfcorlid, bfkey: (ca4.bfkey.to_i + 1).to_s).update(bfmemid: aff_judge.sattyid)
        ca4
      end
      let!(:ca5) do
        ca5 = create(:legacy_aoj_appeal, :aod, judge: other_judge, attorney: attorney, affinity_start_date: 3.days.ago)
        VACOLS::Case.where(bfcorlid: ca5.bfcorlid, bfkey: (ca5.bfkey.to_i + 1).to_s).update(bfmemid: aff_judge.sattyid)
        ca5
      end
      let!(:ca6) do
        ca6 = create(:legacy_aoj_appeal, :aod, judge: other_judge, attorney: attorney, appeal_affinity: false)
        VACOLS::Case.where(bfcorlid: ca6.bfcorlid, bfkey: (ca6.bfkey.to_i + 1).to_s).update(bfmemid: aff_judge.sattyid)
        ca6
      end
      # hearing held with previous decision where judge is same (THIS IS TIED TO)
      let!(:ca7) { create(:legacy_aoj_appeal, :aod, judge: tied_judge, attorney: attorney) }
      let!(:ca8) { create(:legacy_aoj_appeal, :aod, judge: tied_judge, attorney: attorney, affinity_start_date: 3.days.ago) }
      let!(:ca9) { create(:legacy_aoj_appeal, :aod, judge: tied_judge, attorney: attorney, appeal_affinity: false) }
      # hearing held but no previous deciding judge
      let!(:ca10) do
        ca10 = create(:legacy_aoj_appeal, :aod, judge: tied_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: ca10.bfcorlid, bfkey: (ca10.bfkey.to_i + 1).to_s).update(bfmemid: nil)
        ca10
      end
      # no hearing held, no previous deciding judge
      let!(:ca11) do
        ca11 = create(:legacy_aoj_appeal, :aod, judge: aff_judge, attorney: attorney, tied_to: false)
        VACOLS::Case.where(bfcorlid: ca11.bfcorlid, bfkey: (ca11.bfkey.to_i + 1).to_s).update(bfmemid: nil)
        ca11
      end
      # excluded judge cases:
      # no hearing held but has previous decision
      let!(:ca12) { create(:legacy_aoj_appeal, :aod, judge: excl_judge, attorney: attorney, tied_to: false) }
      let!(:ca13) { create(:legacy_aoj_appeal, :aod, judge: excl_judge, attorney: attorney, tied_to: false, affinity_start_date: 3.days.ago) }
      let!(:ca14) { create(:legacy_aoj_appeal, :aod, judge: excl_judge, attorney: attorney, tied_to: false, appeal_affinity: false) }
      # hearing held with previous decision where judge is not the same
      let!(:ca15) do
        ca15 = create(:legacy_aoj_appeal, :aod, judge: other_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: ca15.bfcorlid, bfkey: (ca15.bfkey.to_i + 1).to_s).update(bfmemid: excl_judge.sattyid)
        ca15
      end
      let!(:ca16) do
        ca16 = create(:legacy_aoj_appeal, :aod, judge: other_judge, attorney: attorney, affinity_start_date: 3.days.ago)
        VACOLS::Case.where(bfcorlid: ca16.bfcorlid, bfkey: (ca16.bfkey.to_i + 1).to_s).update(bfmemid: excl_judge.sattyid)
        ca16
      end
      let!(:ca17) do
        ca17 = create(:legacy_aoj_appeal, :aod, judge: other_judge, attorney: attorney, appeal_affinity: false)
        VACOLS::Case.where(bfcorlid: ca17.bfcorlid, bfkey: (ca17.bfkey.to_i + 1).to_s).update(bfmemid: excl_judge.sattyid)
        ca17
      end
      # hearing held with previous decision where judge is same (THIS IS TIED TO)
      let!(:ca18) { create(:legacy_aoj_appeal, :aod, judge: excl_judge, attorney: attorney) }
      let!(:ca19) { create(:legacy_aoj_appeal, :aod, judge: excl_judge, attorney: attorney, affinity_start_date: 3.days.ago) }
      let!(:ca20) { create(:legacy_aoj_appeal, :aod, judge: excl_judge, attorney: attorney, appeal_affinity: false) }
      # ineligible judge cases:
      # no hearing held but has previous decision
      let!(:ca21) { create(:legacy_aoj_appeal, :aod, judge: inel_judge, attorney: attorney, tied_to: false) }
      let!(:ca22) { create(:legacy_aoj_appeal, :aod, judge: inel_judge, attorney: attorney, tied_to: false, affinity_start_date: 3.days.ago) }
      let!(:ca23) { create(:legacy_aoj_appeal, :aod, judge: inel_judge, attorney: attorney, tied_to: false, appeal_affinity: false) }
      # hearing held with previous decision where judge is not the same
      let!(:ca24) do
        ca24 = create(:legacy_aoj_appeal, :aod, judge: other_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: ca24.bfcorlid, bfkey: (ca24.bfkey.to_i + 1).to_s).update(bfmemid: inel_judge.sattyid)
        ca24
      end
      let!(:ca25) do
        ca25 = create(:legacy_aoj_appeal, :aod, judge: other_judge, attorney: attorney, affinity_start_date: 3.days.ago)
        VACOLS::Case.where(bfcorlid: ca25.bfcorlid, bfkey: (ca25.bfkey.to_i + 1).to_s).update(bfmemid: inel_judge.sattyid)
        ca25
      end
      let!(:ca26) do
        ca26 = create(:legacy_aoj_appeal, :aod, judge: other_judge, attorney: attorney, appeal_affinity: false)
        VACOLS::Case.where(bfcorlid: ca26.bfcorlid, bfkey: (ca26.bfkey.to_i + 1).to_s).update(bfmemid: inel_judge.sattyid)
        ca26
      end
      # hearing held with previous decision where judge is same (THIS IS TIED TO)
      let!(:ca27) { create(:legacy_aoj_appeal, :aod, judge: inel_judge, attorney: attorney) }
      let!(:ca28) { create(:legacy_aoj_appeal, :aod, judge: inel_judge, attorney: attorney, affinity_start_date: 3.days.ago) }
      let!(:ca29) { create(:legacy_aoj_appeal, :aod, judge: inel_judge, attorney: attorney, appeal_affinity: false) }
      # hearing held but no previous deciding judge
      let!(:ca30) do
        ca30 = create(:legacy_aoj_appeal, :aod, judge: inel_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: ca30.bfcorlid, bfkey: (ca30.bfkey.to_i + 1).to_s).update(bfmemid: nil)
        ca30
      end

      it "distributes AOJ AOD cases correctly based on lever value", :aggregate_failures do
        IneligibleJudgesJob.new.perform_now
        aoj_aod_lever = CaseDistributionLever.find_by_item(Constants.DISTRIBUTION.aoj_aod_affinity_days)

        # {FOR LEVER HAVING A VALUE:}
        aoj_aod_lever.update!(value: 14)
        expect(VACOLS::AojCaseDocket.distribute_priority_appeals(judge, "any", 100, true).map { |c| c["bfkey"] }.sort)
          .to match_array([
            ca1, ca4, ca10, ca11, ca12, ca13, ca14, ca15, ca16, ca17, ca21, ca22, ca23, ca24, ca25,
            ca26, ca27, ca28, ca29, ca30
          ]
            .map { |c| c["bfkey"].to_i.to_s }.sort)
        # {FOR LEVER BEING INFINITE:}
        aoj_aod_lever.update!(value: "infinite")
        expect(VACOLS::AojCaseDocket.distribute_priority_appeals(judge, "any", 100, true).map { |c| c["bfkey"] }.sort)
          .to match_array([ca11, ca12, ca13, ca14, ca15, ca16, ca17, ca21, ca22, ca23, ca24, ca25, ca26, ca27, ca28, ca29, ca30]
            .map { |c| c["bfkey"].to_i.to_s }.sort)
        # {FOR LEVER BEING OMIT:}
        aoj_aod_lever.update!(value: "omit")
        expect(VACOLS::AojCaseDocket.distribute_priority_appeals(judge, "any", 100, true).map { |c| c["bfkey"] }.sort)
          .to match_array([
            ca1, ca2, ca3, ca4, ca5, ca6, ca10, ca11, ca12, ca13, ca14, ca15, ca16, ca17, ca21, ca22,
            ca23, ca24, ca25, ca26, ca27, ca28, ca29, ca30
          ]
            .map { |c| c["bfkey"].to_i.to_s }.sort)
      end
    end
  end
  # rubocop:enable Layout/LineLength
end
