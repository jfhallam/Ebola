Rails.application.routes.draw do
  resources :surveys do
  	collection do
  		post :twilio
  		get :twilio
  	end
  end

  root to: 'surveys#index'
end
