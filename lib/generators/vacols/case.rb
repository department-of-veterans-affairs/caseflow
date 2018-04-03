class Generators::Vacols::Case

    class << self

        def case_attrs
            {
              bfkey: 2226048,
              bfddec: "",
              bfcorkey: "CK940968",
              bfcorlid: "213912991S",
              bfdcn: ""
            }
        end


        def create(attrs = {})
            case_attrs.merge(attrs)
            binding.pry
            VACOLS::Case.create(case_attrs)
        end


    end

end