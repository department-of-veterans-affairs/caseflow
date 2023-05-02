# frozen_string_literal: true

RSpec.shared_examples_for "verify_user_can_create" do
  describe ".verify_user_can_create" do
    let(:params) { { appeal: root_task.appeal, parent_id: distribution_task_id, type: task_class.name } }
    let(:distribution_task_id) { distribution_task.id }

    context "when no distribution_task exists for appeal" do
      let(:distribution_task_id) { nil }

      it "throws an error" do
        expect { task_class.create_from_params(params, user) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
