RSpec.describe Requirements::FileAttachmentMetadataChecker do
  describe "#pre_publish_issues" do
    it "raises an issue if official document status is not selected" do
      issues = described_class.new({}).pre_publish_issues
      expect(issues).to have_issue(:file_attachment_official_document, :not_selected)
    end

    %w(act_paper command_paper).each do |doc_type|
      it "raises an issue if #{doc_type} number is missing" do
        issues = described_class.new({ official_document_type: doc_type }).pre_publish_issues
        expect(issues).to have_issue(:file_attachment_paper_number, :missing)
      end
    end

    it "raises an issue if a given act paper number is invalid" do
      issues = described_class.new({ official_document_type: "act_paper", paper_number: "invalid" }).pre_publish_issues
      expect(issues).to have_issue(:file_attachment_act_paper_number, :invalid)
    end

    ["C.", "Cd.", "Cmd.", "Cmnd.", "Cm.", "CP"].each do |prefix|
      it "does not raise an issue when the command paper number starts with '#{prefix}'" do
        issues = described_class.new({ official_document_type: "command_paper", paper_number: "#{prefix} 1234" }).pre_publish_issues
        expect(issues).to be_empty
      end
    end

    ["NA", "C", "Cd ", "CM.", "CP."].each do |prefix|
      it "raises an issue when the command paper number starts with '#{prefix}'" do
        issues = described_class.new({ official_document_type: "command_paper", paper_number: "#{prefix} 1234" }).pre_publish_issues
        expect(issues).to have_issue(:file_attachment_command_paper_number, :invalid)
      end
    end

    ["-I", "-IV", "-VIII"].each do |suffix|
      it "does not raise an issue when the command paper number ends with '#{suffix}'" do
        issues = described_class.new({ official_document_type: "command_paper", paper_number: "C. 1234#{suffix}" }).pre_publish_issues
        expect(issues).to be_empty
      end
    end

    ["-i", "-Iv", "VIII"].each do |suffix|
      it "raises an issue when the command paper number ends with '#{suffix}'" do
        issues = described_class.new({ official_document_type: "command_paper", paper_number: "C. 1234#{suffix}" }).pre_publish_issues
        expect(issues).to have_issue(:file_attachment_command_paper_number, :invalid)
      end
    end

    it "raises an issue when the command paper number has no space after the prefix" do
      issues = described_class.new({ official_document_type: "command_paper", paper_number: "C.1234" }).pre_publish_issues
      expect(issues).to have_issue(:file_attachment_command_paper_number, :invalid)
    end
  end

  describe "#pre_update_issues" do
    let(:max_length) { Requirements::FileAttachmentMetadataChecker::UNIQUE_REF_MAX_LENGTH }

    it "returns no issues if there are none" do
      unique_reference = "z" * max_length
      issues = described_class.new(unique_reference: unique_reference).pre_update_issues
      expect(issues).to be_empty
    end

    it "returns unique_reference issues when the unique_reference is too long" do
      unique_reference = "z" * (max_length + 1)
      issues = described_class.new(unique_reference: unique_reference).pre_update_issues

      expect(issues).to have_issue(:file_attachment_unique_reference,
                                   :too_long,
                                   max_length: max_length)
    end

    [
      "invalid",
      "9788--0631625",
      "9991a9010599938",
      "0-9722051-1-F",
      "ISBN 9788700631625",
    ].each do |invalid_isbn|
      it "returns isbn issues when invalid isbn #{invalid_isbn.inspect} is provided" do
        issues = described_class.new(isbn: invalid_isbn).pre_update_issues
        expect(issues).to have_issue(:file_attachment_isbn, :invalid)
      end
    end

    it "returns no issues when isbn is omitted" do
      issues = described_class.new(isbn: nil).pre_update_issues
      expect(issues).to be_empty
    end

    [
      "9788700631625",
      "1590599934",
      "159-059 9934",
      "978-159059 9938",
      "978-1-60746-006-0",
      "0-9722051-1-X",
      "0-9722051-1-x",
    ].each do |valid_isbn|
      it "returns no issues when valid isbn #{valid_isbn.inspect} is provided" do
        issues = described_class.new(isbn: valid_isbn).pre_update_issues
        expect(issues).to be_empty
      end
    end
  end
end
