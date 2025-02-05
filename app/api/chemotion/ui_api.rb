# frozen_string_literal: true

# Chemotion module
module Chemotion
  # UiAPI class
  class UiAPI < Grape::API
    resource :ui do
      desc 'Initialize UI'
      params do
      end
      get 'initialize' do
        has_chem_spectra = Rails.configuration.try(:spectra).try(:chemspectra).try(:url).present?
        has_nmrium_wrapper = Rails.configuration.try(:spectra).try(:nmriumwrapper).try(:url).present?
        m_config = Rails.root.join('config', 'matrices.json')
        sfn_config = Rails.configuration.try(:sfn_config).try(:provider)
        converter_config = Rails.configuration.try(:converter).try(:url)
        radar_config = Rails.configuration.try(:radar).try(:url)
        {
          has_chem_spectra: has_chem_spectra,
          has_nmrium_wrapper: has_nmrium_wrapper,
          matrices: File.exist?(m_config) ? JSON.parse(File.read(m_config)) : {},
          klasses: ElementKlass.where(is_active: true, is_generic: true)&.pluck(:name) || [],
          structure_editors: Rails.configuration.structure_editors,
          has_sfn: sfn_config.present? && current_user.matrix_check_by_name('scifinderN')
        }
      end
    end
  end
end
