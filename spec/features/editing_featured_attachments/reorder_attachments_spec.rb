RSpec.feature "Reorder attachments" do
  given(:first_attachment_revision) { create(:file_attachment_revision) }
  given(:second_attachment_revision) { create(:file_attachment_revision) }
  given(:edition_with_attachments) do
    create(:edition,
           document_type: build(:document_type, attachments: "featured"),
           file_attachment_revisions: [first_attachment_revision,
                                       second_attachment_revision])
  end

  before do
    stub_any_publishing_api_put_content
    stub_asset_manager_receives_an_asset
  end

  scenario "without javascript" do
    when_i_go_to_the_attachments_page
    and_i_click_to_reorder_the_attachments
    then_i_see_the_current_attachment_order
    and_i_change_the_numeric_positions
    then_i_see_the_order_is_updated
    and_i_see_the_timeline_entry
  end

  scenario "with javascript", js: true do
    when_i_go_to_the_attachments_page
    and_i_click_to_reorder_the_attachments
    then_i_see_the_current_attachment_order
    and_i_move_an_attachment_up
    then_i_see_the_order_is_updated
    and_i_see_the_timeline_entry
  end

  def when_i_go_to_the_attachments_page
    visit featured_attachments_path(edition_with_attachments.document)
  end

  def and_i_click_to_reorder_the_attachments
    click_on "Reorder attachments"
  end

  def then_i_see_the_current_attachment_order
    expect(all(".app-c-reorderable-list__title").map(&:text)).to eq([
      first_attachment_revision.title, second_attachment_revision.title
    ])
  end

  def and_i_change_the_numeric_positions
    fill_in "Position for #{first_attachment_revision.title}", with: 2
    fill_in "Position for #{second_attachment_revision.title}", with: 1
    click_on "Save attachment order"
  end

  def and_i_move_an_attachment_up
    all("button", text: "Up").last.click
    click_on "Save attachment order"
  end

  def then_i_see_the_order_is_updated
    expect(all(".gem-c-attachment__title").map(&:text)).to eq([
      second_attachment_revision.title,
      first_attachment_revision.title,
    ])
  end

  def and_i_see_the_timeline_entry
    visit document_path(edition_with_attachments.document)
    click_on "Document history"
    expect(page).to have_content I18n.t!("documents.history.entry_types.attachments_reordered")
  end
end
