# frozen_string_literal: true

RSpec.describe Tasks::WhitehallImporter do
  include FixturesHelper

  let(:import_data) { whitehall_export_with_one_edition }

  before do
    stub_network_requests_to_whitehall_images
  end

  it "can import JSON data from Whitehall" do
    importer = Tasks::WhitehallImporter.new(123, import_data)

    expect { importer.import }.to change { Document.count }.by(1)

    imported_edition = import_data["editions"][0]
    edition = Edition.last

    expect(edition.summary)
      .to eq(imported_edition["translations"][0]["summary"])

    expect(edition.number).to eql(1)
    expect(edition.status).to be_draft
    expect(edition.update_type).to eq("major")
  end

  it "adds users who have never logged into Content Publisher" do
    importer = Tasks::WhitehallImporter.new(123, import_data)
    importer.import

    expect(User.last.uid).to eq "36d5154e-d3b7-4e3e-aad8-32a50fc9430e"
    expect(User.last.name).to eq "A Person"
    expect(User.last.email).to eq "a-publisher@department.gov.uk"
    expect(User.last.organisation_slug).to eq "a-government-department"
    expect(User.last.organisation_content_id).to eq "01892f23-b069-43f5-8404-d082f8dffcb9"
  end

  it "does not add users who have logged into Content Publisher" do
    importer = Tasks::WhitehallImporter.new(123, import_data)
    User.create!(uid: "36d5154e-d3b7-4e3e-aad8-32a50fc9430e")

    expect { importer.import }.not_to(change { User.count })
  end

  it "creates a user map" do
    importer = Tasks::WhitehallImporter.new(123, import_data)
    importer.import

    expected_user_ids = {
      1 => User.last.id,
    }

    expect(importer.user_ids).to eq(expected_user_ids)
  end

  it "sets created_by_id as the original author" do
    importer = Tasks::WhitehallImporter.new(123, import_data)
    importer.import

    expect(Document.last.created_by_id).to eq(User.last.id)
  end

  it "sets import_from as Whitehall" do
    importer = Tasks::WhitehallImporter.new(123, import_data)
    importer.import

    document = Document.last
    expect(document.imported_from_whitehall?).to be true
  end

  it "sets the correct states when Whitehall document state is 'published'" do
    import_data["editions"][0]["state"] = "published"
    importer = Tasks::WhitehallImporter.new(123, import_data)
    importer.import

    expect(Edition.last.status).to be_published
    expect(Edition.last).to be_live
  end

  it "can set minor update type" do
    import_data["editions"][0]["minor_change"] = true
    importer = Tasks::WhitehallImporter.new(123, import_data)
    importer.import

    expect(Edition.last.update_type).to eq("minor")
  end

  it "sets the correct states when Whitehall document is force published" do
    import_data["editions"][0]["state"] = "published"
    import_data["editions"][0]["force_published"] = true
    importer = Tasks::WhitehallImporter.new(123, import_data)
    importer.import

    expect(Edition.last.status).to be_published_but_needs_2i
    expect(Edition.last).to be_live
  end

  it "sets the correct states when Whitehall document state is 'rejected'" do
    import_data["editions"][0]["state"] = "rejected"
    importer = Tasks::WhitehallImporter.new(123, import_data)
    importer.import

    expect(Edition.last.status).to be_submitted_for_review
    expect(Edition.last).not_to be_live
  end

  it "sets the correct states when Whitehall document state is 'submitted'" do
    import_data["editions"][0]["state"] = "submitted"
    importer = Tasks::WhitehallImporter.new(123, import_data)
    importer.import

    expect(Edition.last.status).to be_submitted_for_review
    expect(Edition.last).not_to be_live
  end

  it "raises AbortImportError when edition has an unsupported state" do
    import_data["editions"][0]["state"] = "not_supported"
    importer = Tasks::WhitehallImporter.new(123, import_data)

    expect { importer.import }.to raise_error(Tasks::AbortImportError)
  end

  it "raises AbortImportError when edition has an unsupported locale" do
    import_data["editions"][0]["translations"][0]["locale"] = "zz"
    importer = Tasks::WhitehallImporter.new(123, import_data)

    expect { importer.import }.to raise_error(Tasks::AbortImportError)
  end

  it "changes the ids of embedded contacts" do
    import_data["editions"][0]["translations"][0]["body"] = "[Contact:123]"
    content_id = SecureRandom.uuid
    import_data["editions"][0]["contacts"] = [{ "id" => 123, "content_id" => content_id }]
    importer = Tasks::WhitehallImporter.new(123, import_data)
    importer.import

    expect(Edition.last.contents["body"]).to eq("[Contact:#{content_id}]")
  end

  it "sets role appointments" do
    importer = Tasks::WhitehallImporter.new(123, import_data)
    importer.import

    imported_role_appointment = import_data["editions"][0]["role_appointments"][0]
    edition = Edition.last

    expect(edition.tags["role_appointments"].first).to eq(imported_role_appointment["content_id"])
  end

  it "sets topical events" do
    importer = Tasks::WhitehallImporter.new(123, import_data)
    importer.import

    imported_topical_events = import_data["editions"][0]["topical_events"][0]
    edition = Edition.last

    expect(edition.tags["topical_events"].first).to eq(imported_topical_events["content_id"])
  end

  it "sets world locations" do
    importer = Tasks::WhitehallImporter.new(123, import_data)
    importer.import

    imported_world_locations = import_data["editions"][0]["world_locations"][0]
    edition = Edition.last

    expect(edition.tags["world_locations"].first).to eq(imported_world_locations["content_id"])
  end

  context "when importing organisation associations" do
    it "sets a primary_publishing_organisation" do
      importer = Tasks::WhitehallImporter.new(123, import_data)
      importer.import

      imported_organisation = import_data["editions"][0]["organisations"][0]
      edition = Edition.last

      expect(edition.primary_publishing_organisation_id).to eq(imported_organisation["content_id"])
    end

    it "rejects the import if there are no organisations" do
      import_data["editions"][0].delete("organisations")
      importer = Tasks::WhitehallImporter.new(123, import_data)

      expect { importer.import }.to raise_error(Tasks::AbortImportError)
    end

    it "rejects the import if there are no lead organisations" do
      import_data["editions"][0]["organisations"].shift
      importer = Tasks::WhitehallImporter.new(123, import_data)

      expect { importer.import }.to raise_error(Tasks::AbortImportError)
    end

    it "rejects the import if there is more than one lead organisation" do
      import_data["editions"][0]["organisations"].push(
        "id" => 3,
        "content_id" => SecureRandom.uuid,
        "lead" => true,
        "lead_ordering" => 2,
      )

      importer = Tasks::WhitehallImporter.new(123, import_data)

      expect { importer.import }.to raise_error(Tasks::AbortImportError)
    end

    it "sets other supporting organisations" do
      importer = Tasks::WhitehallImporter.new(123, import_data)
      importer.import

      imported_organisation = import_data["editions"][0]["organisations"][1]
      edition = Edition.last

      expect(edition.supporting_organisation_ids.first).to eq(imported_organisation["content_id"])
    end
  end

  context "when importing images" do
    let(:edition) { Edition.last }
    let(:revision) { Revision.last }
    let(:image) { Image.last }
    let(:image_metadata_revision) { Image::MetadataRevision.last }
    let(:image_blob_revision) { Image::BlobRevision.last }
    let(:importer) { Tasks::WhitehallImporter.new(123, import_data) }

    context "when there is one image" do
      let(:import_data) { whitehall_export_with_images("single_image.json") }

      before { importer.import }

      subject do
        import_data["editions"][0]["images"][0]
      end

      it "creates an Image" do
        expect(image.created_by_id).to be_nil
        expect(image.created_at).to eq(subject["created_at"])
      end

      it "creates an Image::BlobRevision" do
        expect(image_blob_revision.content_type).to eq("image/jpeg")
        expect(image_blob_revision.blob.class.name).to eq("ActiveStorage::Blob")
        expect(image_blob_revision.filename).to eq("some-image.jpg")
      end

      it "creates an Image::MetadataRevision" do
        expect(image_metadata_revision.caption).to eq(subject["caption"])
        expect(image_metadata_revision.alt_text).to eq(subject["alt_text"])
        expect(image_metadata_revision.created_at).to eq(subject["created_at"])
        expect(image_metadata_revision.credit).to be_nil
        expect(image_metadata_revision.created_by_id).to be_nil
      end

      it "creates an Image::MetadataRevision" do
        expect(image_metadata_revision.caption).to eq(subject["caption"])
        expect(image_metadata_revision.alt_text).to eq(subject["alt_text"])
        expect(image_metadata_revision.created_at).to eq(subject["created_at"])
        expect(image_metadata_revision.credit).to be_nil
        expect(image_metadata_revision.created_by_id).to be_nil
      end

      it "creates an Image::Revision that references all the above" do
        image_revision = edition.image_revisions.first
        expect(edition.revisions.last).to eq(revision)
        expect(image_revision.image).to eq(image)
        expect(image_revision.blob_revision).to eq(image_blob_revision)
        expect(image_revision.metadata_revision).to eq(image_metadata_revision)
        expect(image_revision.revisions.last).to eq(revision)
      end
    end

    context "there are multiple images to import" do
      let(:import_data) { whitehall_export_with_images("multiple_images.json") }

      before { importer.import }

      it "imports all images" do
        expect(edition.image_revisions.count).to eq(2)

        first_image = edition.image_revisions.first
        second_image = edition.image_revisions.last

        expect(first_image.image).to eq(Image.first)
        expect(first_image.blob_revision).to eq(Image::BlobRevision.first)
        expect(first_image.metadata_revision).to eq(Image::MetadataRevision.first)

        expect(second_image.image).to eq(Image.last)
        expect(second_image.blob_revision).to eq(Image::BlobRevision.last)
        expect(second_image.metadata_revision).to eq(Image::MetadataRevision.last)
      end
    end

    context "there are multiple images to import, with the same name" do
      let(:import_data) { whitehall_export_with_images("multiple_images_with_same_name.json") }

      before { importer.import }

      it "renames the file so that it's unique" do
        expect(edition.image_revisions.count).to eq(2)
        expect(Image::BlobRevision.first.filename).to eq("some-image.jpg")
        expect(Image::BlobRevision.last.filename).to eq("some-image-1.jpg")
      end
    end

    context "image has no caption" do
      let(:import_data) { whitehall_export_with_images("image_without_a_caption.json") }

      before { importer.import }

      it "imports successfully, setting caption to empty string" do
        expect(image_metadata_revision.caption).to eq("")
        expect(image_blob_revision.filename).to eq("some-image.jpg")
      end
    end

    context "image is not 960x640" do
      let(:import_data) { whitehall_export_with_images("1000x1000.json") }

      it "aborts the import" do
        expect { importer.import }.to raise_error(Tasks::AbortImportError)
      end
    end

    context "first image is an SVG" do
      let(:import_data) { whitehall_export_with_images("contains_svg.json") }

      it "aborts the import" do
        expect { importer.import }.to raise_error(Tasks::AbortImportError)
      end
    end

    context "one of the latter images is an SVG" do
      let(:import_data) { whitehall_export_with_images("contains_valid_images_and_one_svg.json") }

      it "aborts the import" do
        expect { importer.import }.to raise_error(Tasks::AbortImportError)
      end

      it "should not have created any of the preceding images" do
        begin
          importer.import
        rescue Tasks::AbortImportError
          expect(Image.count).to eq(0)
          expect(Image::BlobRevision.count).to eq(0)
          expect(Image::MetadataRevision.count).to eq(0)
          expect(Revision.count).to eq(0)
          expect(Edition.count).to eq(0)
        end
      end
    end

    context "the same image is referenced across multiple editions" do
      let(:import_data) do
        whitehall_export_with_two_editions_and_images(
          "single_image.json",
          "single_image.json",
        )
      end

      before { importer.import }

      it "should import the images twice - we don't mind" do
        expect(Revision.count).to eq(2)
        expect(Edition.count).to eq(2)
        expect(Image.count).to eq(2)
        expect(Image::BlobRevision.count).to eq(2)
        expect(Image::MetadataRevision.count).to eq(2)
      end
    end
  end

  context "when an imported document has more than one edition" do
    let(:import_published_then_drafted_data) { whitehall_export_with_two_editions }

    it "only creates the latest edition" do
      importer = Tasks::WhitehallImporter.new(123, import_published_then_drafted_data)
      importer.import

      expect(Edition.last.status).to be_draft
      expect(Edition.last).not_to be_live
    end

    it "sets imported to true on revision" do
      importer = Tasks::WhitehallImporter.new(123, import_published_then_drafted_data)
      importer.import

      expect(Revision.last.imported).to be true
    end

    it "sets created_by_id on each edition as the original edition author" do
      importer = Tasks::WhitehallImporter.new(123, import_published_then_drafted_data)
      importer.import

      expect(Edition.second_to_last.created_by_id).to eq(User.second_to_last.id)
      expect(Edition.last.created_by_id).to eq(User.last.id)
    end

    it "sets last_edited_by_id on each edition as the most recent author" do
      importer = Tasks::WhitehallImporter.new(123, import_published_then_drafted_data)
      importer.import

      expect(Edition.second_to_last.last_edited_by_id).to eq(User.second_to_last.id)
      expect(Edition.last.last_edited_by_id).to eq(User.second_to_last.id)
    end

    it "raises AbortImportError when an edition has an unsupported document type" do
      import_published_then_drafted_data["editions"][0]["news_article_type"] = "unsupported_document"
      importer = Tasks::WhitehallImporter.new(123, import_published_then_drafted_data)

      expect { importer.import }.to raise_error(Tasks::AbortImportError)
    end
  end
end
