class Generators::Vacols::Correspondent

    class << self

        def correspondent_attrs
            {
              
            }
        end


        def create(attrs = {})
            correspondent_attrs.merge(attrs)

            VACOLS::Correspondent.create(correspondent_attrs)
        end


    end

end