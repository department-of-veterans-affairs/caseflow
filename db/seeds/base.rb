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
