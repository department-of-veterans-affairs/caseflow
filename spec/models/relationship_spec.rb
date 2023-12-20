# frozen_string_literal: true

describe Relationship, :postgres do
  let(:veteran) { create(:veteran) }
  let(:relationship_type) { "Spouse" }
  let(:gender) { nil }

  let(:relationship) do
    Relationship.new(
      veteran_file_number: veteran.file_number,
      participant_id: "1234",
      first_name: "TORY",
      last_name: "VANCE",
      relationship_type: relationship_type,
      gender: gender
    )
  end

  context "#serialize" do
    subject { relationship.serialize }

    context "when there are no prior claims for that relationship" do
      context "when the claimant is a spouse" do
        let(:relationship_type) { "Spouse" }

        it "defaults to spouse payee code" do
          expect(subject).to include(
            participant_id: "1234",
            first_name: "TORY",
            last_name: "VANCE",
            relationship_type: "Spouse",
            default_payee_code: "10"
          )
        end
      end

      context "when the claimant is a child" do
        let(:relationship_type) { "Child" }

        it "defaults to spouse payee code" do
          expect(subject).to include(
            relationship_type: "Child",
            default_payee_code: "11"
          )
        end
      end

      context "when the relationship is a parent" do
        let(:relationship_type) { "Parent" }
        context "when the parent is male" do
          let(:gender) { "M" }

          it "returns the Father payee code" do
            expect(subject).to include(
              relationship_type: "Parent",
              default_payee_code: "50"
            )
          end
        end

        context "when the parent is female" do
          let(:gender) { "F" }

          it "returns the Mother payee code" do
            expect(subject).to include(
              relationship_type: "Parent",
              default_payee_code: "60"
            )
          end
        end
      end

      context "when the claimant is an unhandled relationship type" do
        let(:relationship_type) { "Other" }

        it "does not have a default payee code" do
          expect(subject).to include(
            relationship_type: "Other",
            default_payee_code: nil
          )
        end
      end
    end

    context "when there are previous claims with that relationship" do
      let!(:recent_end_product_with) do
        Generators::EndProduct.build(
          veteran_file_number: veteran.file_number,
          bgs_attrs: {
            benefit_claim_id: "claim_id",
            claimant_first_name: relationship.first_name,
            claimant_last_name: relationship.last_name,
            payee_type_code: "10",
            claim_date: 5.days.ago
          }
        )
      end

      let!(:outdated_end_product) do
        Generators::EndProduct.build(
          veteran_file_number: veteran.file_number,
          bgs_attrs: {
            benefit_claim_id: "another_claim_id",
            claimant_first_name: relationship.first_name,
            claimant_last_name: relationship.last_name,
            payee_type_code: "11",
            claim_date: 10.days.ago
          }
        )
      end

      it "returns hash with the claimant's most recently used payee code" do
        expect(subject).to include(
          participant_id: "1234",
          first_name: "TORY",
          last_name: "VANCE",
          relationship_type: "Spouse",
          default_payee_code: "10"
        )
      end
    end
  end
end
