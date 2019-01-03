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
        decision_review: decision_document.appeal
      )
    end

    let(:rating_or_nonrating) { :rating }

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
end
