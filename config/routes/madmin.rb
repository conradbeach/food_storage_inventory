namespace :madmin do
  resources :categories
  resources :foods
  resources :household_supplies
  resources :items
  resources :people
  resources :users
  root to: "dashboard#show"
end
