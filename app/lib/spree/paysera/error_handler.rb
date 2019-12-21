# frozen_string_literal: true

module Spree::Paysera::ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from(StandardError, with: ->(e) { handle_error(e) })
  end

  private

  def handle_error(error)
    render plain: 'Error: ' + error.message
  end
end
