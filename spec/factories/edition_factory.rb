# frozen_string_literal: true

FactoryBot.define do
  factory :edition do
    last_edited_at { Time.current }
    current { true }
    live { false }
    revision_synced { true }
    association :created_by, factory: :user

    revision_fields

    transient do
      content_id { SecureRandom.uuid }
      locale { I18n.available_locales.sample }
      document_type_id { build(:document_type, path_prefix: "/prefix").id }
      state { "draft" }
      lead_image_revision { nil }
      image_revisions { [] }
      first_published_at { nil }
    end

    after(:build) do |edition, evaluator|
      unless edition.document
        edition.document = evaluator.association(
          :document,
          created_by: edition.created_by,
          content_id: evaluator.content_id,
          locale: evaluator.locale,
          document_type_id: evaluator.document_type_id,
          first_published_at: evaluator.first_published_at,
        )
      end

      edition.number = edition.document&.next_edition_number unless edition.number

      unless edition.revision
        image_revisions = if evaluator.image_revisions.any?
                            evaluator.image_revisions
                          else
                            [evaluator.lead_image_revision].compact
                          end

        edition.revision = evaluator.association(
          :revision,
          created_by: edition.created_by,
          document: edition.document,
          title: evaluator.title,
          summary: evaluator.summary,
          base_path: evaluator.base_path,
          contents: evaluator.contents,
          tags: evaluator.tags,
          update_type: evaluator.update_type,
          change_note: evaluator.change_note,
          scheduled_publishing_datetime: evaluator.scheduled_publishing_datetime,
          lead_image_revision: evaluator.lead_image_revision,
          image_revisions: image_revisions,
        )
      end

      unless edition.status
        edition.status = evaluator.association(
          :status,
          created_by: edition.created_by,
          revision_at_creation: edition.revision,
          state: evaluator.state,
        )
      end
    end

    trait :publishable do
      summary { SecureRandom.alphanumeric(10) }
    end

    trait :published do
      summary { SecureRandom.alphanumeric(10) }
      live { true }
      first_published_at { Time.current }

      after(:build) do |edition, evaluator|
        edition.status = evaluator.association(
          :status,
          created_by: edition.created_by,
          state: :published,
          revision_at_creation: edition.revision,
        )
      end
    end

    trait :withdrawn do
      summary { SecureRandom.alphanumeric(10) }
      live { true }
      first_published_at { Time.current }

      transient do
        withdrawal { nil }
      end

      after(:build) do |edition, evaluator|
        edition.revision = evaluator.association(:revision)
        edition.status = evaluator.association(
          :status,
          :withdrawn,
          created_by: edition.created_by,
          state: :withdrawn,
          revision_at_creation: edition.revision,
          withdrawal: evaluator.withdrawal,
        )
      end
    end

    trait :scheduled do
      summary { SecureRandom.alphanumeric(10) }

      transient do
        scheduling { nil }
      end

      after(:build) do |edition, evaluator|
        edition.status = evaluator.association(
          :status,
          :scheduled,
          created_by: edition.created_by,
          state: :scheduled,
          revision_at_creation: edition.revision,
          scheduling: evaluator.scheduling,
        )
      end
    end
  end
end
