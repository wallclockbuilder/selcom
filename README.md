# Selcom [![Code Climate](https://codeclimate.com/github/wallclockbuilder/selcom/badges/gpa.svg)](https://codeclimate.com/github/wallclockbuilder/selcom)

This gem makes it possible to use the Selcom API without having to deal with XML RPC.
## Installation

Add this line to your application's Gemfile:

```ruby
gem 'selcom'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install selcom

## Usage

set your API credentials:

```ruby
require 'selcom'
Selcom.configure do |config|
  config.api_key = '...'
  config.api_signature = '...'
end
```
Send money:

```ruby

selcom = Selcom::SendMoney.new(:mobile_number => "...", :amount => 500, :telco_id => '...')
if send_money.send!
  puts selcom.reference
  puts selcom.sent_amount
  puts selcom.success
  puts selcom.status_code
  puts selcom.status_description
else
  puts selcom.response
end

```
## Contributing

1. Fork it ( https://github.com/wallclockbuilder/selcom )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
