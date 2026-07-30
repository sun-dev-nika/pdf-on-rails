class CreateProcessedFiles < ActiveRecord::Migration[8.1]
  def change
    create_table :processed_files do |t|
      t.references :user, null: true, foreign_key: true
      t.string :guest_token
      t.string :operation, null: false
      t.string :status, null: false, default: "pending"
      t.string :original_filename
      t.text :error_message

      t.timestamps
    end

    add_index :processed_files, :guest_token
  end
end
