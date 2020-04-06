RSpec.feature "History mode" do
  given(:past_government) do
    build(
      :government,
      started_on: Time.zone.parse("2006-01-01"),
      ended_on: Time.zone.parse("2010-01-01"),
    ).tap { |g| populate_government_bulk_data(g) }
  end

  given(:not_political_edition) { create(:edition, :not_political) }

  background { login_as(create(:user, managing_editor: true)) }

  scenario do
    when_i_visit_the_summary_page
    then_i_see_that_the_content_doesnt_get_history_mode
    and_i_do_not_see_the_history_mode_banner

    when_i_click_to_change_the_status
    then_i_enable_political_status
    and_i_see_that_the_content_gets_history_mode
    and_i_see_the_timeline_entry
    and_i_do_not_see_the_history_mode_banner

    when_i_click_to_backdate_the_content
    and_i_enter_a_date_to_backdate_the_content_to
    and_i_see_the_history_mode_banner
  end

  def when_i_visit_the_summary_page
    visit document_path(not_political_edition.document)
  end

  def then_i_see_that_the_content_doesnt_get_history_mode
    row = page.find(".govuk-summary-list__row", text: I18n.t!("documents.show.content_settings.gets_history_mode.title"))
    expect(row).to have_content(
      I18n.t!("documents.show.content_settings.gets_history_mode.false_label"),
    )
  end

  def and_i_see_that_the_content_gets_history_mode
    row = page.find(".govuk-summary-list__row", text: I18n.t!("documents.show.content_settings.gets_history_mode.title"))
    expect(row).to have_content(
      I18n.t!("documents.show.content_settings.gets_history_mode.true_label"),
    )
  end

  def when_i_click_to_change_the_status
    click_on "Change Gets history mode"
  end

  def then_i_enable_political_status
    stub_publishing_api_put_content(not_political_edition.content_id, {})
    choose(I18n.t!("history_mode.edit.labels.political"))
    click_on "Save"
  end

  def and_i_see_the_timeline_entry
    click_on "Document history"
    expect(page).to have_content(I18n.t!("documents.history.entry_types.political_status_changed"))
  end

  def when_i_click_to_backdate_the_content
    click_on "Document summary"
    click_on "Change Backdate"
  end

  def and_i_enter_a_date_to_backdate_the_content_to
    stub_publishing_api_put_content(not_political_edition.content_id, {})
    fill_in "backdate[date][day]", with: past_government.started_on.day
    fill_in "backdate[date][month]", with: past_government.started_on.month
    fill_in "backdate[date][year]", with: past_government.started_on.year
    click_on "Save"
  end

  def and_i_do_not_see_the_history_mode_banner
    expect(page).not_to have_content(
      I18n.t!("documents.show.historical.title",
              document_type: not_political_edition.document_type.label.downcase),
    )
  end

  def and_i_see_the_history_mode_banner
    expect(page).to have_content(
      I18n.t!("documents.show.historical.title",
              document_type: not_political_edition.document_type.label.downcase),
    )
  end
end
