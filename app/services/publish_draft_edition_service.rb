# frozen_string_literal: true

class PublishDraftEditionService < ApplicationService
  def initialize(edition, user, with_review:)
    @edition = edition
    @user = user
    @with_review = with_review
  end

  def call
    check_publishable
    publish_assets
    set_publishing_time
    associate_with_government
    update_publishing_api_draft
    publish_current_edition
    supersede_live_edition
    set_new_live_edition
  rescue GdsApi::BaseError => e
    GovukError.notify(e)
    raise
  end

private

  attr_reader :edition, :user, :with_review
  delegate :document, to: :edition

  def check_publishable
    raise "Only a current edition can be published" unless edition.current?
    raise "Live editions cannot be published" if edition.live?
  end
  
  def publish_assets
    PublishAssetsService.call(edition, document.live_edition)
  end
  
  def set_publishing_time
    now = Time.current
    edition.published_at = now
    document.first_published_at = now unless document.first_published_at
  end

  def associate_with_government
    return if edition.government

    repository = BulkData::GovernmentRepository.new
    government = if edition.public_first_published_at
                   repository.for_date(edition.public_first_published_at)
                 else
                   repository.current
                 end
    edition.government_id = government&.content_id
  end

  def publish_current_edition
    GdsApi.publishing_api.publish(
      document.content_id,
      nil, # Sending update_type is deprecated (now in payload)
      locale: document.locale,
    )
  end

  def update_publishing_api_draft
    return if edition.minor? && !edition.government_id_changed?
    
    PreviewDraftEditionService.call(edition)
  end

  def supersede_live_edition
    live_edition = document.live_edition
    return unless live_edition

    AssignEditionStatusService.call(live_edition, user, :superseded, record_edit: false)
    live_edition.live = false
    live_edition.save!
  end

  def set_new_live_edition
    status = with_review ? :published : :published_but_needs_2i
    AssignEditionStatusService.call(edition, user, status)
    edition.access_limit = nil
    edition.live = true
    edition.save!
    document.reload_live_edition
  end
end
