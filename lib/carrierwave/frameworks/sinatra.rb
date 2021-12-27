# frozen_string_literal: true

gem "sinatra", ">= 1.3.0"

CarrierWave.root = Sinatra::Application.public_folder
