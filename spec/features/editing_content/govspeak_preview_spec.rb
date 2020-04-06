RSpec.feature "Shows a preview of Govspeak", js: true do
  given(:edition) do
    document_type = build(:document_type, :with_body)
    create(:edition, document_type: document_type)
  end

  scenario do
    when_i_go_to_edit_the_edition
    and_i_enter_some_govspeak
    and_i_view_the_govspeak_preview
    then_i_see_the_rendered_govspeak
  end

  def when_i_go_to_edit_the_edition
    visit document_path(edition.document)
    click_on "Change Content"
  end

  def and_i_enter_some_govspeak
    fill_in "body", with: "$C “contact” $C"
  end

  def and_i_view_the_govspeak_preview
    click_on "Preview"
  end

  def then_i_see_the_rendered_govspeak
    expect(find(".app-c-markdown-editor__govspeak--rendered")["innerHTML"])
      .to include('<div class="contact">')
  end
end
