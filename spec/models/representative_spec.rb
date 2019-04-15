# frozen_string_literal: true

describe Representative do
  let(:participant_id) { "123456" }
  let(:vso_participant_id) { "789" }

  let(:vso) do
    Representative.create(
      participant_id: vso_participant_id
    )
  end

  let(:user) do
    create(:user, roles: ["VSO"])
  end

  let(:vso_participant_ids) do
    [
      {
        legacy_poa_cd: "070",
        nm: "VIETNAM VETERANS OF AMERICA",
        org_type_nm: "POA National Organization",
        ptcpnt_id: vso_participant_id
      },
      {
        legacy_poa_cd: "071",
        nm: "PARALYZED VETERANS OF AMERICA, INC.",
        org_type_nm: "POA National Organization",
        ptcpnt_id: "2452383"
      }
    ]
  end

  describe ".create!" do
    it "sets the role to VSO" do
      vso = Representative.create!(name: "Veterans' Service Org")
      expect(vso.role).to eq("VSO")
    end
  end

  describe ".should_write_ihp?" do
    let(:docket) { nil }
    let(:appeal) { FactoryBot.create(:appeal, docket_type: docket) }

    before { allow_any_instance_of(Appeal).to receive(:vsos).and_return(poas) }

    subject { vso.should_write_ihp?(appeal) }

    context "when there is no vso_configs record for this VSO" do
      context "when VSO represents the appellant" do
        let(:poas) { [vso] }

        context "when the appeal is on the direct_review docket" do
          let(:docket) { Constants.AMA_DOCKETS.direct_review }
          it "should return false because the default set of dockets to write IHPs is empty" do
            expect(subject).to eq(false)
          end
        end

        context "when the appeal is on the evidence_submission docket" do
          let(:docket) { Constants.AMA_DOCKETS.evidence_submission }
          it "should return false because the default set of dockets to write IHPs is empty" do
            expect(subject).to eq(false)
          end
        end

        context "when the appeal is on the hearing docket" do
          let(:docket) { Constants.AMA_DOCKETS.hearing }
          it "should return false because the default set of dockets to write IHPs is empty" do
            expect(subject).to eq(false)
          end
        end
      end

      context "when VSO does not represent the appellant" do
        let(:poas) { [] }

        context "when the appeal is on the direct_review docket" do
          let(:docket) { Constants.AMA_DOCKETS.direct_review }
          it "should return false for all docket types" do
            expect(subject).to eq(false)
          end
        end

        context "when the appeal is on the evidence_submission docket" do
          let(:docket) { Constants.AMA_DOCKETS.evidence_submission }
          it "should return false for all docket types" do
            expect(subject).to eq(false)
          end
        end

        context "when the appeal is on the hearing docket" do
          let(:docket) { Constants.AMA_DOCKETS.hearing }
          it "should return false for all docket types" do
            expect(subject).to eq(false)
          end
        end
      end
    end

    context "when vso_configs record for this VSO contains all 3 AMA docket types (PVA)" do
      before do
        VsoConfig.create(
          organization: vso,
          ihp_dockets: [
            Constants.AMA_DOCKETS.direct_review,
            Constants.AMA_DOCKETS.evidence_submission,
            Constants.AMA_DOCKETS.hearing
          ]
        )
      end

      context "when VSO represents the appellant" do
        let(:poas) { [vso] }

        context "when the appeal is on the direct_review docket" do
          let(:docket) { Constants.AMA_DOCKETS.direct_review }
          it "should return true because it is included in the vso_configs record" do
            expect(subject).to eq(true)
          end
        end

        context "when the appeal is on the evidence_submission docket" do
          let(:docket) { Constants.AMA_DOCKETS.evidence_submission }
          it "should return true because it is included in the vso_configs record" do
            expect(subject).to eq(true)
          end
        end

        context "when the appeal is on the hearing docket" do
          let(:docket) { Constants.AMA_DOCKETS.hearing }
          it "should return true because it is included in the vso_configs record" do
            expect(subject).to eq(true)
          end
        end
      end

      context "when VSO does not represent the appellant" do
        let(:poas) { [] }

        context "when the appeal is on the direct_review docket" do
          let(:docket) { Constants.AMA_DOCKETS.direct_review }
          it "should return false for all docket types" do
            expect(subject).to eq(false)
          end
        end

        context "when the appeal is on the evidence_submission docket" do
          let(:docket) { Constants.AMA_DOCKETS.evidence_submission }
          it "should return false for all docket types" do
            expect(subject).to eq(false)
          end
        end

        context "when the appeal is on the hearing docket" do
          let(:docket) { Constants.AMA_DOCKETS.hearing }
          it "should return false for all docket types" do
            expect(subject).to eq(false)
          end
        end
      end
    end

    context "when vso_configs record for this VSO doesn't contain any docket types" do
      before do
        VsoConfig.create(
          organization: vso,
          ihp_dockets: []
        )
      end

      context "when VSO represents the appellant" do
        let(:poas) { [vso] }

        context "when the appeal is on the direct_review docket" do
          let(:docket) { Constants.AMA_DOCKETS.direct_review }
          it "should return false because vso_configs record includes no docket types" do
            expect(subject).to eq(false)
          end
        end

        context "when the appeal is on the evidence_submission docket" do
          let(:docket) { Constants.AMA_DOCKETS.evidence_submission }
          it "should return false because vso_configs record includes no docket types" do
            expect(subject).to eq(false)
          end
        end

        context "when the appeal is on the hearing docket" do
          let(:docket) { Constants.AMA_DOCKETS.hearing }
          it "should return false because vso_configs record includes no docket types" do
            expect(subject).to eq(false)
          end
        end
      end

      context "when VSO does not represent the appellant" do
        let(:poas) { [] }

        context "when the appeal is on the direct_review docket" do
          let(:docket) { Constants.AMA_DOCKETS.direct_review }
          it "should return false for all docket types" do
            expect(subject).to eq(false)
          end
        end

        context "when the appeal is on the evidence_submission docket" do
          let(:docket) { Constants.AMA_DOCKETS.evidence_submission }
          it "should return false for all docket types" do
            expect(subject).to eq(false)
          end
        end

        context "when the appeal is on the hearing docket" do
          let(:docket) { Constants.AMA_DOCKETS.hearing }
          it "should return false for all docket types" do
            expect(subject).to eq(false)
          end
        end
      end
    end
  end
end
