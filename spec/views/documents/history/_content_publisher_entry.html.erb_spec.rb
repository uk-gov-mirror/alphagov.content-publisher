RSpec.describe "documents/history/_content_publisher_entry.html.erb" do
  it "shows a timeline entry without an author" do
    allow(view).to receive(:entry) { create(:timeline_entry, created_by: nil) }
    render
    expect(rendered).not_to have_content(I18n.t!("documents.history.by"))
    expect(rendered).to have_content(I18n.t!("documents.history.entry_types.created"))
  end

  it "shows a timeline entry with an author" do
    allow(view).to receive(:entry) { create(:timeline_entry) }
    render
    expect(rendered).to have_content(I18n.t!("documents.history.by") + " John Smith")
    expect(rendered).to have_content(I18n.t!("documents.history.entry_types.created"))
  end

  it "shows a timeline entry with content" do
    allow(view).to receive(:entry) do
      create(:timeline_entry,
             entry_type: :internal_note,
             details: create(:internal_note))
    end

    render
    expect(rendered).to have_selector(".app-timeline-entry__content",
                                      text: "Amazing internal note")
    expect(rendered).to have_content(I18n.t!("documents.history.entry_types.internal_note"))
  end

  context "when the timeline entry is for a removal" do
    it "can show an explanatory_note" do
      allow(view).to receive(:entry) do
        removal = create(:removal, explanatory_note: "My note")
        create(:timeline_entry, entry_type: :removed, details: removal)
      end

      render
      expect(rendered).to have_content("My note")
    end

    it "can show a link to an alternative URL" do
      allow(view).to receive(:entry) do
        removal = create(:removal, alternative_url: "https://example.com")
        create(:timeline_entry, entry_type: :removed, details: removal)
      end

      render
      alternative_url = I18n.t!("documents.history.entry_content.alternative_url")
      expect(rendered).to have_content("#{alternative_url} https://example.com",
                                       normalize_ws: true)
      expect(rendered).to have_link("https://example.com",
                                    href: "https://example.com")
    end

    it "can show a link to an alternative URL that is a path" do
      allow(view).to receive(:entry) do
        removal = create(:removal, alternative_url: "/path")
        create(:timeline_entry, entry_type: :removed, details: removal)
      end

      render
      expect(rendered).to have_link("https://www.test.gov.uk/path",
                                    href: "https://www.test.gov.uk/path")
    end

    it "can show a redirect" do
      allow(view).to receive(:entry) do
        removal = create(:removal, redirect: true, alternative_url: "https://example.com")
        create(:timeline_entry, entry_type: :removed, details: removal)
      end

      render
      redirected_to = I18n.t!("documents.history.entry_content.redirected_to")
      expect(rendered).to have_content("#{redirected_to} https://example.com",
                                       normalize_ws: true)
    end
  end
end
