class Madmin::DashboardController < Madmin::ApplicationController
  helper InventoryHelper

  def show
    @expiring_items = Item.expiring_soon.includes(:food)
    @household_size = Person.household_size
    @foods = Food.includes(:items).order(:name)
  end
end
