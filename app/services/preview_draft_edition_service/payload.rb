# frozen_string_literal: true

class PreviewDraftEditionService::Payload
  PUBLISHING_APP = "content-publisher"

  attr_reader :edition, :document_type, :publishing_metadata, :republish

  def initialize(edition, republish: false)
    @edition = edition
    @document_type = edition.document_type
    @publishing_metadata = document_type.publishing_metadata
    @republish = republish
  end

  def payload
    payload = {
      "base_path" => edition.base_path,
      "title" => edition.title,
      "locale" => edition.locale,
      "description" => edition.summary,
      "schema_name" => publishing_metadata.schema_name,
      "document_type" => document_type.id,
      "publishing_app" => PUBLISHING_APP,
      "rendering_app" => publishing_metadata.rendering_app,
      "update_type" => edition.update_type,
      "details" => details,
      "routes" => [
        { "path" => edition.base_path, "type" => "exact" },
      ],
      "links" => links,
      "access_limited" => access_limited,
      "auth_bypass_ids" => auth_bypass_ids,
      "first_published_at" = history.first_published_at,
      "public_updated_at" = history.public_updated_at,
    }

    if republish
      payload["update_type"] = "republish"
      payload["bulk_publishing"] = true
    end

    payload
  end

private

  def history
    @history ||= History.new(ediiton)
  end

  def access_limited
    return {} unless edition.access_limit

    { "organisations" => edition.access_limit_organisation_ids }
  end

  def auth_bypass_ids
    auth_bypass_id = PreviewAuthBypass.new(edition).auth_bypass_id
    [auth_bypass_id]
  end

  def links
    links = edition.tags["primary_publishing_organisation"].to_a +
      edition.tags["organisations"].to_a

    role_appointments = edition.tags["role_appointments"]
    edition.tags
      .except("role_appointments")
      .merge(roles_and_people(role_appointments))
      .merge("organisations" => links.uniq)
      .merge("government" => [edition.government&.content_id].compact)
  end

  def image
    {
      "high_resolution_url" => edition.lead_image_revision.asset_url("high_resolution"),
      "url" => edition.lead_image_revision.asset_url("300"),
      "alt_text" => edition.lead_image_revision.alt_text,
      "caption" => edition.lead_image_revision.caption,
      "credit" => edition.lead_image_revision.credit,
    }
  end

  def details
    details = {
      "political" => edition.political?,
      "change_history" => history.change_history.as_json,
    }

    document_type.contents.each do |field|
      details[field.id] = perform_input_type_specific_transformations(field)
    end

    if document_type.images && edition.lead_image_revision.present?
      details["image"] = image
    end

    details
  end

  def roles_and_people(role_appointments)
    return {} if !role_appointments || role_appointments.count.zero?

    role_appointments
      .each_with_object("roles" => [], "people" => []) do |appointment_id, memo|
        response = GdsApi.publishing_api.get_links(appointment_id).to_hash

        roles = response.dig("links", "role") || []
        people = response.dig("links", "person") || []

        memo["roles"] = (memo["roles"] + roles).uniq
        memo["people"] = (memo["people"] + people).uniq
      end
  end

  # Note: once this grows to a sufficient size, move it over into a new class
  # or class system.
  def perform_input_type_specific_transformations(field)
    if field.type == "govspeak"
      GovspeakDocument.new(edition.contents[field.id], edition).payload_html
    else
      document.contents[field.id]
    end
  end

  # This expects the following changes to Content Publisher modelling
  # - Document
  #   - first_published_at - a timestamp that matches when the content was
  #     first published in Content Publisher.
  # - Edition
  #   - published_at - a timestamp that when the content is first published
  #     in Content Publisher.
  # - Revision
  #   - change_note - no longer stores the initial "First published." change
  #     note as this is special and not entered by a user.
  #   - change_history - stores an array of hashes of past change notes. Does
  #     not include the special first published note
  class History
    FIRST_CHANGE_NOTE = "First published."

    def initialize(edition)
      @edition = edition
    end

    def public_updated_at
      change_history.first&.fetch(:public_timestamp)
    end

    def first_published_at
      return edition.backdated_to if edition.backdated_to.present?

      edition.document.first_published_at
    end

    def change_history
      change_history = edition.change_history.map do |item|
        { note: item.fetch(:note), public_timestamp: item.fetch(:public_timestamp).in_time_zone }
      end

      change_history << { note: FIRST_CHANGE_NOTE,
                          public_timestamp: first_published_at || Time.current }

      if edition.change_note && edition.major && !edition.first?
        change_history << { note: edition.change_note,
                            public_timestamp: time || Time.current }
      end

      change_history.reject { |note| note[:public_timestamp] < first_published_at }
                    .sort_by { |note| note[:public_timestamp] }
                    .reverse
    end

  private

    attr_reader :edition
  end
end
