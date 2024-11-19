class AddAmaOnlyToOrganization < Caseflow::Migration
  def change
    add_column :organizations, :ama_only_push, :boolean, :default => false, comment: "whether a JudgeTeam should only get AMA appeals during the PushPriorityAppealsToJudgesJob"
    add_column :organizations, :ama_only_request, :boolean, :default => false, comment: "whether a JudgeTeam should only get AMA appeals when requesting more cases"
  end
end
