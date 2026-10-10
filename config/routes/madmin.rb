namespace :madmin do
  resources :categories
  resources :foods
  resources :household_supplies
  resources :items
  resources :people
  resources :shopping_list_items
  resources :users
  root to: "dashboard#show"
end
