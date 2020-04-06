RSpec.feature "Insert inline image" do
  given(:image_revision) do
    create(:image_revision, :on_asset_manager, filename: "foo.jpg")
  end

  given(:edition) do
    create(:edition,
           document_type: build(:document_type, :with_body),
           image_revisions: [image_revision])
  end

  scenario "with javascript", js: true do
    when_i_go_to_edit_the_edition
    and_i_click_to_insert_an_image
    and_i_choose_one_of_the_images
    then_i_see_the_snippet_is_inserted
  end

  scenario "without javascript" do
    when_i_go_to_edit_the_edition
    and_i_click_to_insert_an_image
    then_i_see_the_image_markdown_snippet
  end

  def when_i_go_to_edit_the_edition
    visit content_path(edition.document)
  end

  def and_i_click_to_insert_an_image
    within(".app-c-markdown-editor") do
      find("markdown-toolbar details").click
      click_on "Image"
    end
  end

  def and_i_choose_one_of_the_images
    click_on "Insert image markdown"
  end

  def then_i_see_the_snippet_is_inserted
    expect(page).not_to have_selector(".gem-c-modal-dialogue")
    snippet = I18n.t("images.index.meta.inline_code.value", filename: image_revision.filename)
    expect(find("#body-field").value).to include snippet
  end

  def then_i_see_the_image_markdown_snippet
    snippet = I18n.t("images.index.meta.inline_code.value", filename: image_revision.filename)
    expect(page).to have_content(snippet)
  end
end
