# frozen_string_literal: true

def complete_params(judge:, attorney:, location:, vacols_issue1:, vacols_issue2:)
  {
    location: location,
    judge: judge,
    task_id: "123456-2013-12-06",
    attorney: attorney,
    complexity: "hard",
    quality: "does_not_meet_expectations",
    comment: "do this",
    factors_not_considered: %w[theory_contention relevant_records],
    areas_for_improvement: ["process_violations"],
    issues: [
      { disposition: "5", id: vacols_issue1.issseq, readjudication: true },
      { disposition: "3", id: vacols_issue2.issseq,
        remand_reasons: [{ code: "AB", post_aoj: true }] }
    ]
  }
end

# rubocop:disable Metrics/AbcSize
def expect_decass_to_be_up_to_date(decass)
  decass.reload
  expect(decass.demdusr).to eq "CFS456"
  expect(decass.defdiff).to eq "3"
  expect(decass.deoq).to eq "1"
  expect(decass.deqr2).to eq "Y"
  expect(decass.deqr6).to eq "Y"
  expect(decass.deqr9).to eq "Y"
  expect(decass.deqr1).to eq nil
  expect(decass.deqr3).to eq nil
  expect(decass.deqr4).to eq nil
  expect(decass.decomp).to eq VacolsHelper.local_date_with_utc_timezone
  expect(decass.detrem).to eq "N"
end
# rubocop:enable Metrics/AbcSize

def expect_case_to_be_update_to_date(vacols_case, decass)
  expect(vacols_case.bfmemid).to eq(decass.dememid)
  expect(vacols_case.bfattid).to eq(decass.deatty)
  expect(vacols_case.bfboard).to eq(decass.deteam)
end

describe JudgeCaseReview, :all_dbs do
  before do
    Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
  end

  after do
    Timecop.return
  end

  context ".reached_monthly_limit_in_quality_reviews?" do
    before do
      JudgeCaseReview.skip_callback(:create, :after, :select_case_for_legacy_quality_review)
    end

    after do
      JudgeCaseReview.set_callback(:create, :after, :select_case_for_legacy_quality_review)
    end

    subject { JudgeCaseReview.reached_monthly_limit_in_quality_reviews? }
    let(:limit) { JudgeCaseReview::MONTHLY_LIMIT_OF_QUALITY_REVIEWS }

    context "when more than monthly limit" do
      before do
        limit.times { create(:judge_case_review, location: :quality_review) }
      end

      it { is_expected.to be true }
    end

    context "when less than monthly limit" do
      before do
        (limit - 1).times { create(:judge_case_review, location: :quality_review) }
        create(:judge_case_review, created_at: 2.months.ago, location: :quality_review)
        create(:judge_case_review, location: :bva_dispatch)
      end

      it { is_expected.to be false }
    end
  end

  context ".create" do
    let(:judge) { User.create(css_id: "CFS123", station_id: User::BOARD_STATION_ID) }
    let(:attorney) { User.create(css_id: "CFS456", station_id: "317") }
    let(:probability) { JudgeCaseReview::QUALITY_REVIEW_SELECTION_PROBABILITY }
    subject { JudgeCaseReview.complete(params) }

    context "when ama case review" do
      let(:probability) { JudgeCaseReview::QUALITY_REVIEW_SELECTION_PROBABILITY }
      let(:task) { create(:ama_judge_decision_review_task) }
      let(:request_issue) { create(:request_issue, decision_review: task.appeal) }
      let(:params) do
        {
          location: "bva_dispatch",
          judge: judge,
          task_id: task.id,
          attorney: attorney,
          complexity: "hard",
          quality: "does_not_meet_expectations",
          comment: "do this",
          factors_not_considered: %w[theory_contention relevant_records],
          areas_for_improvement: ["process_violations"],
          issues: [{ disposition: "allowed", description: "something1",
                     benefit_type: "compensation", diagnostic_code: "9999",
                     request_issue_ids: [request_issue.id] }]
        }
      end

      it "should not select the case for a quality review" do
        allow_any_instance_of(JudgeCaseReview).to receive(:rand).and_return(probability / 2)
        expect(subject.valid?).to eq true
        expect(subject.location).to eq "bva_dispatch"
      end
    end

    context "when legacy case review" do
      let!(:decass) do
        create(:decass,
               deadtim: "2013-12-06".to_date,
               defolder: "123456",
               deprod: work_product,
               deatty: "102",
               deteam: "BB",
               dereceive: 4.days.ago,
               dedeadline: 6.days.ago)
      end
      let!(:vacols_case) { create(:case, bfkey: "123456") }
      let!(:vacols_issue1) { create(:case_issue, isskey: "123456") }
      let!(:vacols_issue2) { create(:case_issue, isskey: "123456") }
      let!(:judge_staff) { create(:staff, :judge_role, slogid: "CFS456", sdomainid: judge.css_id, sattyid: "AA") }

      context "when all parameters are present to sign a decision and VACOLS update is successful" do
        before do
          RequestStore.store[:current_user] = judge
          allow(UserRepository).to receive(:fail_if_no_access_to_task!).and_return(true)
        end

        context "when selected for quality review" do
          let(:params) do
            {
              location: "bva_dispatch",
              judge: judge,
              task_id: "123456-2013-12-06",
              attorney: attorney,
              complexity: "hard",
              quality: "does_not_meet_expectations",
              comment: "do this",
              factors_not_considered: %w[theory_contention relevant_records],
              areas_for_improvement: ["process_violations"],
              issues: issues
            }
          end
          let(:issues) do
            [
              { disposition: "5", id: vacols_issue1.issseq, readjudication: true },
              { disposition: "3", id: vacols_issue2.issseq,
                remand_reasons: [{ code: "AB", post_aoj: true }] }
            ]
          end
          let(:work_product) { "DEC" }

          it "should create judge case review and change the location to quality review" do
            allow_any_instance_of(JudgeCaseReview).to receive(:rand).and_return(probability / 2)
            expect(subject.valid?).to eq true
            expect(subject.location).to eq "quality_review"
            expect(subject.complexity).to eq "hard"
            expect(subject.quality).to eq "does_not_meet_expectations"
            expect(subject.comment).to eq "do this"
            expect(subject.factors_not_considered).to eq %w[theory_contention relevant_records]
            expect(subject.areas_for_improvement).to eq ["process_violations"]
            expect(subject.judge).to eq judge
            expect(subject.attorney).to eq attorney
            expect(decass.reload.demdusr).to eq "CFS456"
            expect(decass.defdiff).to eq "3"
            expect(decass.deoq).to eq "1"
            expect(decass.deqr2).to eq "Y"
            expect(decass.deqr6).to eq "Y"
            expect(decass.deqr9).to eq "Y"
            expect(decass.deqr1).to eq nil
            expect(decass.deqr3).to eq nil
            expect(decass.deqr4).to eq nil
            expect(decass.dememid).to eq "AA"
            expect(decass.decomp).to eq VacolsHelper.local_date_with_utc_timezone
            expect(decass.detrem).to eq "N"

            expect(vacols_case.reload.bfcurloc).to eq "48"
            expect(vacols_case.bfmemid).to eq "AA"
            expect(vacols_case.bfattid).to eq "102"
            expect(vacols_case.bfboard).to eq "BB"

            vacols_issues = VACOLS::CaseIssue.where(isskey: "123456")
            # 1 vacated, 1 remanded and 1 blank issue created because of vacated disposition
            expect(vacols_issues.size).to eq 3

            expect(vacols_issues.first.issdc).to eq "5"
            expect(vacols_issues.first.issseq).to eq vacols_issue1.issseq
            expect(vacols_issues.first.issmduser).to eq "CFS456"

            expect(vacols_issues.second.issdc).to eq "3"
            expect(vacols_issues.second.issseq).to eq vacols_issue2.issseq
            expect(vacols_issues.second.issmduser).to eq "CFS456"

            expect(vacols_issues.third.issdc).to eq nil
            expect(vacols_issues.third.issseq).to eq(vacols_issue2.issseq + 1)
            expect(vacols_issues.third.issaduser).to eq "CFS456"

            remand_reasons = VACOLS::RemandReason.where(rmdkey: "123456", rmdissseq: vacols_issue2.issseq)
            expect(remand_reasons.size).to eq 1
            expect(remand_reasons.first.rmdissseq).to eq vacols_issue2.issseq
            expect(remand_reasons.first.rmdmdusr).to eq "CFS456"

            quality_review_record = VACOLS::DecisionQualityReview.find_by(qrfolder: vacols_case.bfkey)
            expect(quality_review_record.qrsmem).to eq "AA"
            expect(quality_review_record.qrteam).to eq "BB"
            expect(quality_review_record.qrseldate).to eq VacolsHelper.local_date_with_utc_timezone
            expect(quality_review_record.qryymm).to eq "1901"
          end
        end

        context "when bva dispatch" do
          let(:params) do
            complete_params(
              judge: judge,
              attorney: attorney,
              location: "bva_dispatch",
              vacols_issue1: vacols_issue1,
              vacols_issue2: vacols_issue2
            )
          end
          let(:work_product) { "DEC" }

          it "should create Judge Case Review" do
            allow_any_instance_of(JudgeCaseReview).to receive(:rand).and_return(probability + probability)
            expect(subject.valid?).to eq true
            expect(subject.location).to eq "bva_dispatch"
            expect(subject.judge).to eq judge
            expect(subject.attorney).to eq attorney
            expect(subject.complexity).to eq "hard"
            expect(subject.quality).to eq "does_not_meet_expectations"
            expect(subject.comment).to eq "do this"
            expect(subject.factors_not_considered).to eq %w[theory_contention relevant_records]
            expect(subject.areas_for_improvement).to eq ["process_violations"]

            expect_decass_to_be_up_to_date(decass)

            vacols_case.reload
            expect(vacols_case.bfcurloc).to eq "4E"
            expect_case_to_be_update_to_date(vacols_case, decass)

            vacols_issues = VACOLS::CaseIssue.where(isskey: "123456")
            # 1 vacated, 1 remanded and 1 blank issue created because of vacated disposition
            expect(vacols_issues.size).to eq 3

            expect(vacols_issues.first.issdc).to eq "5"
            expect(vacols_issues.first.issseq).to eq vacols_issue1.issseq
            expect(vacols_issues.first.issmduser).to eq "CFS456"

            expect(vacols_issues.second.issdc).to eq "3"
            expect(vacols_issues.second.issseq).to eq vacols_issue2.issseq
            expect(vacols_issues.second.issmduser).to eq "CFS456"

            expect(vacols_issues.third.issdc).to eq nil
            expect(vacols_issues.third.issseq).to eq(vacols_issue2.issseq + 1)
            expect(vacols_issues.third.issaduser).to eq "CFS456"

            remand_reasons = VACOLS::RemandReason.where(rmdkey: "123456", rmdissseq: vacols_issue2.issseq)
            expect(remand_reasons.size).to eq 1
            expect(remand_reasons.first.rmdissseq).to eq vacols_issue2.issseq
            expect(remand_reasons.first.rmdmdusr).to eq "CFS456"

            expect(VACOLS::DecisionQualityReview.find_by(qrfolder: vacols_case.bfkey)).to eq nil
          end
        end

        context "when omo office" do
          let(:params) do
            complete_params(
              judge: judge,
              attorney: attorney,
              location: "omo_office",
              vacols_issue1: vacols_issue1,
              vacols_issue2: vacols_issue2
            )
          end
          let(:work_product) { "IME" }

          it "should create Judge Case Review" do
            allow_any_instance_of(JudgeCaseReview).to receive(:rand).and_return(probability + probability)
            expect(subject.valid?).to eq true
            expect(subject.location).to eq "omo_office"
            expect(subject.judge).to eq judge
            expect(subject.attorney).to eq attorney

            expect_decass_to_be_up_to_date(decass)

            expect(vacols_case.reload.bfcurloc).to eq "20"
            expect_case_to_be_update_to_date(vacols_case, decass)

            expect(VACOLS::DecisionQualityReview.find_by(qrfolder: vacols_case.bfkey)).to eq nil
          end
        end
      end
    end
  end
end
