# == Schema Information
#
# Table name: concepts
#
#  id            :bigint           not null, primary key
#  taggable_data :jsonb
#  doi_id        :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  deleted_at    :datetime
#  metadata_xml  :text
#

class Concept < ApplicationRecord
  acts_as_paranoid

  belongs_to :publication, optional: true
  belongs_to :doi

  def update_for_doi!(doi)
    self.doi.doiable_id = doi.doiable_id
    self.doi.save!

    self.metadata_xml = nil
    self.save!
  end

  def self.create_for_doi!(doi)
    concept_doi = doi.dup
    concept_doi.version_count = nil
    concept_doi.save!

    Concept.create!(
      doi: concept_doi
    )
  end

end
