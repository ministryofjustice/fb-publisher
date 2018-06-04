Rails.application.routes.draw do
  # Auth0 routes
  get "/auth/oauth2/callback" => "auth0#callback"
  get "/auth/failure" => "auth0#failure"

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '/dashboard' => 'dashboard#show'

  get '/' => 'home#show', as: 'root'
end
