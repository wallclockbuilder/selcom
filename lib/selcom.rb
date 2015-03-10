require 'active_support'
require 'active_support/core_ext/hash/indifferent_access.rb'
require 'xmlrpc/client'
require 'nokogiri'

module Selcom
	include ActiveSupport::Configurable
	class MalformedRequestError < StandardError
	end

	class SendMoney
		attr_accessor :telco_id, :mobile_number, :amount,
		:response, :reference, :success, :customer_name, :status, :status_description, :status_code

		XMLRPC_URI 				= "https://paypoint.selcommobile.com/api/selcom.pos.server.php"
		XMLRPC_METHOD 			= 'SELCOM.utilityPayment'
		AIRTEL_UTILITY_CODE 	= 'AMCASHIN'
		TIGOPESA_UTILITY_CODE 	= 'TPCASHIN'
		MPESA_UTILITY_CODE 		= 'VMCASHIN'
		EZYPESA_UTILITY_CODE 	= 'EZCASHIN'
		SELCOM_UTILITY_CODES = {
			:airtel_tz => 'AMCASHIN',
			:tigo_tz => 'TPCASHIN',
			:vodacom_tz => 'VMCASHIN',
			:zantel_tz => 'EZCASHIN'
		}

		def initialize(args)
			self.telco_id 			= args[:telco_id]
			self.mobile_number 		= args[:mobile_number]
			self.amount 			= args[:amount]
		end

		def send!

			self.response 			= HashWithIndifferentAccess.new(connection(self.to_params).body)
			self.reference 			= self.response[:reference]
			self.status 			= self.response[:result]
			self.status_code 		= self.response[:resultcode]
			self.status_description = self.response[:message]
			self.success 			= 'SUCCESS' == self.status
			return self.success
		end

		def to_params
			HashWithIndifferentAccess.new(
				:amount => self.amount,
				:mobile_number => self.mobile_number,
				:telco_id => self.telco_id,
				:vendor_id => Selcom.config.vendor_id,
				:vendor_pin => Selcom.config.vendor_pin
			)
		end

		def connection(args)
			amount = args["amount"]
			receipient_number = args["mobile_number"]
			telco_id = args["telco_id"]
			unique_token = SecureRandom.urlsafe_base64(nil, false)
			#Make call to xmlrpc server at selcom
			xmlrpc_server=XMLRPC::Client.new2(XMLRPC_URI)
			request_params = {
				"vendor" => Selcom.config.vendor_id,
				"pin" => Selcom.config.vendor_pin,
				"utilitycode" => telco_id,
				 "utilityref" => receipient_number,
				 "amount" => amount,
				 "transid" => unique_token,
				 "msisdn" => receipient_number
			}
		 	 xmlrpc_server.http_header_extra = {
		 		                        'Content-Type' => 'text/xml; charset=utf-8',
		 		                        'Accept' => 'text/html'
		 		                }
		 	begin
				xmlrpc_server.call(XMLRPC_METHOD, request_params)
			rescue RuntimeError => e
				raise MalformedRequestError, (
					"Invalid request parameters: #{request_params.inspect}"
				)
			end
			xmlrpc_response = xmlrpc_server.http_last_response.body

			#Parse xml response into ruby object
			xml_doc = Nokogiri::XML(xmlrpc_response)
			xml_doc_content = xml_doc.xpath('/methodResponse/params/param/value/struct')
			content_hash = Hash.from_xml(xml_doc_content.to_xml)
			result = HashWithIndifferentAccess.new
			if content_hash
				content_hash['struct']['member'].map {|member|
				 	result.store(
				 		member['name'],
				 		member['value'].first[1]
				 	)
				 }
			end

			# TODO: There's probably some code that should be here.

			# Return response as ruby hash

			# response_hash = HashWithIndifferentAccess.new(
			# 	"body" => {
			# 		"transid" => "mwliid12345",
 		  # 			"reference" => "4655259721",
		  # 	 		"message" => "Airtel Money Cash-in",
		  # 	  		"resultcode" => "000",
		  # 	  		"result" => "FAIL"
			# 	}
			# )

			# response_hash = HashWithIndifferentAccess.new(
			# 	:body => result
			# 	)

		end
	end
end




