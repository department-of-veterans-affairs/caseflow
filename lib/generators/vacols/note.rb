class Generators::Vacols::Note

    class << self

        def note_attrs
            {
              
            }
        end


        def create(attrs = {})
            note_attrs.merge(attrs)

            VACOLS::Note.create(note_attrs)
        end


    end

end