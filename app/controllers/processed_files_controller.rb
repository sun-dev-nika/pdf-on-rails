class ProcessedFilesController < ApplicationController
  before_action :authenticate_user!, only: :index
  before_action :set_processed_file, only: :show

  def show
  end

  def index
    @processed_files = current_user.processed_files.with_attached_result_file.order(created_at: :desc)
  end

  private

  def set_processed_file
    @processed_file = ProcessedFile.find(params[:id])
    unless @processed_file.owned_by?(user: current_user, guest_token: current_guest_token)
      redirect_to root_path, alert: t("processed_files.errors.not_found")
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: t("processed_files.errors.not_found")
  end
end
