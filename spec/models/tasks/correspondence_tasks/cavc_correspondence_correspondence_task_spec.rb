# frozen_string_literal: true

describe CavcCorrespondenceCorrespondenceTask, :postgres do
  let(:user) { create(:user) }
  let(:inbound_ops_team) { InboundOpsTeam.singleton }
  let(:correspondence) { create(:correspondence) }

  before do
    inbound_ops_team.add_user(user)
  end

  describe ".create_url" do
    let(:task) do
      CavcCorrespondenceCorrespondenceTask.create!(
        appeal_type: "correspondence",
        appeal: correspondence,
        parent_id: correspondence.root_task.id,
        assigned_to: user
      )
    end

    context "CAVC request directs to UUID" do
      it "routes user to correspondence details page" do
        expect(task.task_url).to eq(
          Constants.CORRESPONDENCE_TASK_URL.CORRESPONDENCE_TASK_DETAIL_URL.sub("uuid", correspondence.uuid)
        )
      end
    end

    context "CAVC Request Mail Task Label" do
      it "displays CAVC label" do
        expect(task.label).to eq(
          COPY::CAVC_CORRESPONDENCE_MAIL_TASK_LABEL
        )
      end
    end
  end
end
