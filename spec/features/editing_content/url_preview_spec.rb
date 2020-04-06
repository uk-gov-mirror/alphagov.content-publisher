RSpec.feature "Shows a preview of the URL", js: true do
  given(:document_type) do
    build(:document_type, contents: [DocumentType::TitleAndBasePathField.new])
  end

  given(:edition) { create(:edition, document_type: document_type) }

  scenario do
    when_i_go_to_edit_the_edition
    and_i_delete_the_title
    then_i_see_a_prompt_to_enter_a_title
    and_i_fill_in_the_title
    then_i_see_a_preview_of_the_url_on_govuk
  end

  def when_i_go_to_edit_the_edition
    visit document_path(edition.document)
    click_on "Change Content"
  end

  def and_i_delete_the_title
    fill_in("title", with: "")
    page.find("body").click
  end

  def then_i_see_a_prompt_to_enter_a_title
    expect(page).to have_content(I18n.t!("content.edit.url_preview.no_title"))
  end

  def and_i_fill_in_the_title
    fill_in("title", with: "A great title")
    page.find("body").native.send_keys :tab
  end

  def then_i_see_a_preview_of_the_url_on_govuk
    url = "www.test.gov.uk#{document_type.path_prefix}/a-great-title"
    expect(page).to have_content(url)
  end
end
