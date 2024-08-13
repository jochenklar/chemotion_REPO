class CreateConcepts < ActiveRecord::Migration[5.2]
  def change
    create_table :concepts do |t|
      t.jsonb :taggable_data
      t.integer :doi_id
      t.datetime :created_at
      t.datetime :updated_at
      t.datetime :deleted_at
      t.text :metadata_xml

      t.timestamps
    end
  end
end
