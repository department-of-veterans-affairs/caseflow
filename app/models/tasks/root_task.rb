class RootTask < Task
  def self.create!(appeal)
    super({ appeal_id: appeal.id, appeal_type: appeal.class.name, assigned_to_type: "BVA" })
  end

  private

  def skip_assigned_to_validation
    true
  end
end
