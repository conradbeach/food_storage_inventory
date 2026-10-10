class Madmin::ItemsController < Madmin::ResourceController
  def create
    @record = resource.model.new
    if save_record(resource_params)
      redirect_to after_create_path, notice: "#{resource.display_name(@record)} was added."
    else
      render :new, status: :unprocessable_content
    end
  end

  def copy
    @record = @record.dup
    render :new
  end

  private

  def after_create_path
    if params[:add_another]
      main_app.new_madmin_item_path(item: @record.slice(:food_id, :description, :amount, :expires_on))
    else
      resource.show_path(@record)
    end
  end
end
