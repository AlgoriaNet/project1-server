# frozen_string_literal: true

class StaticDataController < ApplicationController
  before_action :authenticate_user, except: [:version_file]

  # GET /static_data/version.json
  def version_file
    version_path = Rails.root.join('public', 'static_data', 'version.json')
    
    if File.exist?(version_path)
      version_data = JSON.parse(File.read(version_path))
      render json: version_data
    else
      render json: { error: "Version file not found" }, status: 404
    end
  end


  # GET /static_data/base_sidekicks.json
  def base_sidekicks_file
    base_sidekicks_path = Rails.root.join('public', 'static_data', 'base_sidekicks.json')
    
    if File.exist?(base_sidekicks_path)
      base_sidekicks_data = JSON.parse(File.read(base_sidekicks_path))
      render json: base_sidekicks_data
    else
      render json: { error: "Base sidekicks file not found" }, status: 404
    end
  end
end