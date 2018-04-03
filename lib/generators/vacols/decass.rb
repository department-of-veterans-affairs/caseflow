class Generators::Vacols::Decass

    class << self

        def decass_attrs
            {
              
            }
        end


        def create(attrs = {})
            decass_attrs.merge(attrs)

            VACOLS::Decass.create(decass_attrs)
        end


    end

end