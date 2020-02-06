# frozen_string_literal: true

class NewDocument::DocumentTypeSelectionInteractor < ApplicationInteractor
  delegate :params,
           :user,
           :document_type,
           :redirect_url,
           :document,
           to: :context


  def call
    check_for_issues

    if DocumentTypeSelection.find_page(params[:document_type])
      # there are subtypes to choose from
      context.needs_refining = true
    else
      # we've made our choice - it's either managed elsewhere or it's a doc we can create
      selection = DocumentTypeSelection.find_option(params[:document_type])

      case selection["type"]
      when "managed_elsewhere"
        context.redirect_url = selection["managed_elsewhere_url"]
      when "document_type"
        create_document(selection)
        create_timeline_entry
      end
    end
  end

private

  def check_for_issues
    return if params[:document_type].present?

    context.fail!(issues: document_type_selection_issues)
  end

  def document_type_selection_issues
    Requirements::CheckerIssues.new([
      Requirements::Issue.new(:document_type, :not_selected),
    ])
  end

  def create_document(document_type)
    context.document = CreateDocumentService.call(
      document_type_id: document_type["id"], tags: default_tags, user: user,
    )
  end

  def create_timeline_entry
    TimelineEntry.create_for_status_change(entry_type: :created,
                                           status: document.current_edition.status)
  end

  def default_tags
    user.organisation_content_id ? { primary_publishing_organisation: [user.organisation_content_id] } : {}
  end
end
