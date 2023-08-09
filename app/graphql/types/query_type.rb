module Types
  class QueryType < Types::BaseObject
    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    field :hearing, Types::HearingType, null: false, description: "Returns a single AMA Hearing" do
      argument :id, ID, required: true
    end

    def hearing(id:)
      Hearing.find(id)
    end
  end
end
