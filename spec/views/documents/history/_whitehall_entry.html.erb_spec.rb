RSpec.describe "documents/history/_whitehall_entry.html.erb" do
  it "shows an imported timeline entry without an author" do
    allow(view).to receive(:entry) do
      create(:timeline_entry,
             :whitehall_imported,
             whitehall_entry_type: :new_edition,
             created_by: nil)
    end

    render
    expect(rendered).not_to have_content(I18n.t!("documents.history.by"))
    expect(rendered).to have_content(I18n.t!("documents.history.entry_types.whitehall_migration.new_edition"))
  end

  it "shows an imported timeline entry with an author" do
    allow(view).to receive(:entry) do
      create(:timeline_entry,
             :whitehall_imported,
             whitehall_entry_type: :new_edition)
    end

    render
    expect(rendered).to have_content(I18n.t!("documents.history.by") + " John Smith")
    expect(rendered).to have_content(I18n.t!("documents.history.entry_types.whitehall_migration.new_edition"))
  end

  it "does not highlight an imported internal note timeline entry without content" do
    allow(view).to receive(:entry) do
      create(:timeline_entry,
             :whitehall_imported,
             whitehall_entry_type: :internal_note)
    end

    render
    expect(rendered).not_to have_selector(".app-timeline-entry--highlighted")
  end

  it "shows the contents of an imported internal note timeline entry" do
    allow(view).to receive(:entry) do
      create(:timeline_entry,
             :whitehall_imported,
             whitehall_entry_type: :internal_note,
             whitehall_entry_contents: { body: "Note" })
    end

    render
    expect(rendered).to have_content("Note")
    expect(rendered).to have_selector(".app-timeline-entry--highlighted")
  end

  it "does not highlight an imported fact check request timeline entry without content" do
    allow(view).to receive(:entry) do
      create(:timeline_entry,
             :whitehall_imported,
             whitehall_entry_type: :fact_check_request)
    end

    render
    expect(rendered).not_to have_selector(".app-timeline-entry--highlighted")
  end

  it "shows the contents of an imported fact check request timeline entry" do
    email = "someone@somewhere.com"
    instructions = "Do something, then do something else"
    allow(view).to receive(:entry) do
      create(:timeline_entry,
             :whitehall_imported,
             whitehall_entry_type: :fact_check_request,
             whitehall_entry_contents: { email_address: email, instructions: instructions })
    end

    render
    expect(rendered).to have_content(email)
    expect(rendered).to have_content(instructions)
    expect(rendered).to have_selector(".app-timeline-entry--highlighted")
  end

  it "does not highlight an imported fact check response timeline entry without content" do
    allow(view).to receive(:entry) do
      create(:timeline_entry,
             :whitehall_imported,
             whitehall_entry_type: :fact_check_response)
    end

    render
    expect(rendered).not_to have_selector(".app-timeline-entry--highlighted")
  end

  it "shows the contents of an imported fact check response timeline entry" do
    email = "someone@somewhere.com"
    comments = "I have done what you requested"
    allow(view).to receive(:entry) do
      create(:timeline_entry,
             :whitehall_imported,
             whitehall_entry_type: :fact_check_response,
             whitehall_entry_contents: { email_address: email, comments: comments })
    end

    render
    expect(rendered).to have_content(email)
    expect(rendered).to have_content(comments)
    expect(rendered).to have_selector(".app-timeline-entry--highlighted")
  end
end
