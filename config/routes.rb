Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get "merge" => "pdf_operations#merge"
  post "merge" => "pdf_operations#merge_files"

  get "split" => "pdf_operations#split"
  post "split" => "pdf_operations#split_file"

  get "rotate" => "pdf_operations#rotate"
  post "rotate" => "pdf_operations#rotate_file"

  get "delete_pages" => "pdf_operations#delete_pages"
  post "delete_pages" => "pdf_operations#delete_pages_file"

  get "compress" => "pdf_operations#compress"
  post "compress" => "pdf_operations#compress_file"

  get "watermark" => "pdf_operations#watermark"
  post "watermark" => "pdf_operations#watermark_file"

  get "protect" => "pdf_operations#protect"
  post "protect" => "pdf_operations#protect_file"

  get "unlock" => "pdf_operations#unlock"
  post "unlock" => "pdf_operations#unlock_file"

  get "jpg_to_pdf" => "conversions#jpg_to_pdf"
  post "jpg_to_pdf" => "conversions#jpg_to_pdf_convert"

  get "pdf_to_jpg" => "conversions#pdf_to_jpg"
  post "pdf_to_jpg" => "conversions#pdf_to_jpg_convert"

  get "ocr" => "pdf_operations#ocr"
  post "ocr" => "pdf_operations#ocr_file"

  get "office_to_pdf" => "conversions#office_to_pdf"
  post "office_to_pdf" => "conversions#office_to_pdf_convert"

  get "organize" => "pdf_operations#organize"
  post "organize" => "pdf_operations#organize_file"
  patch "organize/:id" => "pdf_operations#organize_apply", as: :organize_apply

  get "history" => "processed_files#index"
  resources :processed_files, only: [ :show ]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "pages#home"
end
