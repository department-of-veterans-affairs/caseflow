class DependenciesReportService
  class << self
    ALL_DEPENDENCIES = ["BGS.FilenumberService", "BGS.PoaService", "VACOLS", "VBMS", "VBMS.FindDocumentSeriesReference", "VVA"].freeze

    # this method is in case we need list of dependencies/services that are degraded
    def degraded_dependencies
      str_report = Rails.cache.read(:dependencies_report)
      str_report = '{"BGS.FilenumberService":{"name":"BGS.FilenumberService","env":"beplinktest","time":"2017-11-02T16:31:31.427+00:00","latency":0.6070428639650345,"service":"Person","api":"findPersonByFileNumber","pass":true,"count":15768,"up_rate_5":10.0,"failed_rate_5":1.0e-323,"latency10":0.7424237120057612,"latency60":0.7463230764975536},"BGS.PoaService":{"name":"BGS.PoaService","env":"beplinktest","time":"2017-11-02T16:31:35.930+00:00","latency":0.5509214529884048,"service":"Organization","api":"findPOAsByFileNumbers","pass":true,"count":15826,"up_rate_5":100.0,"failed_rate_5":1.0e-323,"latency10":0.6023662259053334,"latency60":0.614808419636719},"VACOLS":{"name":"VACOLS","env":"vacols.dev.vaco.va.gov","time":"2017-11-02T16:31:49.999+00:00","latency":0.7839521379792131,"service":"VACOLS","api":"ASH","pass":true,"count":15721,"up_rate_5":100.0,"failed_rate_5":1.0e-323,"latency10":0.8248258550164462,"latency60":0.8426215020370702},"VBMS":{"name":"VBMS","env":"uat","time":"2017-11-02T16:31:43.862+00:00","latency":1.2075261889840476,"service":"VBMS","api":"ListDocuments","pass":true,"count":15599,"up_rate_5":100.0,"failed_rate_5":8.646297768313375e-137,"latency10":0.9143511784518592,"latency60":0.9265571139497507},"VBMS.FindDocumentSeriesReference":{"name":"VBMS.FindDocumentSeriesReference","env":"uat","time":"2017-11-02T16:31:28.845+00:00","latency":7.612880339031108,"service":"VBMS","api":"FindDocumentSeriesReference","pass":true,"count":15068,"up_rate_5":100.0,"failed_rate_5":3.8890735318943286e-132,"latency10":2.58603551007831,"latency60":2.0012011762271866},"VVA":{"name":"VVA","env":"test","time":"2017-11-02T16:31:32.565+00:00","latency":2.3558739970321767,"service":"DocumentList","api":"GetDocumentList","pass":true,"count":15148,"up_rate_5":100.0,"failed_rate_5":1.0e-323,"latency10":2.116551377936952,"latency60":2.161831437094918}}'
      return [] if !str_report
      report = JSON.parse str_report
      report.values.each_with_object([]) do |element, result|
        result << element["name"] if element["up_rate_5"].to_i < 50
      end
    end

    def dependencies_report
      case Rails.cache.read(:degraded_service_banner)
      when :always_show
        return ALL_DEPENDENCIES
      when :never_show
        return []
      end
      degraded_dependencies
    rescue => error
      Rails.logger.warn "Exception thrown while checking dependency "\
        "status: #{error}"
      false
    end
  end
end
