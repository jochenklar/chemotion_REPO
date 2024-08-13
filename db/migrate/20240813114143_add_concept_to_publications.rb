class AddConceptToPublications < ActiveRecord::Migration[5.2]
  def change
    add_column :publications, :concept_id, :integer
  end
end
