# frozen_string_literal: true

class Api::StaticDataController < ApplicationController
  before_action :authenticate_user, except: [:manifest, :bundle]

  # GET /api/static_data/manifest
  def manifest
    manifest_path = Rails.root.join('public', 'static_data', 'manifest.json')
    
    if File.exist?(manifest_path)
      manifest_data = JSON.parse(File.read(manifest_path))
      render json: manifest_data
    else
      render json: { error: "Manifest not found" }, status: 404
    end
  end

  # GET /api/static_data/bundle/:bundle_name  
  def bundle
    bundle_name = params[:bundle_name]
    bundle_path = Rails.root.join('public', 'static_data', 'bundles', "#{bundle_name}.json")
    
    if File.exist?(bundle_path)
      bundle_data = JSON.parse(File.read(bundle_path))
      render json: bundle_data
    else
      render json: { error: "Bundle '#{bundle_name}' not found" }, status: 404
    end
  end
end