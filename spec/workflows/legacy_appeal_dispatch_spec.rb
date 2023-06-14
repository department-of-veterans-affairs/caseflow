# frozen_string_literal: true

describe LegacyAppealDispatch do
  describe "#call" do
    let(:user) { create(:user) }
    let(:legacy_appeal) do
      create(:legacy_appeal,
             vacols_case: create(:case, :aod, :type_cavc_remand, bfregoff: "RO13",
                                                                 folder: create(:folder, tinum: "13 11-265")))
    end
    let(:root_task) { create(:root_task, appeal: legacy_appeal) }
    let(:params) do
      { appeal_id: legacy_appeal.id,
        citation_number: "A18123456",
        decision_date: Time.zone.today,
        redacted_document_location: "some/filepath",
        file: "some file" }
    end

    before do
      BvaDispatch.singleton.add_user(user)
      BvaDispatchTask.create_from_root_task(root_task)
    end

    subject { LegacyAppealDispatch.new(appeal: legacy_appeal, params: params) }

    context "valid parameters" do
      it "successfully outcodes dispatch" do
        expect(subject.call).to be_success
      end
    end

    context "invalid citation number" do
      it "returns an object with validation errors" do
        params[:citation_number] = "123"
        expect(subject.call).to_not be_success
        expect(subject.call.errors[0]).to eq "Citation number is invalid"
      end
    end

    context "citation number already exists" do
      it "returns an object with validation errors" do
        allow(subject).to receive(:unique_citation_number?).and_return(false)
        expect(subject.call).to_not be_success
        expect(subject.call.errors[0]).to eq "Citation number already exists"
      end
    end

    context "missing required parameters" do
      it "returns an object with validation errors" do
        params[:decision_date] = nil
        params[:redacted_document_location] = nil
        params[:file] = nil

        error_message = "Decision date can't be blank, Redacted document " \
                        "location can't be blank, File can't be blank"

        expect(subject.call).to_not be_success
        expect(subject.call.errors[0]).to eq error_message
      end
    end
  end
end
