# frozen_string_literal: true

describe Issue, :all_dbs do
  let(:vacols_id) { "12345678" }
  let(:disposition) { :allowed }
  let(:disposition_date) { Time.zone.today }
  let(:readable_disposition) { "Allowed" }
  let(:codes) { %w[02 15 03 5252] }
  let(:close_date) { 4.days.ago }
  let(:labels) { ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] }

  let(:issue) do
    Generators::Issue.build(id: vacols_id,
                            disposition: disposition,
                            disposition_date: disposition_date,
                            readable_disposition: readable_disposition,
                            codes: codes,
                            close_date: close_date,
                            labels: labels)
  end

  context ".load_from_vacols" do
    subject { Issue.load_from_vacols(issue_hash) }
    let(:issue_hash) do
      # NOTE: This is the exact structure pulled from VACOLS
      # please do not touch this!
      { "isskey" => "12345678",
        "issseq" => 1,
        "issdc" => "3",
        "issdcls" => 3.days.ago,
        "issdesc" => "low back condition",
        "issprog" => "02",
        "isscode" => "15",
        "isslev1" => "03",
        "isslev2" => "5252",
        "isslev3" => nil,
        "issprog_label" => "Compensation",
        "isscode_label" => "Service connection",
        "isslev1_label" => "All Others",
        "isslev2_label" => "Thigh, limitation of flexion of",
        "isslev3_label" => nil }
    end

    it "assigns values properly" do
      expect(subject.codes).to eq(codes)
      expect(subject.labels).to eq(labels)
      expect(subject.note).to eq("low back condition")
      expect(subject.disposition).to eq(:remanded)
      expect(subject.readable_disposition).to eq("Remanded")
      expect(subject.close_date).to eq(AppealRepository.normalize_vacols_date(3.days.ago))
    end

    context "when issues are loaded without label joins" do
      let(:issue_hash) do
        # NOTE: This is the exact structure pulled from VACOLS
        # please do not touch this!
        { "isskey" => "12345678",
          "issseq" => 1,
          "issdc" => "3",
          "issdcls" => 3.days.ago,
          "issdesc" => "low back condition",
          "issprog" => "02",
          "isscode" => "15",
          "isslev1" => "02",
          "isslev2" => "03",
          "isslev3" => "04" }
      end

      it "raise exceptions for unloaded attributes" do
        expect(subject.note).to eq("low back condition")
        expect { subject.labels }.to raise_exception(Caseflow::Error::AttributeNotLoaded)
        expect { subject.description }.to raise_exception(Caseflow::Error::AttributeNotLoaded)
      end
    end
  end

  context "#cavc_decisions" do
    subject { issue.cavc_decisions }

    let(:cavc_decision) do
      CAVCDecision.new(
        appeal_vacols_id: vacols_id,
        issue_vacols_sequence_id: 1,
        decision_date: 1.day.ago,
        disposition: "CAVC Vacated and Remanded"
      )
    end

    before do
      CAVCDecision.repository.cavc_decision_records = [cavc_decision]
    end

    it { is_expected.to eq([cavc_decision]) }
  end

  context "#program" do
    subject { issue.program }

    context "when the program is known" do
      it { is_expected.to eq(:compensation) }
    end

    context "when the program is not known" do
      let(:codes) { %w[99 99] }
      it { is_expected.to be_nil }
    end
  end

  context "#dic" do
    subject { issue.dic }

    context "when the issue is dic" do
      let(:codes) { %w[02 08] }
      it { is_expected.to eq(true) }
    end

    context "when the issue is not dic" do
      it { is_expected.to eq(false) }
    end
  end

  context "#aoj" do
    subject { issue.aoj }

    context "when the aoj is vba, vha, or nca" do
      it { is_expected.to eq(:vba) }
    end

    context "when the issue is not originated from vba, vha, or nca" do
      let(:codes) { %w[10 01 02] }
      it { is_expected.to be_nil }
    end
  end

  context "#type" do
    subject { issue.type }
    it { is_expected.to eq("Service connection") }
  end

  context "#program_description" do
    subject { issue.program_description }
    it { is_expected.to eq("02 - Compensation") }
  end

  context "#description" do
    subject { issue.description }
    it "returns an array for each description line" do
      is_expected.to eq([
                          "15 - Service connection",
                          "03 - All Others",
                          "5252 - Thigh, limitation of flexion of"
                        ])
    end
  end

  context "#levels" do
    subject { issue.levels }
    it { is_expected.to eq(["All Others", "Thigh, limitation of flexion of"]) }

    context "when there are no levels" do
      let(:labels) { ["Building maintenance", "Door won't open"] }
      it { is_expected.to eq([]) }
    end
  end

  context "#levels_with_codes" do
    subject { issue.levels_with_codes }

    it { is_expected.to eq(["03 - All Others", "5252 - Thigh, limitation of flexion of"]) }
  end

  context "#formatted_program_type_levels" do
    subject { issue.formatted_program_type_levels }

    it { is_expected.to eq("Comp: SC\n03 - All Others; 5252 - Thigh, limitation of flexion of") }
  end

  context "#formatted_disposition" do
    subject { issue.formatted_disposition }

    it { is_expected.to eq("Allowed\n" + 4.days.ago.to_formatted_s(:short_date)) }
  end

  context "#friendly_description" do
    subject { issue.friendly_description }

    before do
      @raven_called = false
      allow(Raven).to receive(:capture_message) { @raven_called = true }
    end

    it { is_expected.to eq("Service connection, limitation of thigh motion (flexion)") }

    context "when there is an unknown issue code" do
      let(:codes) { %w[99 99 99] }
      it { is_expected.to be_nil }
    end

    context "when there is an unknown diagnostic code" do
      let(:codes) { %w[02 15 03 1234] }
      it { is_expected.to be_nil }
    end

    context "when there are more levels than codes" do
      let(:codes) { %w[01 01] }
      it {
        is_expected.to eq("")
        expect(@raven_called).to eq(true)
      }
    end
  end

  context "#friendly_description_without_new_material" do
    subject { issue.friendly_description_without_new_material }
    let(:codes) { %w[02 15 04 5252] }
    it { is_expected.to eq("Service connection, limitation of thigh motion (flexion)") }
  end

  context "#diagnostic_code" do
    subject { issue.diagnostic_code }

    context "when the issue codes include a diagnostic code" do
      it { is_expected.to eq("5252") }
    end

    context "when there is not an issue code" do
      let(:codes) { %w[02 18 01 05] }
      it { is_expected.to be_nil }
    end
  end

  context "#category" do
    subject { issue.category }
    it { is_expected.to eq("02-15") }
  end

  context "#active?" do
    let(:disposition) { nil }
    let(:vacols_case) { create(:case, :status_advance, case_issues: [vacols_case_issue], bfkey: vacols_id) }
    let(:vacols_case_issue) { create(:case_issue) }
    let!(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }

    subject { issue.active? }

    context "when it has a disposition" do
      let(:disposition) { :allowed }

      it { is_expected.to be_falsey }
    end

    context "when it does not have a disposition" do
      let(:disposition) { nil }

      it { is_expected.to be_truthy }

      context "when the appeal status is complete" do
        let(:vacols_case) { create(:case, :status_complete, case_issues: [vacols_case_issue], bfkey: vacols_id) }
        it { is_expected.to be_falsey }
      end
    end
  end

  context "#allowed?" do
    subject { issue.allowed? }

    context "when disposition is allowed" do
      let(:disposition) { :allowed }

      it { is_expected.to be_truthy }
    end

    context "when disposition is not allowed" do
      let(:disposition) { :remanded }

      it { is_expected.to be_falsey }
    end
  end

  context "#remanded?" do
    subject { issue.remanded? }

    context "when disposition is remanded" do
      let(:disposition) { :remanded }

      it { is_expected.to be_truthy }
    end

    context "when disposition is not remanded" do
      let(:disposition) { :allowed }

      it { is_expected.to be_falsey }
    end
  end

  context "#merged?" do
    subject { issue.merged? }

    context "when disposition is merged" do
      let(:disposition) { :merged }

      it { is_expected.to be_truthy }
    end

    context "when disposition is not merged" do
      let(:disposition) { :allowed }

      it { is_expected.to be_falsey }
    end
  end

  context "#new_material?" do
    subject { issue.new_material? }

    context "when not new and material" do
      it { is_expected.to be_falsey }
    end

    context "when new and material" do
      let(:codes) { %w[02 15 04 5252] }

      it { is_expected.to be_truthy }
    end
  end

  context "#not_new_material?" do
    subject { issue.non_new_material? }

    it "is the opposite of new_material?" do
      expect(subject).to eq(!issue.new_material?)
    end
  end

  context "#non_new_material_allowed?" do
    subject { issue.non_new_material_allowed? }

    context "when non_new_material" do
      it { is_expected.to be_truthy }

      context "when allowed disposition" do
        let(:disposition) { :allowed }
        it { is_expected.to be_truthy }
      end

      context "when non-allowed disposition" do
        let(:disposition) { :remanded }
        it { is_expected.to be_falsey }
      end
    end

    context "when new material" do
      let(:codes) { %w[02 15 04 5252] }

      context "when allowed disposition" do
        let(:disposition) { :remanded }
        it { is_expected.to be_falsey }
      end

      context "when non-allowed disposition" do
        let(:disposition) { :remanded }
        it { is_expected.to be_falsey }
      end
    end

    context "when non-allowed disposition" do
      let(:disposition) { :remanded }

      it "returns false" do
        expect(issue.allowed?).to be_falsey
        expect(subject).to be_falsey
      end
    end
  end

  context "#closed?" do
    subject { issue.closed? }
    let(:disposition) { nil }
    let(:vacols_case) { create(:case, :status_advance, case_issues: [vacols_case_issue], bfkey: vacols_id) }
    let(:vacols_case_issue) { create(:case_issue) }
    let!(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }

    it { is_expected.to be_falsey }

    context "disposition is present" do
      let(:disposition) { :remanded }

      it { is_expected.to be_truthy }
    end

    context "case is REM, disposition is remanded" do
      let(:disposition) { :remanded }
      let(:vacols_case) { create(:case, :status_remand, case_issues: [vacols_case_issue], bfkey: vacols_id) }

      it { is_expected.to be_falsey }
    end

    context "case is neither REM nor ADV nor HIS" do
      let(:vacols_case) { create(:case, :status_active, case_issues: [vacols_case_issue], bfkey: vacols_id) }

      it { is_expected.to be_falsey }
    end
  end

  context "#eligible_for_opt_in?" do
    let(:disposition) { nil }
    let(:soc_date) { Time.zone.today }
    let(:vacols_case) do
      create(:case_with_soc, :status_advance, case_issues: [vacols_case_issue], bfkey: vacols_id, bfdsoc: soc_date)
    end
    let(:vacols_case_issue) do
      create(
        :case_issue,
        isskey: vacols_id,
        issdc: Issue.disposition_code_for_sym(disposition),
        issdcls: disposition_date
      )
    end
    let!(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
    let(:issue) { Issue.load_from_vacols(vacols_case_issue.attributes) }
    let(:covid_flag) { false }

    subject { issue.eligible_for_opt_in?(covid_flag: covid_flag) }

    it { is_expected.to be_truthy }

    context "disposition is present" do
      let(:disposition) { :remanded }

      it { is_expected.to be_falsey }
    end

    context "disposition is failure to respond" do
      let(:disposition) { :remand_failure_to_respond }

      context "parent appeal SOC is later than disposition_date" do
        let(:disposition_date) { Time.zone.today - 1.day }

        it { is_expected.to be_falsey }

        context "issue has covid timeliness exemption" do
          let(:covid_flag) { true }

          it { is_expected.to be_truthy }
        end
      end

      context "parent appeal SOC is earlier than disposition_date" do
        let(:soc_date) { Time.zone.today - 1.day }

        it { is_expected.to be_truthy }
      end
    end

    context "case is REM, disposition is remanded" do
      let(:disposition) { :remanded }
      let(:vacols_case) { create(:case_with_soc, :status_remand, case_issues: [vacols_case_issue], bfkey: vacols_id) }

      it { is_expected.to be_truthy }
    end
  end
end
