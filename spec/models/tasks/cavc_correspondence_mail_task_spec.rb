# frozen_string_literal: true

describe CavcCorrespondenceMailTask do
  let(:mail_user) { create(:user) }
  let(:cavc_lit_user) { create(:user) }
  let(:root_task) { create(:root_task) }
  let(:cavc_task) { create(:cavc_task) }


  before do
    MailTeam.singleton.add_user(mail_user)
    CavcLitigationSupport.singleton.add_user(cavc_lit_user)
  end

  describe ".create_from_params" do
    let(:params) { { parent_id: root_task.id, instructions: "foo bar" } }

    subject { CavcCorrespondenceMailTask.create_from_params(params, mail_user) }

    before { RequestStore[:current_user] = mail_user }

    it "creates an org task each for Mail team and CAVC Lit Support" do
      expect(CavcCorrespondenceMailTask.all.size).to eq(0)
      subject
      expect(CavcCorrespondenceMailTask.where(assigned_to_type: "Organization").size).to eq(2)
      expect(CavcCorrespondenceMailTask.first.assigned_to).to eq(MailTeam.singleton)
      expect(CavcCorrespondenceMailTask.second.assigned_to).to eq(CavcLitigationSupport.singleton)
    end
  end
end
