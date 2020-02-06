# frozen_string_literal: true

class NewDocumentController < ApplicationController
  def choose_document_type
    @document_type_selection = DocumentTypeSelection.find_page(params[:document_type] || "root")
  end

  def create
    result = NewDocument::DocumentTypeSelectionInteractor.call(params: params, user: current_user)
    issues, document, redirect_url, needs_refining = result.to_h.values_at(:issues,
                                                                           :document,
                                                                           :redirect_url,
                                                                           :needs_refining)

    if issues
      flash.now["requirements"] = { "items" => issues.items }

      render :choose_document_type,
             assigns: { issues: issues, document_type_selection: DocumentTypeSelection.find(params[:document_type]) },
             status: :unprocessable_entity
    elsif needs_refining
      redirect_to new_document_path(document_type: params[:document_type])
    elsif document
      redirect_to content_path(document)
    elsif redirect_url
      redirect_to redirect_url
    end
  end
end
