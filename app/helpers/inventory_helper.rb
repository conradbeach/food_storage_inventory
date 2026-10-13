module InventoryHelper
  def format_amount(amount)
    return "—" if amount.nil?

    number_with_precision(amount, precision: 2, delimiter: ",", strip_insignificant_zeros: true)
  end

  def format_months(months)
    (months % 12).zero? ? pluralize(months / 12, "year") : pluralize(months, "month")
  end
end
