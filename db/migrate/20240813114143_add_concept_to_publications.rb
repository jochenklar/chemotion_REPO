class AddConceptToPublications < ActiveRecord::Migration[5.2]
  def change
    add_column :publications, :concept_id, :integer

    Publication.order(:created_at).each do |publication|
      doi = publication.doi
      element = publication.element

      unless doi.nil? or element.nil?
        if publication.element_type == 'Container'
          previous_version = element.extended_metadata['previous_version_id']
          if previous_version.nil?
            concept = Concept.create_for_doi!(doi)
          else
            previous_publication = Publication.find_by(element_type: 'Container', element_id: previous_version)
            concept = previous_publication.concept
            concept.update_for_doi!(doi)
          end
        else
          previous_version = element.tag.taggable_data.dig('previous_version', 'id')
          if previous_version.nil?
            concept = Concept.create_for_doi!(doi)
          else
            previous_publication = Publication.find_by(element_type: publication.element_type, element_id: previous_version)
            concept = previous_publication.concept
            concept.update_for_doi!(doi)
          end
        end

        publication.concept = concept
        publication.save!
      end
    end
  end
end
