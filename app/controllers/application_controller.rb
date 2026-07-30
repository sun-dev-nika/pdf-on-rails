class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_locale

  helper_method :current_guest_token

  private

  def set_locale
    if params[:locale].present? && I18n.available_locales.include?(params[:locale].to_sym)
      session[:locale] = params[:locale]
    end

    I18n.locale = session[:locale] || I18n.default_locale
  end

  # Stable per-browser-session identifier for guests, used to own
  # ProcessedFile records without requiring an account.
  def current_guest_token
    session[:guest_token] ||= SecureRandom.uuid
  end
end
