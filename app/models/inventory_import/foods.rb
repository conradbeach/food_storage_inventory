module InventoryImport::Foods
  ADULT_CALORIES_PER_YEAR = Person::ADULT_DAILY_CALORIES * 365

  # Each food is a row on the spreadsheet's Summary sheet; its items come from
  # one or more sub-tables. `summary` names the Summary and Shopping List row.
  DEFINITIONS = [
    { category: "Grains", name: "Wheat", tables: ["Grains-Wheat"] },
    { category: "Grains", name: "Rice", tables: ["Grains-Rice"] },
    { category: "Grains", name: "Oats", tables: ["Grains-Oats"] },
    { category: "Grains", name: "Pasta", tables: ["Grains-Pasta"] },
    {
      category: "Legumes", name: "Legumes",
      tables: [
        "Legumes-Black Beans", "Legumes-Great Northern Beans", "Legumes-Pinto Beans", "Legumes-White Beans"
      ]
    },
    { category: "Dairy", name: "Dry Milk", tables: ["Dairy-Dry Milk"] },
    { category: "Dairy", name: "Cheese", tables: ["Dairy-Cheese"] },
    { category: "Sugars", name: "Sugars", tables: ["Sugars-Sugar", "Sugars-Honey"] },
    { category: "Fats", name: "Cooking/Salad Oil", tables: ["Fats-Cooking Salaid Oil"] },
    { category: "Fats", name: "Butter/Margarine", tables: ["Fats-Butter Margarine"] },
    { category: "Fats", name: "Peanut Butter/Other Butters", tables: ["Fats-Peanut Butter Other Butters"] },
    { category: "Fats", name: "Mayonnaise/Salad Dressings", tables: ["Fats-Mayonnaise Salad Dressings"] },
    { category: "Fruits & Veggies", name: "Apple Slices", tables: ["Fruits & Veggies-Apple Slices"] },
    { category: "Fruits & Veggies", name: "Strawberry Slices", tables: ["Fruits & Veggies-Strawberries"] },
    { category: "Fruits & Veggies", name: "Potato Flakes", tables: ["Fruits & Veggies-Potato Flakes"] },
    { category: "Fruits & Veggies", name: "Carrots", tables: ["Fruits & Veggies-Carrots"] },
    { category: "Fruits & Veggies", name: "Onions", tables: ["Fruits & Veggies-Onions"] },
    { category: "Baking", name: "Salt", tables: ["Baking-Salt"] },
    { category: "Baking", name: "Baking Soda", tables: ["Baking-Baking Soda"] },
    { category: "Baking", name: "Baking Powder", tables: ["Baking-Baking Powder"] },
    { category: "Baking", name: "Dried Eggs", summary: "Eggs, dried", tables: ["Baking-Dried Egg"] },
    { category: "Baking", name: "Yeast", tables: ["Baking-Yeast"] },
    { category: "Baking", name: "Spices", tables: ["Baking-Spices"] },
    {
      category: "Other", name: "Vitamin C", summary: "Vitamin C (mg)", unit: "mg",
      tables: ["Other-Vitamin C (Tablets)"], amount_column: "Total mg"
    },
    {
      category: "Other", name: "Multi-vitamin", summary: "Multi-vitamin (serving)", unit: "servings",
      tables: ["Other-Multi-vitamin"]
    },
    { category: "Other", name: "Garden Seeds", tables: ["Other-Garden Seeds"] },
    {
      category: "3 Month Supply", name: "Long Term Food", unit: "calories",
      yearly_amount_per_person: ADULT_CALORIES_PER_YEAR, tables: ["3 Month Supply-Long Term Food"]
    },
  ].freeze
end
