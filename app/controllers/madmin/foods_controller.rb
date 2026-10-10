class Madmin::FoodsController < Madmin::ResourceController
  private

  def scoped_resources = super.includes(:category)
end
