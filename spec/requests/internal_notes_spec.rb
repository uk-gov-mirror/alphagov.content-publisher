# frozen_string_literal: true

RSpec.describe "Internal notes" do
  describe "POST /documents/:document/internal-notes" do
    it "returns a redirect to document history" do
      edition = create(:edition)
      note = SecureRandom.alphanumeric(8)
      post create_internal_note_path(edition.document),
           params: { internal_note: note }

      expect(response).to redirect_to(
        document_path(edition.document, anchor: "document-history"),
      )
      follow_redirect!
      expect(response.body).to include(note)
    end
  end
end
