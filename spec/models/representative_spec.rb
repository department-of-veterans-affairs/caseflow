# frozen_string_literal: true

describe Representative, :postgres do
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
      vso = Representative.create!(name: "Veterans' Service Org", url: "veterans-service-org")
      expect(vso.role).to eq("VSO")
    end
  end

  context "#user_has_access?" do
    before do
      stub_const("BGSService", ExternalApi::BGSService)
      RequestStore[:current_user] = user

      allow_any_instance_of(BGS::SecurityWebService).to receive(:find_participant_id)
        .with(css_id: user.css_id, station_id: user.station_id).and_return(participant_id)
      allow_any_instance_of(BGS::OrgWebService).to receive(:find_poas_by_ptcpnt_id)
        .with(participant_id).and_return(vso_participant_ids)
    end

    subject { vso.user_has_access?(user) }

    context "when the users participant_id is associated with this VSO" do
      it "returns true" do
        is_expected.to be_truthy
      end
    end

    context "when the users participant_id is associated with a different VSO" do
      let(:vso) do
        Representative.create(
          participant_id: "999"
        )
      end

      it "returns false" do
        is_expected.to be_falsey
      end
    end

    context "when the users participant_id is associated with no VSOs" do
      let(:vso_participant_ids) { [] }

      it "returns false" do
        is_expected.to be_falsey
      end
    end

    context "when the user does not have the VSO role" do
      let(:user) do
        create(:user, roles: ["Other Role"])
      end

      it "returns false" do
        is_expected.to be_falsey
      end
    end
  end

  describe ".should_write_ihp?" do
    let(:docket) { nil }
    let(:appeal) { create(:appeal, docket_type: docket) }

    before { allow_any_instance_of(Appeal).to receive(:representatives).and_return(poas) }

    subject { vso.should_write_ihp?(appeal) }

    context "when there is no vso_configs record for this VSO" do
      context "when VSO represents the appellant" do
        let(:poas) { [vso] }

        context "when the appeal is on the direct_review docket" do
          let(:docket) { Constants.AMA_DOCKETS.direct_review }
          it "should return true because the default set of dockets to write IHPs include direct_review" do
            expect(subject).to eq(true)
          end
        end

        context "when the appeal is on the evidence_submission docket" do
          let(:docket) { Constants.AMA_DOCKETS.evidence_submission }
          it "should return true because the default set of dockets to write IHPs include evidence_submission" do
            expect(subject).to eq(true)
          end
        end

        context "when the appeal is on the hearing docket" do
          let(:docket) { Constants.AMA_DOCKETS.hearing }
          it "should return false because the default set of dockets to write IHPs does not include hearing" do
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

  describe ".queue_tabs" do
    it "returns the expected 4 tabs" do
      expect(vso.queue_tabs.map(&:class)).to eq(
        [
          OrganizationTrackingTasksTab,
          OrganizationUnassignedTasksTab,
          OrganizationAssignedTasksTab,
          OrganizationCompletedTasksTab
        ]
      )
    end
  end
end
