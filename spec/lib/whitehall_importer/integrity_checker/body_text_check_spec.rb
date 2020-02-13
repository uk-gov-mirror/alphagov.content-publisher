RSpec.describe WhitehallImporter::IntegrityChecker::BodyTextCheck do
  it "retuns no problems if the proposed payload matches" do
    integrity_check = WhitehallImporter::IntegrityChecker::BodyTextCheck.new("Some text", "Some text")
    expect(integrity_check.sufficiently_similar?).to be true
  end

  it "returns a problem when the body text doesn't match" do
    integrity_check = WhitehallImporter::IntegrityChecker::BodyTextCheck.new("Some text", "Some different text")
    expect(integrity_check.sufficiently_similar?).to be false
  end
end
