# frozen_string_literal: true

require_relative "services/person"

module MPI
  class Services
    class << self
      def all
        ObjectSpace.each_object(Class).select { |klass| klass < MPI::Base }
      end

      def register_services
        all.each do |service|
          define_method(service.service_name) do
            service.new @config
          end
        end
      end
    end

    # call register on init
    MPI::Services.register_services

    def initialize(ssl_cert_file:, ssl_cert_key_file:, ssl_ca_cert:,
                   env: nil, application: nil, log: false, logger: nil)
      @config = {
        env: env, application: application,
        ssl_cert_file: ssl_cert_file, ssl_cert_key_file: ssl_cert_key_file, ssl_ca_cert: ssl_ca_cert,
        log: log, logger: logger
      }
    end

    def application
      config[:application]
    end

    private

    attr_accessor :config
  end
end
