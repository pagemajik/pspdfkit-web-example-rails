class CreateModels < ActiveRecord::Migration[5.0]
  def change
    create_table :documents do |t|
      t.string :title
      t.integer :server_id
      t.timestamps
    end

    create_table :documents_users do |t|
      t.integer :document_id
      t.integer :user_id
    end

    create_table :users do |t|
      t.string :name
    end
  end
end
