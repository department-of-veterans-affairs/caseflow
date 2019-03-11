# frozen_string_literal: true

class Generators::Vacols::Folder
  class << self
    # rubocop:disable Metrics/MethodLength
    def folder_attrs
      {
        ticknum: "877483",
        ticorkey: "CK168505",
        tistkey: "CRUSSEL",
        tinum: "8927941",
        tifiloc: "A",
        tiaddrto: nil,
        titrnum: "626343664S",
        ticukey: nil,
        tidsnt: nil,
        tidrecv: "2017-06-13 00:00:00 UTC",
        tiddue: nil,
        tidcls: "2017-11-28 00:00:00 UTC",
        tiwpptr: "Mollitia hic quia incidunt blanditiis quam ut facilis.",
        tiwpptrt: nil,
        tiaduser: nil,
        tiadtime: "2017-04-24 00:00:00 UTC",
        timduser: "FBEAHAN",
        timdtime: "2017-11-28 00:00:00 UTC",
        ticlstme: nil,
        tiresp1: "RO72",
        tikeywrd: "REMAND",
        tiactive: nil,
        tispare1: nil,
        tispare2: nil,
        tispare3: nil,
        tiread1: nil,
        tiread2: "5371173",
        timt: nil,
        tisubj1: nil,
        tisubj: nil,
        tisubj2: nil,
        tisys: nil,
        tiagor: nil,
        tiasbt: nil,
        tigwui: nil,
        tihepc: nil,
        tiaids: nil,
        timgas: nil,
        tiptsd: nil,
        tiradb: nil,
        tiradn: nil,
        tisarc: nil,
        tisexh: nil,
        titoba: nil,
        tinosc: "Y",
        ti38us: nil,
        tinnme: nil,
        tinwgr: nil,
        tipres: nil,
        titrtm: nil,
        tinoot: nil,
        tioctime: "2017-11-28 00:00:00 UTC",
        tiocuser: "FBEAHAN",
        tidktime: "2017-06-13 00:00:00 UTC",
        tidkuser: "CVON1",
        tipulac: nil,
        ticerullo: nil,
        tiplnod: nil,
        tiplwaiver: nil,
        tiplexpress: nil,
        tisnl: nil,
        tivbms: "Y",
        ticlcw: nil
      }
    end
    # rubocop:enable Metrics/MethodLength

    def create(attrs = {})
      attrs = folder_attrs.merge(attrs)
      VACOLS::Folder.create(attrs)
    end
  end
end
