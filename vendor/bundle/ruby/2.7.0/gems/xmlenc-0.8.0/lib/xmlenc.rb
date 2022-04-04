require 'active_support/all'
require 'active_model'
require 'xmlenc/version'
require 'openssl'
require 'base64'
require 'nokogiri'

module Xmlenc
  NAMESPACES = {
      :xenc => 'http://www.w3.org/2001/04/xmlenc#',
      :ds =>   'http://www.w3.org/2000/09/xmldsig#'
  }

  class Error < StandardError; end
  class UnsupportedError < Error; end
  class UnparseableMessage < Error; end
  class EncryptedDataNotFound < Error; end

  module Builder
    autoload :Base, 'xmlenc/builder/base'
    autoload :EncryptedData, 'xmlenc/builder/encrypted_data'
    autoload :EncryptionMethod, 'xmlenc/builder/encryption_method'
    autoload :EncryptedKey, 'xmlenc/builder/encrypted_key'
    autoload :KeyInfo, 'xmlenc/builder/key_info'
    autoload :CipherData, 'xmlenc/builder/cipher_data'
    autoload :DigestMethod, 'xmlenc/builder/digest_method'
    autoload :ReferenceList, 'xmlenc/builder/reference_list'
    autoload :DataReference, 'xmlenc/builder/data_reference'
    autoload :RetrievalMethod, 'xmlenc/builder/retrieval_method'

    module ComplexTypes
      autoload :EncryptedType, 'xmlenc/builder/complex_types/encrypted_type'
    end
  end

  module Algorithms
    autoload :RSA15, 'xmlenc/algorithms/rsa_15'
    autoload :RsaOaepMgf1p, 'xmlenc/algorithms/rsa_oaep_mgf1p'
    autoload :DES3CBC, 'xmlenc/algorithms/des3_cbc'
    autoload :AESCBC, 'xmlenc/algorithms/aes_cbc'
    autoload :AESGCM, 'xmlenc/algorithms/aes_gcm'
  end

  autoload :EncryptedDocument, 'xmlenc/encrypted_document'
  autoload :EncryptedData, 'xmlenc/encrypted_data'
  autoload :EncryptedKey, 'xmlenc/encrypted_key'
end
