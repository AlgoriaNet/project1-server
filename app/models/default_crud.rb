# app/controllers/concerns/default_crud.rb
module DefaultCrud
  extend ActiveSupport::Concern
  extend Result



  included do
    before_action :set_resource, only: [:show, :update, :destroy]
  end

  def index
    query = params[:query].try(&:as_json) || {}
    @resources = resource_class.where(query).all
    render json: ok(@resources.map(&:http_json))
  end

  def show
    render json: ok(@resource)
  end

  def create
    if resource_class.const_defined?('CREATE_FIELDS')
      create_fields = resource_class.const_get('CREATE_FIELDS')
    else
      create_fields = resource_class.attribute_names.map(&:to_sym)
    end
    @resource = resource_class.new(params.permit(create_fields))
    if @resource.save
      render json: ok(@resource.http_json)
    else
      render json: error(@resource.errors.full_messages.join(","))
    end
  end

  def update
    if resource_class.const_defined?('UPDATE_FIELDS')
      update_fields = resource_class.const_get('UPDATE_FIELDS')
    else
      update_fields = resource_class.attribute_names.map(&:to_sym)
    end
    if @resource.update(params.permit(update_fields))
      render json: ok(@resource.http_json)
    else
      render json: error(@resource.errors.full_messages.join(","))
    end
  end

  def destroy
    @resource.destroy
    if @resource.destroyed?
      render json: ok
    else
      render json: error(@resource.errors.full_messages.join(","))
    end
  end

  private

  def set_resource
    @resource = resource_class.find(params[:id])
  end

  def resource_class
    controller_name.classify.constantize
  end

  def resource_params
    params.require(controller_name.singularize.to_sym).permit!
    # You can modify the strong parameters to fit your needs
  end
end
