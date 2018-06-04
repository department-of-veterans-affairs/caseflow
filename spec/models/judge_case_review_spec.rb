describe JudgeCaseReview do
  let(:judge) { User.create(css_id: "CFS123", station_id: User::BOARD_STATION_ID) }
  let(:attorney) { User.create(css_id: "CFS456", station_id: "317") }

  context ".create" do
    subject { JudgeCaseReview.create(params) }

    context "when all parameters are present to sign a decision and VACOLS update is successful" do
      before do
        allow(UserRepository).to receive(:vacols_uniq_id).and_return("CFS456")
        allow(UserRepository).to receive(:can_access_task?).and_return(true)
        allow(QueueRepository).to receive(:sign_decision_or_create_omo!).with(
          vacols_id: "123456",
          created_in_vacols_date: "2013-12-06".to_date,
          location: :bva_dispatch,
          decass_attrs: {
            complexity: "hard",
            quality: "does_not_meet_expectations",
            comment: "do this",
            modifying_user: "CFS456",
            deficiencies: %w[theory_contention relevant_records process_violations]
          }
        ).and_return(true)
      end

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
      end
    end
  end
end
