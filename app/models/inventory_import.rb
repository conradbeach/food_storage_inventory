require "csv"

# Imports the CSV export of the original Numbers spreadsheet, which has one CSV
# per sub-table named "<Sheet>-<Table>.csv".
class InventoryImport
  class AlreadyImportedError < StandardError; end

  def initialize(directory)
    @directory = Pathname(directory)
  end

  def run
    raise AlreadyImportedError, "Items already exist; import only into an empty database." if Item.exists?

    ActiveRecord::Base.transaction do
      Foods::DEFINITIONS.each { import_food(it) }
      import_people
      import_household_supplies
    end
  end

  private

  def import_food(definition)
    category = Category.find_or_create_by!(name: definition[:category])
    food = category.foods.create!(food_attributes(definition))

    definition[:tables].each do |table|
      import_items(food, table, definition[:amount_column], multiple_tables: definition[:tables].many?)
    end
  end

  def food_attributes(definition)
    summary_name = definition.fetch(:summary, definition[:name])
    {
      name: definition[:name],
      unit: definition.fetch(:unit, "lbs"),
      yearly_amount_per_person: definition.fetch(:yearly_amount_per_person) { yearly_targets[summary_name] },
      package_amount: number(packages.dig(summary_name, "Amount Per Unit")),
      package_price: number(packages.dig(summary_name, "Per Unit Price")),
    }
  end

  def import_items(food, table, amount_column, multiple_tables:)
    rows(table).each do |row|
      amount_text = amount_column ? row[amount_column] : row[1]
      # Skips blank rows and notes such as links or "Months Supplied For" footers.
      next if number(amount_text).nil? && (row[0].blank? || amount_text.blank?)

      food.items.create!(
        description: item_description(table, row[0], amount_text, multiple_tables:),
        amount: number(amount_text),
        expires_on: expiration_date(row["Exp. Date"]),
      )
    end
  end

  # Blank descriptions take the sub-table's name, e.g. "Pinto Beans". Amounts
  # that aren't numbers, like "195 grams, 20 varieties", are kept in the text.
  def item_description(table, description, amount_text, multiple_tables:)
    table_name = table.split("-", 2).last
    description = description.to_s.strip
    description = table_name if description.empty?
    if multiple_tables && description.downcase.exclude?(table_name.downcase)
      description = "#{table_name}: #{description}"
    end
    description += " (#{amount_text})" if amount_text.present? && number(amount_text).nil?
    description
  end

  def import_people
    rows("Summary-People to Provide For").each do |row|
      next if row["Person"].blank? || row["Person"] == "Total"

      Person.create!(name: row["Person"], calories_per_day: number(row["Calories Per Day"]).to_i)
    end
  end

  def import_household_supplies
    rows("3 Month Supply-Essential Home Supplies").each do |row|
      next if row["Description"].blank?

      HouseholdSupply.create!(name: row["Description"], quantity_to_store: row["Quantity to Store"])
    end
  end

  def yearly_targets
    @yearly_targets ||= rows("Summary-Table 1").to_h do |row|
      [row["Food Item (lbs or noted)"], number(row["Per Person/Per Year"])]
    end
  end

  def packages
    @packages ||= rows("Shopping List-Shopping List").index_by { it["Item"] }
  end

  def rows(table)
    path = @directory.join("#{table}.csv")
    path.exist? ? CSV.read(path, headers: true) : []
  end

  def number(text)
    cleaned = text.to_s.delete(",$").strip
    BigDecimal(cleaned) if cleaned.match?(/\A-?\d+(\.\d+)?\z/)
  end

  # "2048" and "8/27" are stored as the first day of that year or month so
  # they're flagged early; "Eternity" or blank means no expiration date.
  def expiration_date(text)
    text = text.to_s.strip
    if (month_year = text.match(%r{\A(?<month>\d{1,2})/(?<year>\d{2})\z}))
      Date.new(2000 + month_year[:year].to_i, month_year[:month].to_i, 1)
    elsif text.match?(/\A\d{4}\z/)
      Date.new(text.to_i, 1, 1)
    end
  end
end
