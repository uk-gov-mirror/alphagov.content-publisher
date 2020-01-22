# frozen_string_literal: true

class WhitehallDocumentImportWipJob < ApplicationJob
  retry_on(GdsApi::BaseError, attempts: 5) do |job, error|
    handle_error
  end

  discard_on(StandardError) do |job, error|
    handle_error
  end

  def perform(document_import)
    return if document_import.completed?

    if document_import.pending?
      WhitehallImporter::Import.call(document_import)
    end

    WhitehallImporter::Sync.call(document_import)
  end

  def handle_error(document_import, error)
    if document_import.pending?
      unlock_whitehall
    end

    case error
    when WhitehallImporter::IntegrityCheckError
    when WhitehallImporter::AbortImportError
    else
      document_import.update!(
        state: document_import.imported? ? :sync_failed : :import_failed
      )
    end
  end
end
