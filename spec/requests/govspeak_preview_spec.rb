# frozen_string_literal: true

RSpec.describe "Govspeak Preview" do
  describe "POST /documents/:document/govspeak-preview" do
    it "returns rendered govspeak in a govspeak component" do
      edition = create(:edition)

      post govspeak_preview_path(edition.document),
           params: { govspeak: "## Test" }

      expect(response).to be_successful
      expect(response.media_type).to eq("text/html")
      expect(response.body).to have_tag(".gem-c-govspeak") do
        with_tag("h2", text: "Test")
      end
    end
  end
end
