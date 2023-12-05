# frozen_string_literal: true

describe HearingRequestMailTask, :postgres do
  let(:user) { create(:user) }
  let(:root_task) { create(:root_task) }

  describe ".create" do
    let(:params) { { appeal: root_task.appeal, parent: root_task, assigned_to: user } }

    it "throws an error" do
      expect { described_class.create!(params) }.to raise_error(Caseflow::Error::InvalidTaskTypeOnTaskCreate)
    end
  end
end
