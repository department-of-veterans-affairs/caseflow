# frozen_string_literal: true

def complete_params(judge:, attorney:, location:, vacols_issue1:, vacols_issue2:)
  {
    location: location,
    judge: judge,
    task_id: "123456-2013-12-06",
    attorney: attorney,
    timeliness: "timely",
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
  expect(decass.demdusr).to eq vacols_judge.slogid
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

def expect_case_to_be_update_to_date(vacols_case, decass)
  expect(vacols_case.bfmemid).to eq(decass.dememid)
  expect(vacols_case.bfattid).to eq(decass.deatty)
  expect(vacols_case.bfboard).to eq(decass.deteam)
end

def expect_case_review_to_match_params(case_review)
  expect(case_review.valid?).to eq true
  expect(case_review.complexity).to eq "hard"
  expect(case_review.quality).to eq "does_not_meet_expectations"
  expect(case_review.comment).to eq "do this"
  expect(case_review.factors_not_considered).to match_array %w[theory_contention relevant_records]
  expect(case_review.areas_for_improvement).to match_array ["process_violations"]
  expect(case_review.judge).to eq judge
  expect(case_review.attorney).to eq attorney
  expect(case_review.appeal_type).to eq "LegacyAppeal"
  expect(case_review.appeal_id).to eq LegacyAppeal.find_by_vacols_id(vacols_case.bfkey).id
end
# rubocop:enable Metrics/AbcSize

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
    let(:judge) { create(:user, :judge, css_id: "CFS123" ) }
    let!(:vacols_judge) { create(:staff, :judge_role, user: judge) }
    let(:attorney) { create(:user, css_id: "CFS456", station_id: "317") }
    let!(:vacols_attorney) { create(:staff, :attorney_role, user: attorney) }
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

      it "should associate appeal to JudgeCaseReview" do
        case_review = subject
        expect(case_review.appeal_type).to eq "Appeal"
        expect(case_review.appeal_id).to eq task.appeal.id
        expect(task.appeal.judge_case_reviews).to eq [case_review]
        expect(task.appeal.attorney_case_reviews).to eq []
      end
    end

    context "when legacy case review" do
      let!(:decass) do
        create(:decass,
               deadtim: "2013-12-06".to_date,
               defolder: vacols_case.bfkey,
               deprod: work_product,
               deatty: "102",
               deteam: "BB",
               dereceive: 4.days.ago,
               dedeadline: 6.days.ago)
      end
      let!(:vacols_case) { create(:case, bfkey: "123456") }
      let(:vacols_issue1) { create(:case_issue, isskey: vacols_case.bfkey) }
      let(:vacols_issue2) { create(:case_issue, isskey: vacols_case.bfkey) }

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
            expect(subject.location).to eq "quality_review"
            expect_case_review_to_match_params(subject)

            expect_decass_to_be_up_to_date(decass)

            expect(vacols_case.reload.bfcurloc).to eq "48"
            expect(vacols_case.bfmemid).to eq vacols_judge.sattyid
            expect(vacols_case.bfattid).to eq "102"
            expect(vacols_case.bfboard).to eq "BB"

            vacols_issues = VACOLS::CaseIssue.where(isskey: vacols_case.bfkey)
            # 1 vacated, 1 remanded and 1 blank issue created because of vacated disposition
            expect(vacols_issues.size).to eq 3

            vacols_issue = vacols_issues.find_by(issseq: 1)
            expect(vacols_issue.issdc).to eq "5"
            expect(vacols_issue.issseq).to eq vacols_issue1.issseq
            expect(vacols_issue.issmduser).to eq vacols_judge.slogid

            vacols_issue = vacols_issues.find_by(issseq: 2)
            expect(vacols_issue.issdc).to eq "3"
            expect(vacols_issue.issseq).to eq vacols_issue2.issseq
            expect(vacols_issue.issmduser).to eq vacols_judge.slogid

            vacols_issue = vacols_issues.find_by(issseq: 3)
            expect(vacols_issue.issdc).to eq nil
            expect(vacols_issue.issseq).to eq(vacols_issue2.issseq + 1)
            expect(vacols_issue.issaduser).to eq vacols_judge.slogid

            remand_reasons = VACOLS::RemandReason.where(rmdkey: "123456", rmdissseq: vacols_issue2.issseq)
            expect(remand_reasons.size).to eq 1
            expect(remand_reasons.first.rmdissseq).to eq vacols_issue2.issseq
            expect(remand_reasons.first.rmdmdusr).to eq vacols_judge.slogid

            quality_review_record = VACOLS::DecisionQualityReview.find_by(qrfolder: vacols_case.bfkey)
            expect(quality_review_record.qrsmem).to eq vacols_judge.sattyid
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
            expect(subject.location).to eq "bva_dispatch"
            expect_case_review_to_match_params(subject)

            expect_decass_to_be_up_to_date(decass)

            vacols_case.reload
            expect(vacols_case.bfcurloc).to eq "4E"
            expect_case_to_be_update_to_date(vacols_case, decass)

            vacols_issues = VACOLS::CaseIssue.where(isskey: vacols_case.bfkey)
            # 1 vacated, 1 remanded and 1 blank issue created because of vacated disposition
            expect(vacols_issues.size).to eq 3

            vacols_issue = vacols_issues.find_by(issseq: vacols_issue1.issseq)
            expect(vacols_issue.issdc).to eq "5"
            expect(vacols_issue.issmduser).to eq vacols_judge.slogid

            vacols_issue = vacols_issues.find_by(issseq: vacols_issue2.issseq)
            expect(vacols_issue.issdc).to eq "3"
            expect(vacols_issue.issmduser).to eq vacols_judge.slogid

            vacols_issue = vacols_issues.find_by(issseq: vacols_issue2.issseq + 1)
            expect(vacols_issue.issdc).to eq nil
            expect(vacols_issue.issaduser).to eq vacols_judge.slogid

            remand_reasons = VACOLS::RemandReason.where(rmdkey: "123456", rmdissseq: vacols_issue2.issseq)
            expect(remand_reasons.size).to eq 1
            expect(remand_reasons.first.rmdissseq).to eq vacols_issue2.issseq
            expect(remand_reasons.first.rmdmdusr).to eq vacols_judge.slogid

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

            expect(subject.appeal_type).to eq "LegacyAppeal"
            expect(subject.appeal_id).to eq LegacyAppeal.find_by_vacols_id(vacols_case.bfkey).id

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
