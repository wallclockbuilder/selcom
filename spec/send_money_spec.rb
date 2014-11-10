require 'Selcom'


describe Selcom::SendMoney do
	subject { 
		Selcom::SendMoney.new({
			mobile_number: '+255701234567',
			amount: '543',
			vendor_id: 'abc'
		})
	}

	it { expect(subject.vendor_id).to eql('abc') }
	it { expect(subject.mobile_number).to eql('+255701234567') }
	it { expect(subject.amount).to eql('543') }

	it { should respond_to(:vendor_id) }
	it { should respond_to(:mobile_number) }
	it { should respond_to(:amount) }
	it { should respond_to(:response) }
	it { should respond_to(:reference) }
	it { should respond_to(:success) }
	it { should respond_to(:customer_name) }
	it { should respond_to(:sent_amount) }
	it { should respond_to(:status) }
	it { should respond_to(:status_description) }
	it { should respond_to(:status_code) }

	describe 'request params' do
		before do
			Selcom.configure do |c|
				c.vendor_id = 'abc'
				c.vendor_pin = '543'
			end
		end

		subject do 
			Selcom::SendMoney.new({
			amount: '543',
			mobile_number: '+255701234567',
			vendor_id: 'abc'
			})
		end

		it do
			expect(subject.to_params).to eql({
				amount: '543',
				mobile_number: '+255701234567',
				vendor_id: 'abc'
				})
		end


	end

	describe 'sending money' do

		describe "invalid request" do
			let(:response) do
				double(:body => 
					HashWithIndifferentAccess.new(
						{"transid" => "mwliid12345",
			 			"reference" => "4655259721",
			  			"message" => "Airtel Money Cash-in",
			   			"resultcode" => "000",
			   			"result" => "FAIL"}
			   		)
        		)
			end

			subject { Selcom::SendMoney.new(:amount => 543, :mobile_number => '', :vendor_id =>'') }
			before { subject.should_receive(:connection).with(subject.to_params).and_return(response) }

			it 'parses the response and sets accessors' do
				expect(subject.send!).to eql(false)
				expect(subject.status_code).to eql("000")
				expect(subject.status_description).to eql('Airtel Money Cash-in')
			end
		end

		describe "success" do
			let(:response) do
				double(:body => 
					HashWithIndifferentAccess.new(
					{"transid"=>"mwliid12345",
			 			"reference"=>"4655259721",
			  			"message"=>"Airtel Money Cash-in",
			   			"resultcode"=>"000",
			    		"result"=>"SUCCESS"}
        			)
        		)
			end

			subject { Selcom::SendMoney.new(:amount => 1234, :mobile_number => '+255701234567') }
			before { subject.should_receive(:connection).with(subject.to_params).and_return(response) }

			it 'parses the response and sets accessors' do
				expect(subject.send!).to eql(true)
				expect(subject.status_code).to eql('000')
				expect(subject.status_description).to eql("Airtel Money Cash-in")
				expect(subject.reference).to eql('4655259721')
			end
		end
	end
end
	