# frozen_string_literal: true

FactoryBot.define do
  factory :nod_date_update do
    appeal { create(:appeal) }
    user { create(:user) }
    old_date { 1.month.ago }
    new_date { 7.days.ago }
    change_reason { :new_info }
  end
end
