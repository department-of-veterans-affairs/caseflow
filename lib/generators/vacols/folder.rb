class Generators::Vacols::Folder

    class << self

        def folder_attrs
            {
              
            }
        end


        def create(attrs = {})
            folder_attrs.merge(attrs)

            VACOLS::Folder.create(folder_attrs)
        end


    end

end