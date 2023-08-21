# frozen_string_literal: true

module Types
  class UserType < Types::BaseObject
    field :id, ID, null: false

    field :first_name, String, null: false do
      description "User's first name"
    end

    field :last_name, String, null: false do
      description "Users's last name"
    end

    def first_name
      name_arr = object.full_name&.split(" ")

      return name_arr.first if name_arr
    end

    def last_name
      name_arr = object.full_name&.split(" ")

      return name_arr.last if name_arr
    end
  end
end
