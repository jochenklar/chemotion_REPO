# frozen_string_literal: true

module AttachmentConverter
  ACCEPTED_FORMATS = (Rails.configuration.try(:converter).try(:ext) || []).freeze
  extend ActiveSupport::Concern

  included do
    before_create :init_converter
    after_update :exec_converter
    def init_converter
      self.aasm_state = 'queueing' if Rails.configuration.try(:converter).try(:url) && ACCEPTED_FORMATS.include?(File.extname(filename&.downcase))
    end

    def exec_converter
      return if !Rails.configuration.try(:converter).try(:url) || !ACCEPTED_FORMATS.include?(File.extname(filename&.downcase)) || aasm_state != 'queueing'

      state = Analyses::Converter.jcamp_converter(id)
      self.aasm_state = state if %w[done failure].include?(state)
    end
  end
end
