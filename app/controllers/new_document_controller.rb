# frozen_string_literal: true

class NewDocumentController < ApplicationController
  def choose_document_type # GET
    render :choose_document_type,
            assigns: { issues: issues, id: id }
  end

  def choose_or_create_document_type # POST
    result = NewDocument::DocumentTypeSelectionInteractor.call(params: params, user: current_user)

    if result.issues
      flash.now["requirements"] = { "items" => issues.items }

      render :choose_supertype,
             assigns: { issues: issues },
             status: :unprocessable_entity
    elsif result.refine_further
      redirect_to refine_further
    elsif result.managed_elsewhere
      redirect_to managed_elsewhere
    elsif result.created_document_path
      redirect_to created_document_path
    end
  end
end
