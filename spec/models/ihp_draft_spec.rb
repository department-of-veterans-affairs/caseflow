# frozen_string_literal: true

describe IhpDraft do
  describe ".create!" do
    subject { IhpDraft.new(params) }

    let(:appeal) { create(:appeal) }
    let(:organization) { create(:organization) }
    let(:path) { "\\\\vacoappbva3.dva.va.gov\\DMDI$\\VBMS Paperless IHPs\\AML\\AMA IHPs\\VetName 12345.pdf" }
    let(:params) do
      {
        appeal: appeal,
        organization: organization,
        path: path
      }
    end

    context "when appeal is not specified" do
      let(:appeal) { nil }

      it "fails validation" do
        expect(subject.valid?).to be false
        expect(subject.errors.key?(:appeal)).to be true
      end
    end

    context "when organization is not specified" do
      let(:organization) { nil }

      it "fails validation" do
        expect(subject.valid?).to be false
        expect(subject.errors.key?(:organization)).to be true
      end
    end

    context "when path is not specified" do
      let(:path) { nil }

      it "fails validation" do
        expect(subject.valid?).to be false
        expect(subject.errors.key?(:path)).to be true
      end
    end

    context "when path is invalid" do
      shared_examples "invalid path" do
        it "fails path regex validation" do
          expect(subject.valid?).to be false
          expect(subject.errors.key?(:path)).to be true
          expect(subject.errors[:path].first).to eq COPY::INVALID_IHP_DRAFT_PATH
        end
      end

      context "due to the wrong extension" do
        let(:params) { { appeal: appeal, organization: organization, path: path.gsub(".pdf", ".wrong") } }

        it_behaves_like "invalid path"
      end

      context "due to the wrong appeal_type" do
        let(:params) { { appeal: appeal, organization: organization, path: path.gsub("AMA IHPs", "902") } }

        it_behaves_like "invalid path"
      end

      context "due to not containing the beginning of the path" do
        let(:path) { "AML\\AMA IHPs\\VetName 12345.pdf" }

        it_behaves_like "invalid path"
      end

      context "due to only stipulating the V drive" do
        let(:path) { "V:\\VBMS Paperless IHPs\\AML\\AMA IHPs\\VetName 12345.pdf" }

        it_behaves_like "invalid path"
      end
    end

    context "When all params are valid" do
      it "successfully creates the record" do
        expect(subject.valid?).to be true
        expect(subject.save!).to be true
      end
    end
  end

  context ".create_or_update_from_task!" do
    subject { IhpDraft.create_or_update_from_task!(task, path) }

    let(:organization) { create(:organization) }
    let(:user) { create(:user) }
    let(:appeal) { create(:appeal) }
    let(:root_task) { create(:task, appeal: appeal) }
    let(:org_task) { create(:task, assigned_to: organization, parent: root_task, appeal: appeal) }
    let(:user_task) { create(:task, assigned_to: user, parent: org_task, appeal: appeal) }
    let(:task) { org_task }
    let(:path) { "\\\\vacoappbva3.dva.va.gov\\DMDI$\\VBMS Paperless IHPs\\AML\\AMA IHPs\\VetName 12345.pdf" }

    context "when there is no existing record" do
      context "when the task is assigned to an organization" do
        it "creates a new record based on the task's assignee" do
          expect { subject }.to change(IhpDraft, :count).by(1)
          expect(subject.organization).to eq organization
        end
      end

      context "when the task is assigned to a user" do
        let(:task) { user_task }

        it "creates a new record based on the parent task's assignee" do
          expect { subject }.to change(IhpDraft, :count).by(1)
          expect(subject.organization).to eq organization
        end
      end

      context "when the provided path contains extra quotes from copy/paste" do
        let(:stripped_path) { "\\\\vacoappbva3.dva.va.gov\\DMDI$\\VBMS Paperless IHPs\\AML\\AMA IHPs\\VetName 123.pdf" }
        let(:path) { "\"\\\\vacoappbva3.dva.va.gov\\DMDI$\\VBMS Paperless IHPs\\AML\\AMA IHPs\\VetName 123.pdf\"" }

        it "strips the quotes before creating" do
          expect { subject }.to change(IhpDraft, :count).by(1)
          expect(subject.path).to eq stripped_path
        end
      end
    end

    context "when there is no existing record associated with the ihp writing vso" do
      let!(:existing_record) { IhpDraft.create!(appeal: appeal, organization: create(:organization), path: path) }

      it "creates a new record" do
        expect { subject }.to change(IhpDraft, :count).by(1)
        expect(subject).not_to eq existing_record
        expect(subject.organization).to eq organization
      end
    end

    context "when there is no existing record associated with the task's appeal" do
      let!(:existing_record) { IhpDraft.create!(appeal: create(:appeal), organization: organization, path: path) }

      it "creates a new record" do
        expect { subject }.to change(IhpDraft, :count).by(1)
        expect(subject).not_to eq existing_record
        expect(subject.appeal).to eq appeal
      end
    end

    context "when there is an existing record associated with the appeal and VSO" do
      let(:old_path) { "\\\\vacoappbva3.dva.va.gov\\DMDI$\\VBMS Paperless IHPs\\AML\\AMA IHPs\\VetName 12.pdf" }
      let!(:existing_record) { IhpDraft.create!(appeal: appeal, organization: organization, path: old_path) }

      it "updates the existing record" do
        expect { subject }.to change(IhpDraft, :count).by(0)
        expect(subject).to eq existing_record
        expect(subject.path).not_to eq old_path
      end
    end
  end
end
