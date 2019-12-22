# frozen_string_literal: true

FactoryBot.define do
  factory :paysera_gateway, class: Spree::Gateway::Paysera do
    name { 'Paysera' }

    transient do
      project_id { ENV.fetch('PROJECT_ID', 'change me') }
      sign_key { ENV.fetch('SIGN_PASSWORD', 'change me') }
      domain_name { 'https://dommy.domain' }
      message_text { 'Dummy payment' }
    end

    before(:create) do |gateway, s|
      %w[project_id sign_key domain_name message_text].each do |preference|
        gateway.send "preferred_#{preference}=", s.send(preference)
      end
      gateway.send 'preferred_server=', :sandbox
    end
  end
end
