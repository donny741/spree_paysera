## [Paysera](https://www.paysera.com/v2/en-GB/index) payment gateway integration for [Spree Ecommerce](https://spreecommerce.org).

[![Build Status](https://travis-ci.org/donny741/spree_paysera.svg?branch=master)](https://travis-ci.org/donny741/spree_paysera)

Adds Paysera payment option to the checkout view. Can be customized by editing `paysera` partial.
Tested on Spree version 3.5+.


## Installation

1. Add gem to your gemfile:

        gem 'spree_paysera', '~> 1.0', '>= 1.0.1'

2. Install the gem using Bundler:

        bundle install

3. Restart your server

## Setup

- In Spree admin panel go to "Configuration" > "Payment Methods".
- Create a new payment method.
- Select provider "Spree::Gateway::Paysera", enter name and description.
- Click "Create".
- Enter Project ID, Domain Name and Message Text (paytext). Untick "Test Mode" for use in production.
