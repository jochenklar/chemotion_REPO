class AddConceptToPublications < ActiveRecord::Migration[5.2]
  def change
    add_column :publications, :concept_id, :integer

    Publication.all.each do |publication|
      doi = publication.doi
      unless doi.nil?
        concept = Concept.create_for_doi!(doi)
        publication.concept = concept
        publication.save!
      end
    end
  end
end
