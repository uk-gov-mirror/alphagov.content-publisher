# frozen_string_literal: true

module WhitehallImporter
  class IntegrityChecker
    attr_reader :edition

    def initialize(edition)
      @edition = edition
    end

    def valid?
      problems.empty?
    end

    def problems
      problems = []

      %w(base_path title).each do |attribute|
        if publishing_api_content[attribute] != proposed_payload[attribute]
          problems << "#{attribute} doesn't match"
        end
      end

      problems
    end

  private

    def proposed_payload
      @proposed_payload ||= PreviewService::Payload.new(edition, republish: edition.live?).payload
    end

    def publishing_api_content
      @publishing_api_content ||= GdsApi.publishing_api.get_content(edition.content_id).to_h
    end
  end
end
