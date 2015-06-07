require 'active_support'
require 'active_support/core_ext/hash/conversions'
require 'active_support/core_ext/hash/indifferent_access'
require 'xmlrpc/client'
require 'nokogiri'

module Selcom
  include ActiveSupport::Configurable
  class MalformedRequestError < StandardError
  end

  class SendMoney
    attr_accessor(
      :amount,        :status,
      :success,       :telco_id,
      :response,      :reference,
      :status_code,   :customer_name,
      :mobile_number, :status_description
    )

    XMLRPC_URI            = "https://paypoint.selcommobile.com/api/selcom.pos.server.php"
    XMLRPC_METHOD         = 'SELCOM.utilityPayment'

    SELCOM_UTILITY_CODES  = {
      :airtel_tz  => 'AMCASHIN',
      :tigo_tz    => 'TPCASHIN',
      :vodacom_tz => 'VMCASHIN',
      :zantel_tz  => 'EZCASHIN'
    }
    NUMBER_PREFIXES = {
      '068'       => :airtel_tz,
      '078'       => :airtel_tz,
      '065'       => :tigo_tz,
      '071'       => :tigo_tz,
      '075'       => :vodacom_tz,
      '076'       => :vodacom_tz,
      '077'       => :zantel_tz
    }

    def initialize(args)
      self.telco_id       = args[:telco_id]
      self.mobile_number  = args[:mobile_number]
      self.amount         = args[:amount]
    end

    def send!
      self.response = make_rpc(self.to_params)
      parse_response(response)

      return self.success
    end

    def to_params
      return HashWithIndifferentAccess.new(
        :amount         => self.amount,
        :mobile_number  => self.mobile_number,
        :telco_id       => self.telco_id,
        :vendor_id      => Selcom.config.vendor_id,
        :vendor_pin     => Selcom.config.vendor_pin
      )
    end

    private

    def make_rpc(args)
      request_params  = create_request_params(args)
      xmlrpc_client   = create_rpc_client()
      xml_response    = call_rpc_server(xmlrpc_client, request_params)

      return parse_xml_into_hash(xml_response)
    end

    def parse_response(response)
      self.reference          = response[:reference]
      self.status             = response[:result]
      self.status_code        = response[:resultcode]
      self.status_description = response[:message]
      self.success            = ('SUCCESS' == self.status)
    end

    def create_request_params(args)
      amount            = args["amount"]
      receipient_number = args["mobile_number"]
      telco_id          = NUMBER_PREFIXES[receipient_number[0..2]] || :vodacom_tz
      utility_code      = SELCOM_UTILITY_CODES[telco_id]
      unique_token      = SecureRandom.urlsafe_base64(nil, false)

      return {
        "vendor"      => Selcom.config.vendor_id,
        "pin"         => Selcom.config.vendor_pin,
        "utilitycode" => utility_code,
        "utilityref"  => receipient_number,
        "amount"      => amount,
        "transid"     => unique_token,
        "msisdn"      => receipient_number
      }
    end

    def parse_xml_into_hash(xml_from_rpc)
      xml = extract_xml(xml_from_rpc)

      return convert_xml_to_hash(xml)
    end

    def extract_xml(xml_rpc_response)
      xml_doc = Nokogiri::XML(xml_rpc_response)
      xml_doc_content = xml_doc.xpath('/methodResponse/params/param/value/struct')

      return xml_doc_content.to_xml
    end

    def convert_xml_to_hash(xml)
      content_hash  = Hash.from_xml(xml)
      resultHash    = HashWithIndifferentAccess.new
      if content_hash
        content_hash['struct']['member'].map {|member|
          result.store(
            member['name'], member['value'].first[1]
          )
        }
        end

      return resultHash
    end

    def create_rpc_client()
      client     = XMLRPC::Client.new2(XMLRPC_URI)
      client.http_header_extra = {
        'Content-Type'  => 'text/xml; charset=utf-8',
        'Accept'        => 'text/html'
      }

      return client
    end

    def call_rpc_server(xmlrpc_client, request_params)
      # make call to xmlrpc server at selcom
      begin
        xmlrpc_client.call(XMLRPC_METHOD, request_params)
      rescue RuntimeError => e
        raise MalformedRequestError, (
          "Invalid request parameters: #{request_params.inspect}"
        )
      end

      return xmlrpc_client.http_last_response.body
    end
  end
end
