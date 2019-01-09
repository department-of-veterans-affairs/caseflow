describe BoardGrantEffectuation do
  before do
    Timecop.freeze(Time.utc(2020, 1, 1, 19, 0, 0))
  end

  let(:decision_document) { create(:decision_document) }

  context ".create" do
    subject { BoardGrantEffectuation.create(granted_decision_issue: granted_decision_issue) }

    let!(:granted_decision_issue) do
      FactoryBot.create(
        :decision_issue,
        rating_or_nonrating,
        disposition: "allowed",
        decision_review: decision_document.appeal,
        benefit_type: benefit_type
      )
    end

    let(:rating_or_nonrating) { :rating }
    let(:benefit_type) { "compensation" }

    it do
      is_expected.to have_attributes(
        appeal_id: decision_document.appeal.id,
        decision_document_id: decision_document.id
      )
    end

    context "when matching end product establishment exists" do
      let!(:matching_end_product_establishment) do
        FactoryBot.create(
          :end_product_establishment,
          code: "030BGR",
          source: decision_document,
          established_at: nil
        )
      end

      let!(:not_matching_end_product_establishment) do
        FactoryBot.create(
          :end_product_establishment,
          code: "030BGNR",
          source: decision_document
        )
      end

      let!(:already_established_end_product_establishment) do
        FactoryBot.create(
          :end_product_establishment,
          code: "030BGR",
          source: decision_document,
          established_at: Time.zone.now
        )
      end

      it "associates it with the effectuation" do
        expect(subject.end_product_establishment).to eq(matching_end_product_establishment)
      end
    end

    context "when non compensation issue" do
      let(:benefit_type) { "insurance" }
      let(:rating_or_nonrating) { :nonrating }

      context "when a task doesn't exist yet" do
        it "creates a task and not an end product establishment" do
          expect(subject.end_product_establishment).to be_nil
          expect(BoardGrantEffectuationTask.find_by(appeal: decision_document.appeal)).to have_attributes(
            assigned_to: BusinessLine.find_by(url: benefit_type)
          )
        end
      end

      context "when a task already exists" do
        let(:task) do
          create(
            :board_grant_effectuation_task,
            appeal: decision_document.appeal,
            assigned_to: BusinessLine.find_by(url: benefit_type)
          )
        end

        it "does not create a new task" do
          expect(subject.end_product_establishment).to be_nil
          expect(BoardGrantEffectuationTask.where(
            appeal: decision_document.appeal,
            assigned_to: BusinessLine.find_by(url: benefit_type)
          ).count).to eq(1)
        end
      end
    end

    context "when compensation issue" do
      let(:benefit_type) { "compensation" }

      context "when rating issue" do
        let(:rating_or_nonrating) { :rating }

        it "creates rating end product establishment" do
          expect(subject.end_product_establishment).to have_attributes(
            source: decision_document,
            veteran_file_number: decision_document.appeal.veteran.file_number,
            claim_date: decision_document.decision_date,
            payee_code: "00",
            benefit_type_code: decision_document.appeal.veteran.benefit_type_code,
            user: User.system_user,
            code: "030BGR"
          )
        end
      end

      context "when non rating issue" do
        let(:rating_or_nonrating) { :nonrating }

        # Create a not matching end product establishment to make sure that never matches
        let!(:not_matching_end_product_establishment) do
          FactoryBot.create(
            :end_product_establishment,
            code: "030BGR",
            source: decision_document
          )
        end

        it "creates nonrating end product establishment" do
          expect(subject.end_product_establishment).to have_attributes(
            source: decision_document,
            veteran_file_number: decision_document.appeal.veteran.file_number,
            claim_date: decision_document.decision_date,
            payee_code: "00",
            benefit_type_code: decision_document.appeal.veteran.benefit_type_code,
            user: User.system_user,
            code: "030BGNR"
          )
        end
      end
    end

    context "when pension issue" do
      let(:benefit_type) { "pension" }

      context "when rating issue" do
        let(:rating_or_nonrating) { :rating }

        it "creates rating end product establishment" do
          expect(subject.end_product_establishment).to have_attributes(
            source: decision_document,
            veteran_file_number: decision_document.appeal.veteran.file_number,
            claim_date: decision_document.decision_date,
            payee_code: "00",
            benefit_type_code: decision_document.appeal.veteran.benefit_type_code,
            user: User.system_user,
            code: "030BGRPMC"
          )
        end
      end

      context "when non rating issue" do
        let(:rating_or_nonrating) { :nonrating }

        # Create a not matching end product establishment to make sure that never matches
        let!(:not_matching_end_product_establishment) do
          FactoryBot.create(
            :end_product_establishment,
            code: "030BGR",
            source: decision_document
          )
        end

        it "creates nonrating end product establishment" do
          expect(subject.end_product_establishment).to have_attributes(
            source: decision_document,
            veteran_file_number: decision_document.appeal.veteran.file_number,
            claim_date: decision_document.decision_date,
            payee_code: "00",
            benefit_type_code: decision_document.appeal.veteran.benefit_type_code,
            user: User.system_user,
            code: "030BGNRPMC"
          )
        end
      end
    end
  end
end
