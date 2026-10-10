module InventoryHelper
  def format_amount(amount)
    return "—" if amount.nil?

    number_with_precision(amount, precision: 2, delimiter: ",", strip_insignificant_zeros: true)
  end
end
