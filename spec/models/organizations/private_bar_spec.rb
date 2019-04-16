# frozen_string_literal: true

describe PrivateBar do
  describe ".create_for_user" do
    let(:user_name) { "Mariano Rivera" }
    let(:css_id) { "VACORIVEM" }
    let(:user) { FactoryBot.create(:user, full_name: user_name, css_id: css_id) }
    let(:participant_id) { 1_234_567 }

    before do
      allow_any_instance_of(BGSService).to receive(:get_participant_id_for_user).and_return(participant_id)
    end

    subject { PrivateBar.create_for_user(user) }

    context "when the user has a participant_id" do
      it "creates the organization with one user" do
        org = subject

        expect(org.name).to eq(user_name)
        expect(org.url).to eq(css_id.downcase)
        expect(org.participant_id).to eq(participant_id.to_s)

        expect(org.users.length).to eq(1)
        expect(org.users.first).to eq(user)
      end
    end
  end

  describe ".for_user" do
    let(:user) { FactoryBot.create(:user) }

    subject { PrivateBar.for_user(user) }

    context "when a PrivateBar organization exists for the user" do
      let(:private_bar) { FactoryBot.create(:private_bar) }

      before do
        OrganizationsUser.add_user_to_organization(user, private_bar)
      end

      it "returns the PrivateBar organization that this user belongs to" do
        expect(subject).to eq(private_bar)
      end
    end

    context "when a PrivateBar organization does not exist for the user" do
      it "returns nil" do
        expect(subject).to eq(nil)
      end
    end
  end

  describe ".should_write_ihp?" do
    let(:rep) { FactoryBot.create(:private_bar) }
    let(:docket) { nil }
    let(:appeal) { FactoryBot.create(:appeal, docket_type: docket) }

    before { allow_any_instance_of(Appeal).to receive(:vsos).and_return(poas) }

    subject { rep.should_write_ihp?(appeal) }

    context "when there is no vso_configs record for this PrivateBar" do
      context "when PrivateBar represents the appellant" do
        let(:poas) { [rep] }

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

      context "when PrivateBar does not represent the appellant" do
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
