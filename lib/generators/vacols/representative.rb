class Generators::Vacols::Representative

    class << self

        def representative_attrs
            {
              
            }
        end


        def create(attrs = {})
            representative_attrs.merge(attrs)

            VACOLS::Representative.create(representative_attrs)
        end


    end

end