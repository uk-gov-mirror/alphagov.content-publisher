# frozen_string_literal: true

module FixturesHelper
  def fixtures_path
    File.expand_path(Rails.root + "spec/fixtures")
  end

  def whitehall_export_with_one_edition
    JSON.parse(File.read(fixtures_path + "/whitehall_export_with_one_edition.json"))
  end

  def whitehall_export_with_two_editions
    JSON.parse(File.read(fixtures_path + "/whitehall_export_with_two_editions.json"))
  end

  def whitehall_export_with_images(image_fixture)
    whitehall_export_with_images = whitehall_export_with_one_edition
    whitehall_export_with_images["editions"][0]["images"] = JSON.parse(File.read(fixtures_path + "/whitehall_image_exports/#{image_fixture}"))
    whitehall_export_with_images
  end

  def stub_network_requests_to_whitehall_images
    binary_jpg = File.open(File.join(fixtures_path, "files", "960x640.jpg"), "rb").read
    stub_request(:get, "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/default_news_organisation_image_data/file/42/some-image.jpg").
      to_return(status: 200, body: binary_jpg)

    binary_png = File.open(File.join(fixtures_path, "files", "Bad $ name.png"), "rb").read
    stub_request(:get, "https://assets.publishing.service.gov.uk/frontend/homepage/nhs-long-term-plan-495f6e127d8e29d77cdc8ca724043fda508a74cb381ac216129a98693d53891d.png").
      to_return(status: 200, body: binary_png)
  end
end
