FactoryBot.define do
  factory :task do
    assigned_at 2.days.ago
    assigned_by { create(:user) }
    assigned_to { create(:user) }
    appeal { create(:legacy_appeal, vacols_case: create(:case)) }

    factory :colocated_admin_action do
      type "CoLocatedAdminAction"
      title "poa_clarification"
      instructions "poa is missing"

      after(:create) do |task, _evaluator|
        create(:staff, :attorney_role, sdomainid: task.assigned_by.css_id)
      end
    end
  end
end
