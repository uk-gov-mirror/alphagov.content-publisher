RSpec.feature "Viewing debug information" do
  given(:edition_with_revisions) do
    create(:edition).tap do |edition|
      revisions = create_list(:revision, 25, document: edition.document)
      edition.update!(revision: revisions.last)
    end
  end

  scenario do
    when_i_dont_have_the_debug_permission
    and_i_visit_the_debug_page
    then_i_see_an_error_page
    when_im_given_debug_permission
    and_i_visit_the_debug_page
    then_i_see_the_debug_page
    and_i_can_paginate_to_the_next_page
  end

  def and_i_visit_the_debug_page
    visit debug_document_path(edition_with_revisions.document)
  end

  def when_i_dont_have_the_debug_permission
    login_as(create(:user))
  end

  def then_i_see_an_error_page
    expect(page).to have_content(
      "Sorry, you don't seem to have the #{User::DEBUG_PERMISSION} permission for this app",
    )
  end

  def when_im_given_debug_permission
    current_user.update_attribute(:permissions, [User::DEBUG_PERMISSION])
  end

  def then_i_see_the_debug_page
    expect(page).to have_content(
      "Revision history for ‘#{edition_with_revisions.title_or_fallback}’",
    )
  end

  def and_i_can_paginate_to_the_next_page
    click_on "Next page"
    expect(page).to have_content("Revision 1")
  end
end
