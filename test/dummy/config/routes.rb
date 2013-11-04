Rails.application.routes.draw do
  
  resources :things
  resources :pieces
  
  resources :modal_things
  resources :modal_pieces
  
  
  root :to=>'things#index'

  #mount Wake::Engine => "/wake"
end
