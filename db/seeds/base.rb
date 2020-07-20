# frozen_string_literal: true

# abstract base class for all Seed:: classes.
# inherit from this class for common util methods that (currently)
# wrap around FactoryBot

module Seeds
  class Base
    private

    def create(*args)
      FactoryBot.create(*args)
    end

    def build(*args)
      FactoryBot.build(*args)
    end

    def create_list(*args)
      FactoryBot.create_list(*args)
    end
  end
end
