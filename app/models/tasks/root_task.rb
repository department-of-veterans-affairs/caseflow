class RootTask < Task
  def self.create!(appeal)
    super({ appeal_id: appeal.id, appeal_type: appeal.class.name, assigned_to_type: "BVA" })
  end
end
