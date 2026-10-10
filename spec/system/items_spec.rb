require "rails_helper"

RSpec.describe "Managing items" do
  it "adds several items in a row with save and add another" do
    create(:food, name: "Rice")
    sign_in_as(create(:user))

    click_on "Add Item"
    fill_in "item_food_id_combobox", with: "Rice"
    find("[role=option]", text: "Rice").click
    fill_in "Description", with: "White Rice"
    fill_in "Amount", with: "32.4"
    fill_in "Expires on", with: "2054-01-01"
    click_on "Save and add another"

    expect(page).to have_content("White Rice was added.")
    expect(page).to have_field("Description", with: "White Rice")
    fill_in "Amount", with: "5.4"
    click_on "Create Item"

    expect(page).to have_content("White Rice was added.")
    expect(Item.pluck(:description, :amount)).to contain_exactly(["White Rice", 32.4], ["White Rice", 5.4])
  end

  it "copies an existing item and edits the copy" do
    original = create(:item, description: "Hard White", amount: 45, expires_on: Date.new(2039, 1, 1))
    sign_in_as(create(:user))

    visit madmin_items_path
    click_on "Copy and edit"
    fill_in "Expires on", with: "2042-01-01"
    click_on "Create Item"

    expect(page).to have_content("Hard White was added.")
    expect(original.reload.expires_on).to eq(Date.new(2039, 1, 1))
    expect(Item.where.not(id: original.id).sole).to have_attributes(amount: 45, expires_on: Date.new(2042, 1, 1))
  end
end
