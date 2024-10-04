# frozen_string_literal: true

describe SupplementalClaim, :postgres do
  before do
    Timecop.freeze(Time.utc(2018, 4, 24, 12, 0, 0))
  end

  let(:veteran_file_number) { "64205555" }
  let(:ssn) { "64205555" }
  let!(:veteran) { Generators::Veteran.build(file_number: "64205555", ssn: ssn) }
  let(:receipt_date) { nil }
  let(:benefit_type) { nil }
  let(:legacy_opt_in_approved) { nil }
  let(:veteran_is_not_claimant) { false }
  let(:decision_review_remanded) { nil }

  let(:supplemental_claim) do
    SupplementalClaim.new(
      veteran_file_number: veteran_file_number,
      receipt_date: receipt_date,
      benefit_type: benefit_type,
      legacy_opt_in_approved: legacy_opt_in_approved,
      veteran_is_not_claimant: veteran_is_not_claimant,
      decision_review_remanded: decision_review_remanded
    )
  end

  let!(:intake) do
    create(:intake, user: current_user, detail: supplemental_claim, veteran_file_number: veteran_file_number)
  end

  let(:current_user) do
    User.authenticate!(roles: ["Admin Intake"])
  end

  context "#valid?" do
    subject { supplemental_claim.valid? }

    context "when saving review" do
      before { supplemental_claim.start_review! }

      context "review fields when they are set" do
        let(:benefit_type) { "compensation" }
        let(:legacy_opt_in_approved) { false }
        let(:receipt_date) { 1.day.ago }

        it "is valid" do
          is_expected.to be true
        end

        context "invalid Veteran" do
          context "processed in VBMS" do
            let(:benefit_type) { "compensation" }

            it "adds an error" do
              veteran.update(first_name: nil)
              expect(subject).to eq false
              expect(supplemental_claim.errors[:veteran]).to include("veteran_not_valid")
            end
          end

          context "processed in Caseflow" do
            let(:benefit_type) { "education" }

            it { is_expected.to be_truthy }
          end
        end
      end

      context "when they are nil" do
        let(:veteran_is_not_claimant) { nil }
        it "adds errors" do
          is_expected.to be false
          expect(supplemental_claim.errors[:benefit_type]).to include("blank")
          expect(supplemental_claim.errors[:legacy_opt_in_approved]).to include("blank")
          expect(supplemental_claim.errors[:receipt_date]).to include("blank")
          expect(supplemental_claim.errors[:veteran_is_not_claimant]).to include("blank")
        end
      end
    end

    context "receipt_date" do
      let(:benefit_type) { "compensation" }
      let(:legacy_opt_in_approved) { false }
      context "when it is nil" do
        it { is_expected.to be true }
      end

      context "when saving review" do
        before { supplemental_claim.start_review! }

        context "when it is after today" do
          let(:receipt_date) { 1.day.from_now }

          it "adds an error to receipt_date" do
            is_expected.to be false
            expect(supplemental_claim.errors[:receipt_date]).to include("in_future")
          end
        end

        context "when it is before AMA begin date" do
          let(:receipt_date) { ama_test_start_date - 1 }

          it "adds an error to receipt_date" do
            is_expected.to be false
            expect(supplemental_claim.errors[:receipt_date]).to include("before_ama")
          end
        end

        context "when it is nil" do
          let(:receipt_date) { nil }

          it "adds error to receipt_date" do
            is_expected.to be false
            expect(supplemental_claim.errors[:receipt_date]).to include("blank")
          end
        end
      end
    end
  end

  context "create_remand_issues!" do
    subject { supplemental_claim.create_remand_issues! }

    let(:decision_review_remanded) { create(:appeal) }
    let!(:decision_document) do
      create(:decision_document, decision_date: Time.zone.today - 3.days, appeal: decision_review_remanded)
    end
    let(:benefit_type) { "education" }

    let!(:decision_issue_not_remanded) do
      create(
        :decision_issue,
        disposition: "allowed",
        benefit_type: benefit_type,
        decision_review: decision_review_remanded
      )
    end

    let!(:decision_issue_benefit_type_not_matching) do
      create(
        :decision_issue,
        disposition: "remanded",
        benefit_type: "insurance",
        decision_review: decision_review_remanded
      )
    end

    let!(:decision_issue_needing_remand) do
      create(
        :decision_issue,
        disposition: "remanded",
        benefit_type: benefit_type,
        decision_review: decision_review_remanded,
        rating_issue_reference_id: "1234",
        description: "a description"
      )
    end

    let!(:already_contested_remanded_di) do
      create(
        :decision_issue,
        disposition: "remanded",
        benefit_type: benefit_type,
        decision_review: decision_review_remanded,
        rating_issue_reference_id: "1234",
        description: "a description"
      )
    end

    let!(:ri_contesting_di) { create(:request_issue, contested_decision_issue_id: already_contested_remanded_di.id) }

    it "creates remand issues for appropriate decision issues" do
      expect { subject }.to change(supplemental_claim.request_issues, :count).by(1)

      expect(supplemental_claim.request_issues.last).to have_attributes(
        decision_review: supplemental_claim,
        contested_decision_issue_id: decision_issue_needing_remand.id,
        contested_rating_issue_reference_id: decision_issue_needing_remand.rating_issue_reference_id,
        contested_rating_issue_profile_date: decision_issue_needing_remand.rating_profile_date,
        contested_issue_description: decision_issue_needing_remand.description,
        benefit_type: benefit_type
      )

      expect(RequestIssue.find_by(
               decision_review: supplemental_claim,
               contested_decision_issue_id: already_contested_remanded_di.id,
               contested_rating_issue_reference_id: already_contested_remanded_di.rating_issue_reference_id,
               contested_rating_issue_profile_date: already_contested_remanded_di.rating_profile_date,
               contested_issue_description: already_contested_remanded_di.description,
               benefit_type: benefit_type
             )).to be_nil
    end

    it "doesn't create duplicate remand issues" do
      supplemental_claim.create_remand_issues!

      expect { subject }.to_not change(supplemental_claim.request_issues, :count)
    end
  end

  context "#alerts" do
    let(:receipt_date) { Time.new("2018", "03", "01").utc }
    let(:benefit_type) { "compensation" }

    let!(:sc) do
      create(:supplemental_claim,
             veteran_file_number: veteran_file_number,
             receipt_date: receipt_date,
             benefit_type: benefit_type)
    end

    context "have a decision" do
      let(:decision_date) { receipt_date + 100.days }

      let!(:sc_ep) do
        create(:end_product_establishment,
               :cleared, source: sc, last_synced_at: decision_date)
      end

      let!(:decision_issue) do
        create(:decision_issue,
               decision_review: sc, end_product_last_action_date: decision_date,
               benefit_type: benefit_type, diagnostic_code: nil)
      end

      it "has a ama post decision alert" do
        alerts = sc.alerts

        expect(alerts.empty?).to be(false)
        expect(alerts.first[:type]).to eq("ama_post_decision")
        expect(alerts.first[:details][:decisionDate]).to eq(decision_date.to_date)
        expect(alerts.first[:details][:dueDate]).to eq((decision_date + 365.days).to_date)
        expect(alerts.first[:details][:cavcDueDate]).to be_nil

        available_options = %w[supplemental_claim higher_level_review appeal]
        expect(alerts.first[:details][:availableOptions]).to eq(available_options)
      end
    end
  end

  context "#other_close_event_date" do
    subject { supplemental_claim.other_close_event_date }

    context "with an end product" do
      let!(:sc_ep) do
        create(:end_product_establishment,
               :cleared, source: supplemental_claim,
                         last_synced_at: last_synced_at)
      end

      context "when end product's last_synced_at is nil" do
        let(:last_synced_at) { nil }
        it "returns nil" do
          expect(subject).to be_nil
        end
      end

      context "when end product has a last_synced_at" do
        let(:last_synced_at) { Time.now.utc }
        it "returns that date" do
          expect(subject).to eq(last_synced_at.to_date)
        end
      end
    end
  end
end
