require 'nokogiri'
require 'openssl'

module Akami
  class WSSE
    class InvalidSignature < RuntimeError; end

    # Validating WSSE signed messages.
    class VerifySignature
      include Akami::C14nHelper

      class InvalidDigest < RuntimeError; end
      class InvalidSignedValue < RuntimeError; end

      attr_reader :document

      def initialize(xml)
        @document = Nokogiri::XML(xml.to_s, &:noblanks)
      end

      # Returns XML namespaces that are used internally for document querying.
      def namespaces
        @namespaces ||= {
          wse: Akami::WSSE::WSE_NAMESPACE,
          ds:  'http://www.w3.org/2000/09/xmldsig#',
          wsu: Akami::WSSE::WSU_NAMESPACE,
        }
      end

      # Allows to replace used XML namespaces if anyone will ever need. +hash+ should be a +Hash+ with symbol keys +:wse+, +:ds+, and +:wsu+.
      attr_writer :namespaces

      # Returns signer's certificate, bundled in signed document
      def certificate
        certificate_value = document.at_xpath('//wse:Security/wse:BinarySecurityToken', namespaces).text.strip
        OpenSSL::X509::Certificate.new Base64.decode64(certificate_value)
      end

      # Validates document signature, returns +true+ on success, +false+ otherwise.
      def valid?
        verify
      rescue InvalidDigest, InvalidSignedValue
        return false
      end

      # Validates document signature and digests and raises if anything mismatches.
      def verify!
        verify
      rescue InvalidDigest, InvalidSignedValue => e
        raise InvalidSignature, e.message
      end

      # Returns a hash with currently initialized digesters.
      #
      # Will be empty after initialization, and will contain used algorithms after verification.
      #
      # May be used to insert additional digesters, not supported out of the box, for example:
      #
      #   digesters['http://www.w3.org/2001/04/xmldsig-more#rsa-sha512'] = OpenSSL::Digest::SHA512.new

      def digesters
        @digesters
      end

      private

      def verify
        document.xpath('//wse:Security/ds:Signature/ds:SignedInfo/ds:Reference', namespaces).each do |ref|
          digest_algorithm = ref.at_xpath('//ds:DigestMethod', namespaces)['Algorithm']
          element_id = ref.attributes['URI'].value[1..-1] # strip leading '#'
          element = document.at_xpath(%(//*[@wsu:Id="#{element_id}"]), namespaces)
          unless supplied_digest(element) == generate_digest(element, digest_algorithm)
            raise InvalidDigest, "Invalid Digest for #{element_id}"
          end
        end

        data = canonicalize(signed_info)
        signature = Base64.decode64(signature_value)
        signature_algorithm = document.at_xpath('//wse:Security/ds:Signature/ds:SignedInfo/ds:SignatureMethod', namespaces)['Algorithm']
        signature_digester = digester_for_signature_method(signature_algorithm)

        certificate.public_key.verify(signature_digester, signature, data) or raise InvalidSignedValue, "Could not verify the signature value"
      end

      def signed_info
        document.at_xpath('//wse:Security/ds:Signature/ds:SignedInfo', namespaces)
      end

      # Generate digest for a given +element+ (or its XPath) with a given +algorithm+
      def generate_digest(element, algorithm)
        element = document.at_xpath(element, namespaces) if element.is_a? String
        xml = canonicalize(element)
        digest(xml, algorithm).strip
      end

      def supplied_digest(element)
        element = document.at_xpath(element, namespaces) if element.is_a? String
        find_digest_value element.attributes['Id'].value
      end

      def signature_value
        element = document.at_xpath('//wse:Security/ds:Signature/ds:SignatureValue', namespaces)
        element ? element.text : ""
      end

      def find_digest_value(id)
        document.at_xpath(%(//wse:Security/ds:Signature/ds:SignedInfo/ds:Reference[@URI="##{id}"]/ds:DigestValue), namespaces).text
      end

      # Calculate digest for string with given algorithm URL and Base64 encodes it.
      def digest(string, algorithm)
        Base64.encode64 digester(algorithm).digest(string)
      end

      # Returns digester for calculating digest for signature verification
      def digester_for_signature_method(algorithm_url)
        signature_digest_mapping = {
          'http://www.w3.org/2000/09/xmldsig#rsa-sha1' => 'http://www.w3.org/2000/09/xmldsig#sha1',
          'http://www.w3.org/2001/04/xmldsig-more#gostr34102001-gostr3411' => 'http://www.w3.org/2001/04/xmldsig-more#gostr3411',
        }
        digest_url = signature_digest_mapping[algorithm_url] || algorithm_url
        digester(digest_url)
      end

      # Constructors for known digest calculating objects
      DIGESTERS = {
          # SHA1
          'http://www.w3.org/2000/09/xmldsig#sha1' => lambda { OpenSSL::Digest::SHA1.new },
          # SHA 256
          'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256' => lambda { OpenSSL::Digest::SHA256.new },
          # GOST R 34.11-94
          # You need correctly configured gost engine in your system OpenSSL, requires OpenSSL >= 1.0.0
          # see https://github.com/openssl/openssl/blob/master/engines/ccgost/README.gost
          'http://www.w3.org/2001/04/xmldsig-more#gostr3411' => lambda {
            if defined? JRUBY_VERSION
              OpenSSL::Digest.new('GOST3411')
            else
              OpenSSL::Engine.load
              gost_engine = OpenSSL::Engine.by_id('gost')
              gost_engine.set_default(0xFFFF)
              gost_engine.digest('md_gost94')
            end
          },
      }

      # Returns instance of +OpenSSL::Digest+ class, initialized, reset, and ready to calculate new hashes.
      def digester(url)
        @digesters ||= {}
        unless @digesters[url]
          DIGESTERS[url] or raise InvalidDigest, "Digest algorithm not supported: #{url}"
          @digesters[url] = DIGESTERS[url].call
        end
        @digesters[url].reset
      end

    end
  end
end
