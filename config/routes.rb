Rails.application.routes.draw do
  resources :users, only: [:new, :create]
  resources :documents do
    member do
      post :permissions
    end
  end
  root to: redirect('/documents')
end
