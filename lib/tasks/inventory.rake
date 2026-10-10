namespace :inventory do
  desc "Import the original spreadsheet's CSV export, e.g. rake inventory:import[path/to/csv_directory]"
  task :import, [:directory] => :environment do |_task, args|
    abort "Usage: rake inventory:import[path/to/csv_directory]" if args[:directory].blank?

    InventoryImport.new(args[:directory]).run
    puts "Imported #{Item.count} items across #{Food.count} foods, #{Person.count} people, " \
         "and #{HouseholdSupply.count} household supplies."
  end
end
