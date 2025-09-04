# frozen_string_literal: true

class StaticDataController < ApplicationController
  before_action :authenticate_user, except: [:version_file, :skill_effects_file]

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

  # GET /static_data/skill_effects.json  
  def skill_effects_file
    skill_effects_path = Rails.root.join('public', 'static_data', 'skill_effects.json')
    
    if File.exist?(skill_effects_path)
      skill_effects_data = JSON.parse(File.read(skill_effects_path))
      render json: skill_effects_data
    else
      render json: { error: "Skill effects file not found" }, status: 404
    end
  end
end