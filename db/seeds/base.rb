module Seeds
  class Base
    private

    def create(*args)
      FactoryBot.create(*args)
    end

    def build(*args)
      FactoryBot.build(*args)
    end
  end
end
