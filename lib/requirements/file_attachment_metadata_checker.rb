module Requirements
  class FileAttachmentMetadataChecker
    UNIQUE_REF_MAX_LENGTH = 255
    ISBN10_REGEX = /^(?:\d[\ -]?){9}[\dX]$/i.freeze
    ISBN13_REGEX = /^(?:\d[\ -]?){13}$/i.freeze
    VALID_COMMAND_PAPER_NUMBER_PREFIXES = ["C.", "Cd.", "Cmd.", "Cmnd.", "Cm.", "CP"].freeze

    attr_reader :isbn, :unique_reference

    def initialize(params)
      @isbn = params[:isbn]
      @official_document_type = params[:official_document_type]
      @paper_number = params[:paper_number]
      @unique_reference = params[:unique_reference]
    end

    def pre_publish_issues
      offical_number_issues
    end

    def pre_update_issues
      isbn_issues + unique_reference_issues
    end

  private

    def act_paper_number_invalid?
      (@paper_number !~ /^\d/)
    end

    def command_paper_number_invalid?
      valid_prefixes = VALID_COMMAND_PAPER_NUMBER_PREFIXES.map { |prefix| Regexp.escape(prefix) }
      command_paper_number_regex = %r{
        \A        # beginning of string
        (#{valid_prefixes.join('|')}) # all allowed prefixes
        \s        # single space
        \d+       # number
        (-[IV]+)? # optional Roman numeral suffix
        \z        # end of string
        }x
      @paper_number.nil? || !@paper_number.match(command_paper_number_regex)
    end

    def isbn_issues
      issues = CheckerIssues.new

      unless isbn.blank? || ISBN10_REGEX.match?(isbn) || ISBN13_REGEX.match?(isbn)
        issues.create(:file_attachment_isbn, :invalid)
      end

      issues
    end

    def nothing_selected?
      !@official_document_type
    end

    def offical_number_issues
      issues = CheckerIssues.new
      issues.create(:file_attachment_official_document, :not_selected) if nothing_selected?
      issues.create(:file_attachment_paper_number, :missing) if %w(act_paper command_paper).include?(@official_document_type) && @paper_number.nil?
      issues.create(:file_attachment_act_paper_number, :invalid) if @official_document_type == "act_paper" && act_paper_number_invalid?
      issues.create(:file_attachment_command_paper_number, :invalid) if @official_document_type == "command_paper" && command_paper_number_invalid?
      issues
    end

    def unique_reference_issues
      issues = CheckerIssues.new

      if unique_reference.present? &&
          unique_reference.to_s.size > UNIQUE_REF_MAX_LENGTH
        issues.create(:file_attachment_unique_reference,
                      :too_long,
                      max_length: UNIQUE_REF_MAX_LENGTH)
      end

      issues
    end
  end
end
