# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    field :hearing, Types::HearingType, null: false, description: "Returns a single AMA Hearing" do
      argument :id, ID, required: true
    end

    field :hearing_day, Types::HearingDayType, null: false do
      description "Hearing days groups hearings, both AMA and legacy, by a regional office and a room at the BVA."
      argument :id, ID, required: true
    end

    field :judge, Types::JudgeType, null: false, description: "A judge" do
      argument :id, ID, required: true
    end

    field :user, Types::UserType, null: false, description: "A user of Caseflow" do
      argument :id, ID, required: true
    end

    def hearing(id:)
      Hearing.find(id)
    end

    def hearing_day(id:)
      HearingDay.find(id)
    end

    def judge(id:)
      Judge.find(id)
    end

    def user(id:)
      User.find(id)
    end
  end
end
