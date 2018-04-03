class Generators::Vacols::Staff

    class << self

        def staff_attrs
            {
              
            }
        end


        def create(attrs = {})
            staff_attrs.merge(attrs)

            VACOLS::Staff.create(staff_attrs)
        end


    end

end