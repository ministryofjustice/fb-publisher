Rails.application.routes.draw do
  # Auth0 routes
  get "/auth/oauth2/callback" => "auth0#callback"
  get "/auth/failure" => "auth0#failure"

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '/dashboard' => 'dashboard#show'
  get '/welcome' => 'welcome#show'
  get '/signup_not_allowed' => 'user_sessions#signup_not_allowed', as: 'signup_not_allowed'
  get '/signup_error/:error_type' => 'user_sessions#signup_error', as: 'signup_error'
  get '/' => 'home#show', as: 'root'

  resources :teams
  resources :services do
    scope :module => 'services' do
      resource :status, controller_name: :service_status
      resources :config_params
      resources :permissions, controller_name: :service_permissions
      resources :deployments, controller_name: :service_deployments
    end
  end


  resource :user, only: [:edit, :update, :destroy]
  resource :user_session, only: [:destroy]
end
