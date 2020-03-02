namespace :remove do
  desc "Remove a document with a gone on GOV.UK e.g. remove:gone['a-content-id']"
  task :gone, [:content_id] => :environment do |_, args|
    raise "Missing content_id parameter" unless args.content_id

    explanatory_note = ENV["NOTE"]
    alternative_url = ENV["URL"]
    locale = ENV["LOCALE"] || "en"
    user = User.find_by!(email: ENV["USER_EMAIL"]) if ENV["USER_EMAIL"]

    edition = Edition.joins(:document).find_by!(
      live: true,
      documents: { content_id: args.content_id, locale: locale }
    )

    removal = Removal.new(removal_type: :gone,
                          explanatory_note: explanatory_note,
                          alternative_url: alternative_url)

    RemoveDocumentService.call(edition, removal, user: user)
  end

  desc "Remove a document with a redirect on GOV.UK e.g. remove:redirect['a-content-id'] URL='/redirect-to-here'"
  task :redirect, [:content_id] => :environment do |_, args|
    raise "Missing content_id parameter" unless args.content_id
    raise "Missing URL value" if ENV["URL"].blank?

    explanatory_note = ENV["NOTE"]
    redirect_url = ENV["URL"]
    locale = ENV["LOCALE"] || "en"
    user = User.find_by!(email: ENV["USER_EMAIL"]) if ENV["USER_EMAIL"]

    edition = Edition.joins(:document).find_by!(
      live: true,
      documents: { content_id: args.content_id, locale: locale }
    )

    removal = Removal.new(removal_type: :redirect,
                          explanatory_note: explanatory_note,
                          alternative_url: redirect_url)

    RemoveDocumentService.call(edition, removal, user: user)
  end

  desc "Remove a document with a vanish (a 404) on GOV.UK e.g. remove:vanish['a-content-id']"
  task :vanish, [:content_id] => :environment do |_, args|
    raise "Missing content_id parameter" unless args.content_id

    locale = ENV["LOCALE"] || "en"
    user = User.find_by!(email: ENV["USER_EMAIL"]) if ENV["USER_EMAIL"]

    edition = Edition.joins(:document).find_by!(
      live: true,
      documents: { content_id: args.content_id, locale: locale }
    )

    removal = Removal.new(removal_type: :vanish)

    RemoveDocumentService.call(edition, removal, user: user)
  end
end
