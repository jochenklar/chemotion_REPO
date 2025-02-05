module Chemotion
  class LiteratureAPI < Grape::API
    helpers CollectionHelpers
    helpers ParamsHelpers

    helpers do
      def citation_for_elements(id = params[:element_id], type = @element_klass, cat = 'detail')
        return Literature.none unless id.present?
        Literature.by_element_attributes_and_cat(id, type, cat).add_user_info
      end
    end

    resource :literatures do

      after_validation do
        @is_owned = nil
        @is_public = nil
        unless request.url =~ /doi\/metadata|ui_state|collection/
          @element_klass = params[:element_type].classify
          @element = @element_klass.constantize.find_by(id: params[:element_id])
          @element_policy = ElementPolicy.new(current_user, @element)
          allowed = if request.env['REQUEST_METHOD'] =~ /get/i
                      @element_policy.read?
                    else
                      @element_policy.update?
                    end

          @is_public = "Collections#{params[:element_type].classify}".constantize.where(
            "#{params[:element_type]}_id = ? and collection_id in (?)",
            params[:element_id],
            [Collection.public_collection_id, Collection.scheme_only_reactions_collection.id]
          ).presence
          error!('401 Unauthorized', 401) unless allowed
          @cat = @is_public ? 'public' : 'detail'
        end
      end

      desc "Update type of literals by element"
      params do
        requires :element_id, type: Integer
        requires :element_type, type: String, values: %w[sample reaction research_plan]
        requires :id, type: Integer
        requires :litype, type: String, values: %w[citedOwn citedRef referTo]
      end
      put do
        Literal.find(params[:id])&.update(litype: params[:litype])
        { literatures: citation_for_elements(params[:element_id], @element_klass, @cat) }
      end

      desc "Return the literature list for the given element"
      params do
        requires :element_id, type: Integer
        requires :element_type, type: String, values: %w[sample reaction research_plan]
        optional :is_all, type: Boolean, default: false
      end

      get do
        if (params[:is_all] && params[:is_all] == true && params[:element_type] == 'reaction')
          literatures = citation_for_elements(params[:element_id], @element_klass, @cat) || []
          reaction = Reaction.find(params[:element_id])
          reaction.products.each do |p|
            literatures = literatures + citation_for_elements(p.id, 'Sample', @cat)
          end
          { literatures: literatures }
        else
          { literatures: citation_for_elements(params[:element_id], @element_klass, @cat) }
        end
      #  literatures = Literature.by_element_attributes_and_cat(params[:element_id], @element_klass, %w[detail public])
      #  { literatures: literatures }
      end

      desc 'create a literature entry'
      params do
        requires :element_id, type: Integer
        requires :element_type, type: String, values: %w[sample reaction research_plan]
        requires :ref, type: Hash do
          optional :is_new, type: Boolean
          optional :id, types: [Integer, String]
          optional :doi, type: String
          optional :url, type: String
          optional :litype, type: String
          optional :title, type: String
          optional :isbn, type: String
          optional :refs, type: Hash do
            optional :bibtex, type: String
          end
        end
      end

      post do
        lit = if params[:ref][:is_new]
                Literature.find_or_create_by(
                  doi: params[:ref][:doi],
                  url: params[:ref][:url],
                  title: params[:ref][:title],
                  isbn: params[:ref][:isbn]
                )
              else
                Literature.find_by(id: params[:ref][:id])
              end

        lit.update!(refs: (lit.refs || {}).merge(declared(params)[:ref][:refs])) if params[:ref][:refs]
        attributes = {
          literature_id: lit.id,
          user_id: current_user.id,
          element_type: @element_klass,
          element_id: params[:element_id],
          litype: params[:ref][:litype],
          category: @cat
        }
        unless Literal.find_by(attributes)
          Literal.create(attributes)
          @element.touch
        end

        { literatures: citation_for_elements(params[:element_id], @element_klass, @cat) }
      end

      params do
        requires :element_id, type: Integer
        requires :element_type, type: String, values: %w[sample reaction research_plan]
        requires :id, type: Integer
      end

      delete do
        Literal.find_by(
          id: params[:id],
          # user_id: current_user.id,
          element_type: @element_klass,
          element_id: params[:element_id],
          category: @cat
        )&.destroy!
      end

      namespace :collection do
        params do
          requires :id, type: Integer
          optional :is_sync_to_me, type: Boolean, default: false
        end

        after_validation do
          set_var(params[:id], params[:is_sync_to_me])
          error!(404) unless @c
          if !@is_owned
            obj = fetch_collection_w_current_user(params[:id], params[:is_sync_to_me])
            @is_public = obj['shared_by'] && obj['shared_by']['initials'] == 'CI'
          end
        end

        get do
          if @is_public
            return {
              collectionRefs: Literature.none,
              sampleRefs: Literature.by_element_attributes_and_cat(sample_ids, 'Sample', 'public').group('literatures.id'),
              reactionRefs: Literature.by_element_attributes_and_cat(reaction_ids, 'Reaction', 'public').group('literatures.id'),
              researchPlanRefs: Literature.none,
            }
          end
          sample_ids = @dl_s > 1 ? @c.sample_ids : []
          reaction_ids = @dl_r > 1 ? @c.reaction_ids : []
          research_plan_ids = @dl_rp > 1 ? @c.research_plan_ids : []
          {
            collectionRefs: Literature.by_element_attributes_and_cat(@c_id, 'Collection', 'detail').group_by_element,
            sampleRefs: Literature.by_element_attributes_and_cat(sample_ids, 'Sample', 'detail').group_by_element,
            reactionRefs: Literature.by_element_attributes_and_cat(reaction_ids, 'Reaction', 'detail').group_by_element,
            researchPlanRefs: Literature.by_element_attributes_and_cat(research_plan_ids, 'ResearchPlan', 'detail').group_by_element,
          }
        end
      end

      namespace :ui_state do
        params do
          requires :sample, type: Hash do
            use :ui_state_params
          end
          requires :reaction, type: Hash do
            use :ui_state_params
          end
          requires :id, type: Integer
          optional :is_sync_to_me, type: Boolean, default: false
          optional :ref, type: Hash do
            optional :is_new, type: Boolean
            optional :id, types: [Integer, String]
            optional :doi, type: String
            optional :url, type: String
            optional :litype, type: String
            optional :title, type: String
            optional :refs, type: Hash do
              optional :bibtex, type: String
            end
          end
        end

        after_validation do
          set_var(params[:id], params[:is_sync_to_me])
          error!(404) unless @c
          @sids = @dl_s > 1 ? @c.samples.by_ui_state(declared(params)[:sample]).pluck(:id) : []
          @rids = @dl_r > 1 ? @c.reactions.by_ui_state(declared(params)[:reaction]).pluck(:id) : []
          @cat = "detail"
          if !@is_owned
            obj = fetch_collection_w_current_user(params[:id], params[:is_sync_to_me])
            @is_public = obj['shared_by_id'] && obj['shared_by_id'] == User.chemotion_user.id
          end
        end

        post do
          @cat = @is_public ? 'public' : 'detail'
          if params[:ref] && (@pl >= 1 || @is_public)
            lit = if params[:ref][:is_new]
                  Literature.find_or_create_by(
                    doi: params[:ref][:doi],
                    url: params[:ref][:url],
                    title: params[:ref][:title]
                  )
                else
                  Literature.find_by(id: params[:ref][:id])
                end

            lit.update!(refs: (lit.refs || {}).merge(declared(params)[:ref][:refs])) if params[:ref][:refs]
            if lit
              { 'Sample': @sids, 'Reaction': @rids }.each do |type, ids|
                ids.each do |id|
                  ltl = Literal.find_or_create_by(
                    literature_id: lit.id,
                    user_id: current_user.id,
                    element_type: type,
                    element_id: id,
                    litype: params[:ref][:litype],
                    category: @cat
                  )
                end
              end
            end
          end

          # { selectedRefs: LiteralGroup.by_element_ids_and_cat(@sids, @rids, @cat).order(element_updated_at: :desc)  }
          { selectedRefs: Literature.by_element_attributes_and_cat(@sids, 'Sample', @cat).add_element_and_user_info +
              Literature.by_element_attributes_and_cat(@rids, 'Reaction', @cat).add_element_and_user_info }
        end
      end


      namespace :doi do
        desc "get metadata from a doi input"
        params do
          requires :doi, type: String
        end

        after_validation do
          params[:doi].match(/(?:\s*10\.)(\S+)\/(\S+)/)
          @doi_prefix = $1
          @doi_suffix = $2
          error(400) unless (@doi_prefix.present? && @doi_suffix.present?)
        end

        get :metadata do
          connection = Faraday.new(url: "https://dx.doi.org") do |f|
            f.use FaradayMiddleware::FollowRedirects
            # f.headers = { 'Accept' => 'text/bibliography; style=bibtex'}
            f.headers = { 'Accept' => 'application/x-bibtex' }
            f.adapter :net_http
          end
          resp = connection.get { |req| req.url("/10.#{@doi_prefix}/#{@doi_suffix}") }
          unless resp.success?
            error!({ error: reason_phrase } , resp.status)
          end
          resp_json = begin
                        JSON.parse(BibTeX.parse(resp.body).to_json)
                      rescue StandardError => e
                        error!(e , 503)
                      end
          { bibtex: resp.body, BTjson: resp_json }
        end
      end
    end
  end
end
