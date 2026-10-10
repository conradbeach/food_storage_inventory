namespace :madmin do
  resources :categories
  resources :foods
  resources :household_supplies
  resources :items do
    get :copy, on: :member
  end
  resources :people
  resources :users
  root to: "dashboard#show"
end
