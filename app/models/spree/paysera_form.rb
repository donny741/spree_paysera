# frozen_string_literal: true

class Spree::PayseraForm
  include ActiveModel::Model

  attr_accessor :projectid, :orderid, :accepturl, :cancelurl, :callbackurl,
                :version, :lang, :amount, :currency, :payment, :country,
                :paytext, :p_firstname, :p_lastname, :p_email, :p_street,
                :p_city, :p_state, :p_zip, :p_countrycode, :only_payments,
                :disalow_payments, :test, :time_limit, :personcode, :developerid

  validates :projectid, presence: true, length: { maximum: 11 },
                        format: { with: /\A\d+\z/ }
  validates :version, presence: true, length: { maximum: 9 },
                      format: { with: /\A\d+\.\d+\z/ }
  validates :orderid, presence: true, length: { maximum: 40 }
  validates :accepturl, presence: true, length: { maximum: 255 }
  validates :cancelurl, presence: true, length: { maximum: 255 }
  validates :callbackurl, presence: true, length: { maximum: 255 }

  validates :lang, length: { maximum: 3 },
                   format: { with: /\A[a-z]{3}\z/i, allow_blank: true }
  validates :amount, length: { maximum: 11 },
                     numericality: { only_integer: true, allow_blank: true }
  validates :currency, length: { maximum: 3 },
                       format: { with: /\A[a-z]{3}\z/i, allow_blank: true }
  validates :country, length: { maximum: 2 },
                      format: { with: /\A[a-z]{2}\z/i, allow_blank: true }
  validates :paytext, length: { maximum: 255 }
  validates :payment, length: { maximum: 20 }

  validates :p_firstname, length: { maximum: 255 }
  validates :p_lastname, length: { maximum: 255 }
  validates :p_email, length: { maximum: 255 }
  validates :p_street, length: { maximum: 255 }
  validates :p_city, length: { maximum: 255 }
  validates :p_state, length: { maximum: 20 }
  validates :p_zip, length: { maximum: 20 }
  validates :p_countrycode, length: { maximum: 2 },
                            format: { with: /\A[a-z]{2}\z/i, allow_blank: true }

  validates :time_limit, length: { maximum: 19 }
  validates :personcode, length: { maximum: 255 }
  validates :developerid, length: { maximum: 11 },
                          format: { with: /\A\d+\z/, allow_blank: true }
  validates :test, length: { maximum: 1 },
                   format: { with: /\A[01]\z/, allow_blank: true }

  def attributes
    instance_values.except('errors', 'validation_context').symbolize_keys
  end
end
