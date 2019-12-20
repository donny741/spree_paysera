# frozen_string_literal: true

FactoryBot.define do
  factory :paysera_gateway, class: Spree::Gateway::Paysera do
    name { 'Paysera' }

    # to write new specs please provide proper credentials
    # either here or in dummy secrets.yml file. Values will
    # be recorded on VCR, so they can be safely replaced with
    # placeholder afterwards
    transient do
      project_id { Rails.application.secrets.project_id || 'change me' }
      sign_key { Rails.application.secrets.sign_key || 'change me' }
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
