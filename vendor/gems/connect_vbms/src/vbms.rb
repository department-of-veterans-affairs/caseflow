#!/usr/bin/env ruby
require 'base64'
require 'benchmark'
require 'erb'
require 'httpclient'
require 'tempfile'
require 'uri'
require 'nokogiri'
require 'mail'

require 'vbms/common'
require 'vbms/client'
require 'vbms/version'
require 'vbms/requests'

require 'vbms/responses/document'
require 'vbms/responses/document_type'
require 'vbms/responses/document_with_content'

require 'vbms/requests/upload_document_with_associations'
require 'vbms/requests/list_documents'
require 'vbms/requests/fetch_document_by_id'
require 'vbms/requests/get_document_types'
