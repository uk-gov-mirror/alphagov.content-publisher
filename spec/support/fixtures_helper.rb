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

  def stub_network_requests_to_whitehall_images
    binary_image = File.open(File.join(fixtures_path, "files", "960x640.jpg"), "rb").read
    stub_request(:get, whitehall_export_with_one_edition.dig("editions", 0, "images", 0, "url")).
      to_return(status: 200, body: binary_image)
  end
end
