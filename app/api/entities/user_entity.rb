module Entities
  class UserEntity < Grape::Entity
    expose :id, documentation: { type: "Integer", desc: "User's unique id"}
    expose :name, documentation: { type: "String", desc: "User's name" }
    expose :first_name, documentation: { type: "String", desc: "User's name" }
    expose :last_name, documentation: { type: "String", desc: "User's name" }
    expose :initials, documentation: { type: "String", desc: "initials" }
    expose :samples_count, documentation: { type: "Integer", desc: "Sample count"}
    expose :reactions_count, documentation: { type: "Integer", desc: "Reactions count"}
    expose :type, if: -> (obj, opts) { obj.respond_to? :type}
    expose :reaction_name_prefix, if: -> (obj, opts) { obj.respond_to? :reaction_name_prefix}
    expose :layout, if: -> (obj, opts) { obj.respond_to? :layout}
    expose :email, if: -> (obj, opts) { obj.respond_to? :email}
    expose :unconfirmed_email, if: -> (obj, opts) { obj.respond_to? :unconfirmed_email}
    expose :confirmed_at, if: -> (obj, opts) { obj.respond_to? :confirmed_at}
    expose :current_sign_in_at, if: -> (obj, opts) { obj.respond_to? :current_sign_in_at}
    expose :locked_at, if: -> (obj, opts) { obj.respond_to? :locked_at}
    expose :is_templates_moderator, documentation: { type: "Boolean", desc: "ketcherails template administrator" }
    expose :molecule_editor, documentation: { type: 'Boolean', desc: 'molecule administrator' }
    expose :converter_admin, documentation: { type: 'Boolean', desc: 'converter administrator' }
    expose :account_active, documentation: { type: 'Boolean', desc: 'User Account Active or Inactive' }
    expose :matrix, documentation: { type: 'Integer', desc: "User's matrix" }
    expose :counters
    expose :affiliations, :current_affiliations
    expose :is_article_editor, :is_howto_editor, :is_reviewer
    expose :orcid

    def affiliations
      a = {}
      object.affiliations.select(
        'id',
        'affiliations.department || chr(44)|| chr(32) || affiliations.organization || chr(44)|| chr(32) || affiliations.country as aff'
      ).reduce(a){|acc, affiliation| a[affiliation.id] = affiliation.aff}
      a
    end

    def orcid
      object.orcid
    end

    def current_affiliations
      a = {}
      object.current_affiliations.select(
        'id',
        'affiliations.department || chr(44)|| chr(32) || affiliations.organization || chr(44)|| chr(32) || affiliations.country as aff'
      ).reduce(a){|acc, affiliation| a[affiliation.id] = affiliation.aff}
      a
    end

    def samples_count
      object.counters['samples'].to_i
    end

    def reactions_count
      object.counters['reactions'].to_i
    end

    expose :current_sign_in_at do |obj|
      return nil unless obj.respond_to? :current_sign_in_at
      obj.current_sign_in_at.strftime('%d.%m.%Y, %H:%M') unless obj.current_sign_in_at.nil?
    end
  end
end
