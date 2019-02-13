describe BoardGrantEffectuation do
  before do
    Timecop.freeze(Time.utc(2020, 1, 1, 19, 0, 0))
  end

  let!(:veteran) { decision_document.appeal.veteran }
  let(:decision_document) { create(:decision_document) }
  let(:contention_reference_id) { nil }
  let(:board_grant_effectuation) do
    BoardGrantEffectuation.create(
      granted_decision_issue: granted_decision_issue,
      decision_sync_processed_at: processed_at,
      contention_reference_id: contention_reference_id
    )
  end

  let(:end_product_establishment) do
    board_grant_effectuation.end_product_establishment
  end

  let(:rating_or_nonrating) { :rating }
  let(:benefit_type) { "compensation" }
  let(:processed_at) { nil }

  let!(:granted_decision_issue) do
    FactoryBot.create(
      :decision_issue,
      rating_or_nonrating,
      disposition: "allowed",
      decision_review: decision_document.appeal,
      benefit_type: benefit_type
    )
  end

  context "#sync_decision_issues!" do
    subject { board_grant_effectuation.sync_decision_issues! }
    before { end_product_establishment.update!(established_at: 3.months.ago) }

    let(:associated_claims) { nil }

    let!(:rating) do
      Generators::Rating.build(
        participant_id: veteran.participant_id,
        promulgation_date: 15.days.ago,
        profile_date: 20.days.ago,
        issues: [
          { reference_id: "ref_id1", decision_text: "PTSD denied", contention_reference_id: "1111" },
          { reference_id: "ref_id2", decision_text: "Left leg", contention_reference_id: "2222" }
        ],
        associated_claims: associated_claims
      )
    end

    context "when the decision issue is already processed" do
      let(:processed_at) { 1.day.ago }
      it "does nothing" do
        subject
        expect(board_grant_effectuation.decision_sync_attempted_at).to be_nil
      end
    end

    context "when there is no associated rating on the end product" do
      it "attempts sync but does not finish processing" do
        subject
        expect(board_grant_effectuation).to be_attempted
        expect(board_grant_effectuation).to_not be_processed
      end
    end

    context "when there is an associated rating" do
      before { end_product_establishment.update!(reference_id: "ep_ref_id") }
      let(:associated_claims) { [{ clm_id:  "ep_ref_id", bnft_clm_tc: "ep_code" }] }

      context "when a matching rating issue is found" do
        let(:contention_reference_id) { "1111" }

        it "Updates the granted decision issue" do
          subject
          expect(granted_decision_issue).to have_attributes(
            promulgation_date: rating.promulgation_date,
            profile_date: rating.profile_date,
            decision_text: "PTSD denied",
            rating_issue_reference_id: "ref_id1"
          )
          expect(board_grant_effectuation).to be_processed
        end
      end

      context "when a matching rating issue is not found" do
        let(:contention_reference_id) { "9999" }

        it "is processed but does not update granted decision issue" do
          subject
          expect(board_grant_effectuation).to be_attempted
          expect(granted_decision_issue).to have_attributes(
            promulgation_date: nil,
            profile_date: nil,
            decision_text: nil,
            rating_issue_reference_id: nil
          )
          expect(board_grant_effectuation).to be_processed
        end
      end

      context "when previous attempt failed" do
        let(:contention_reference_id) { "1111" }

        it "clears error" do
          board_grant_effectuation.decision_sync_error = "previous error"
          subject
          expect(board_grant_effectuation.decision_sync_error).to be_nil
        end
      end
    end
  end

  context ".create" do
    subject { BoardGrantEffectuation.create(granted_decision_issue: granted_decision_issue) }

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
          code: "030BGRNR",
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
            code: "030BGRNR"
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
