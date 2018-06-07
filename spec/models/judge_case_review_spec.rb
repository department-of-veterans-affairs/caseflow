describe JudgeCaseReview do
  let(:judge) { User.create(css_id: "CFS123", station_id: User::BOARD_STATION_ID) }
  let(:attorney) { User.create(css_id: "CFS456", station_id: "317") }
  let!(:decass) { create(:decass, deadtim: "2013-12-06".to_date, defolder: "123456", deprod: work_product) }
  let!(:vacols_case) { create(:case, bfkey: "123456") }

  context ".create" do
    subject { JudgeCaseReview.create(params) }

    context "when all parameters are present to sign a decision and VACOLS update is successful" do
      before do
        RequestStore.store[:current_user] = judge
        FeatureToggle.enable!(:test_facols)
        allow(UserRepository).to receive(:vacols_uniq_id).and_return("CFS456")
        allow(UserRepository).to receive(:can_access_task?).and_return(true)
      end

      after do
        FeatureToggle.disable!(:test_facols)
      end

      context "when bva dispatch" do

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
            areas_for_improvement: ["process_violations"]
          }
        end
        let(:work_product) { "DEC" }

        it "should create Judge Case Review" do
          expect(subject.valid?).to eq true
          expect(subject.location).to eq "bva_dispatch"
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
          expect(vacols_case.reload.bfcurloc).to eq "30"
        end
      end
    end
  end
end
