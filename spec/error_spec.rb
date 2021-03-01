require 'spec_helper'

describe CarrierWave::IntegrityError do
  it "should use I18n to fill the default public message" do
    expect(CarrierWave::IntegrityError.new).to have_attributes(public_message: 'is not of an allowed file type')

    change_locale_and_store_translations(:pt, :errors => {
      :messages => {
        :carrierwave_integrity_error => 'não é um tipo de ficheiro permitido'
      }
    }) do
      expect(CarrierWave::IntegrityError.new).to have_attributes(public_message: 'não é um tipo de ficheiro permitido')
    end
  end

  it "should use the given public messages" do
    expect(CarrierWave::IntegrityError.new('Ohh noez!')).to have_attributes(public_message: 'Ohh noez!')

    change_locale_and_store_translations(:pt, :activerecord => {
      :errors => {
        :messages => {
          :carrierwave_integrity_error => 'não é um tipo de ficheiro permitido'
        }
      }
    }) do
      expect(CarrierWave::IntegrityError.new('Ohh noez!')).to have_attributes(public_message: 'Ohh noez!')
    end
  end
end

describe CarrierWave::ProcessingError do
  it "should use I18n to fill the default public message" do
    expect(CarrierWave::ProcessingError.new).to have_attributes(public_message: 'failed to be processed')

    change_locale_and_store_translations(:pt, :errors => {
      :messages => {
        :carrierwave_processing_error => 'falha ao processar imagem.'
      }
    }) do
      expect(CarrierWave::ProcessingError.new).to have_attributes(public_message: 'falha ao processar imagem.')
    end
  end

  it "should use the given public messages" do
    expect(CarrierWave::ProcessingError.new('Ohh noez!')).to have_attributes(public_message: 'Ohh noez!')

    change_locale_and_store_translations(:pt, :errors => {
      :messages => {
        :carrierwave_processing_error => 'falha ao processar imagem.'
      }
    }) do
      expect(CarrierWave::ProcessingError.new('Ohh noez!')).to have_attributes(public_message: 'Ohh noez!')
    end
  end
end

describe CarrierWave::DownloadError do
  it "should use I18n to fill the default public message" do
    expect(CarrierWave::DownloadError.new).to have_attributes(public_message: 'could not be downloaded')

    change_locale_and_store_translations(:pt, :errors => {
      :messages => {
        :carrierwave_download_error => 'não pôde ser transferido'
      }
    }) do
      expect(CarrierWave::DownloadError.new).to have_attributes(public_message: 'não pôde ser transferido')
    end
  end

  it "should use the given public messages" do
    expect(CarrierWave::DownloadError.new('Ohh noez!')).to have_attributes(public_message: 'Ohh noez!')

    change_locale_and_store_translations(:pt, :errors => {
      :messages => {
        :carrierwave_download_error => 'não pôde ser transferido'
      }
    }) do
      expect(CarrierWave::DownloadError.new('Ohh noez!')).to have_attributes(public_message: 'Ohh noez!')
    end
  end
end
