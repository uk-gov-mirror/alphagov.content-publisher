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

  def whitehall_export_with_two_editions_and_images(edition_1_images, edition_2_images)
    whitehall_export_with_images = whitehall_export_with_two_editions
    whitehall_export_with_images["editions"][0]["images"] = JSON.parse(File.read(fixtures_path + "/whitehall_image_exports/#{edition_1_images}"))
    whitehall_export_with_images["editions"][1]["images"] = JSON.parse(File.read(fixtures_path + "/whitehall_image_exports/#{edition_2_images}"))
    whitehall_export_with_images
  end

  def stub_network_requests_to_whitehall_images
    binary_jpg = File.open(File.join(fixtures_path, "files", "960x640.jpg"), "rb").read
    stub_request(:get, "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/default_news_organisation_image_data/file/42/some-image.jpg").
      to_return(status: 200, body: binary_jpg)
    stub_request(:get, "https://assets.publishing.service.gov.uk/some/other/path/some-image.jpg").
      to_return(status: 200, body: binary_jpg)
    stub_request(:get, "https://assets.publishing.service.gov.uk/path/to/some/photo.jpg").
      to_return(status: 200, body: binary_jpg)

    binary_jpeg = File.open(File.join(fixtures_path, "files", "960x640.jpeg"), "rb").read
    stub_request(:get, "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/default_news_organisation_image_data/file/42/some-image.jpeg").
      to_return(status: 200, body: binary_jpeg)

    binary_jpg_1000px = File.open(File.join(fixtures_path, "files", "1000x1000.jpg"), "rb").read
    stub_request(:get, "https://assets.publishing.service.gov.uk/government/uploads/etc/1000x1000.jpg").
      to_return(status: 200, body: binary_jpg_1000px)

    binary_png = File.open(File.join(fixtures_path, "files", "960x640.png"), "rb").read
    stub_request(:get, "https://assets.publishing.service.gov.uk/frontend/homepage/nhs-long-term-plan-495f6e127d8e29d77cdc8ca724043fda508a74cb381ac216129a98693d53891d.png").
      to_return(status: 200, body: binary_png)

    binary_gif = File.open(File.join(fixtures_path, "files", "static-gif-960x640.gif"), "rb").read
    stub_request(:get, "https://assets.publishing.service.gov.uk/path/to/some/static.gif").
      to_return(status: 200, body: binary_gif)
  end
end
