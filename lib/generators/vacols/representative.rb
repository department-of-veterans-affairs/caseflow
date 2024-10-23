# frozen_string_literal: true

class Generators::VACOLS::Representative
  class << self
    # rubocop:disable Metrics/MethodLength
    def representative_attrs
      {
        repkey: "877483",
        repaddtime: "2017-10-13 06:51:24 UTC",
        reptype: nil,
        repso: nil,
        replast: "Runte",
        repfirst: "Trevion",
        repmi: "Y",
        repsuf: "DVM",
        repaddr1: "5446 Grady Garden",
        repaddr2: "Apt. 636",
        repcity: "New Otha",
        repst: "OH",
        repzip: "90467",
        repphone: "277-060-6791 x14708",
        repnotes: nil,
        repmoduser: nil,
        repmodtime: nil,
        repdirpay: nil,
        repdfee: nil,
        repfeerecv: nil,
        replastdoc: nil,
        repfeedisp: nil,
        repcorkey: nil,
        repacknw: nil
      }
    end
    # rubocop:enable Metrics/MethodLength

    def create(attrs = {})
      attrs = representative_attrs.merge(attrs)

      VACOLS::Representative.create(attrs)
    end
  end
end
