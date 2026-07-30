class ProcessedFile < ApplicationRecord
  belongs_to :user, optional: true
  has_one_attached :source_file
  has_one_attached :result_file

  enum :status, { pending: "pending", processing: "processing", completed: "completed", failed: "failed" },
       default: :pending

  validates :operation, presence: true

  broadcasts_refreshes

  def owned_by?(user:, guest_token:)
    if user_id
      user_id == user&.id
    else
      guest_token.present? && guest_token == self.guest_token
    end
  end
end
