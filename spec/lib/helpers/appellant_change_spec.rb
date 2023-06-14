# frozen_string_literal: true

require "helpers/appellant_change"

describe AppellantChange do
  describe "#run_appellant_change" do
    subject(:run_appellant_change) { described_class.new.run_appellant_change(arguments) }

    let(:arguments) { valid_params }
    let(:valid_params) do
      {
        appeal_uuid: double("appeal_uuid"),
        claimant_participant_id: "dummy-participant-id",
        claimant_type: "DependentClaimant",
        claimant_payee_code: "dummy-payee-code"
      }
    end

    context 'when appeal does not exist' do
      before { allow(Appeal).to receive(:find_by).and_return(nil) }

      it { is_expected.to be_nil }

      it 'puts an error message' do
        expect { run_appellant_change }.to output("Appeal not found for UUID\n").to_stdout
      end
    end

    context "when appeal is found" do
      let(:appeal) { instance_double("Appeal") }
      before { allow(Appeal).to receive(:find_by).and_return(appeal) }

      context 'when claimant type is invalid' do
        let(:arguments) { valid_params.merge(claimant_type: "InvalidClaimantType") }

        it { is_expected.to be_nil }
      end

      context 'when all parameters are valid' do

        context "when appeal has a claimant" do
          let!(:appeal) { create(:appeal) }
          let!(:claimant) { create(:claimant, decision_review: appeal) }

          it 'destroys the existing claimant' do
            expect(Claimant.find_by(id: claimant.id)).not_to be_nil
            run_appellant_change
            expect(Claimant.find_by(id: claimant.id)).to be_nil
          end

          context "when appeal claimant destroy fails" do
            before do
              allow(appeal).to receive(:claimant).and_return(claimant)
              expect(claimant).to receive(:destroy!).and_raise(StandardError)
            end

            it "does not update appeal" do
              expect { run_appellant_change }.not_to change { appeal.attributes }
            end

            it "does not create new claimant for appeal" do
              expect { run_appellant_change }.not_to change { Claimant.count }
            end

            it 'ouputs an error message' do
              expect { run_appellant_change }.to output(
                "StandardError\n\n\nAn error occurred. Appeal claimant not changed.\n"
              ).to_stdout
            end
          end

          context "when claimant_type is 'VeteranClaimant'" do
            let(:arguments) { valid_params.merge(claimant_type: "VeteranClaimant") }
            let!(:appeal) { create(:appeal, veteran_is_not_claimant: true) }

            it "updates the appeal 'veteran_is_not_claimant' attribute to false" do
              run_appellant_change
              expect(appeal.reload.veteran_is_not_claimant).to eq(false)
            end
          end

          context "when claimant_type is not 'VeteranClaimant" do
            let(:arguments) { valid_params.merge(claimant_type: "AttorneyClaimant") }
            let!(:appeal) { create(:appeal, veteran_is_not_claimant: false) }

            it "updates the appeal 'veteran_is_not_claimant' attribute" do
              run_appellant_change
              expect(appeal.reload.veteran_is_not_claimant).to eq(true)
            end
          end

          context "when appeal update fails" do
            before do
              expect(appeal).to receive(:update!).and_raise(StandardError)
            end

            it "it rolls back destroy of original appeal claimant" do
              expect(Claimant.find_by(id: claimant.id)).not_to be_nil
              run_appellant_change
              expect(Claimant.find_by(id: claimant.id)).not_to be_nil
            end
          end

          it "creates new claimant for appeal" do
            run_appellant_change
            new_claimant = Claimant.last

            expect(new_claimant.attributes.symbolize_keys).to include(
              participant_id: valid_params[:claimant_participant_id],
              payee_code: valid_params[:claimant_payee_code],
              type: valid_params[:claimant_type],
              decision_review_id: appeal.id,
              decision_review_type: "Appeal"
            )
          end

          context "when claimant create fails" do
            before do
              expect(Claimant).to receive(:create!).and_raise(StandardError)
            end

            it "rolls back update to appeal" do
              original_claimant_attributes = appeal.claimant.attributes
              run_appellant_change
              expect(appeal.claimant.reload.attributes).to include(original_claimant_attributes)
            end

            it 'ouputs an error message' do
              expect { run_appellant_change }.to output(
                "StandardError\n\n\nAn error occurred. Appeal claimant not changed.\n"
              ).to_stdout
            end
          end
        end
      end
    end
  end
end
