# frozen_string_literal: true

RSpec.feature "Force publishing" do
  scenario "User force publishes and approves a document retroactively" do
    given_there_is_a_document
    when_i_visit_the_document_page
    and_i_click_on_the_publish_button
    and_i_say_that_the_document_has_not_been_reviewed
    and_i_confirm_the_publishing
    then_i_see_that_the_document_was_force_published

    when_i_visit_the_document_page
    and_i_click_the_approval_button
    then_i_see_that_its_reviewed
  end

  def given_there_is_a_document
    @document = create(:document, publication_state: "sent_to_draft")
  end

  def when_i_visit_the_document_page
    visit document_path(@document)
  end

  def and_i_click_on_the_publish_button
    click_on "Publish"
  end

  def and_i_say_that_the_document_has_not_been_reviewed
    choose "This content needs to be published urgently but should be reviewed as soon as possible"
  end

  def and_i_confirm_the_publishing
    # We don't care about what kind of request is done here, this is tested in
    # the main publishing feature test
    stub_any_publishing_api_publish

    click_on "Confirm publish"
  end

  def then_i_see_that_the_document_was_force_published
    expect(page).to have_content("Content has been published but still needs 2i review")
  end

  def and_i_click_the_approval_button
    click_on "Approve"
  end

  def then_i_see_that_its_reviewed
    expect(page).to have_content "Content has been reviewed and approved"
  end
end
