# frozen_string_literal: true

class DocumentTypeSelection
  include InitializeWithHash

  attr_reader :id, :type, :options

  def self.find_page(id)
    all.find { |document_type_selection| document_type_selection.id == id }
  end

  def self.find_option(id)
    all.each do |document_type_selection|
      document_type_selection.options.each do |key, val|
        if key["id"] == id
          return key
        end
      end
    end
    throw "NO OPTION #{id}"
  end

  def self.all
    @all ||= begin
      hashes = YAML.load_file(Rails.root.join("config/document_type_selections.yml"))

      hashes.map do |hash|
        hash["options"].map! do |option|
          SelectionOption.new(option).hash.stringify_keys
        end
        new(hash)
      end
    end
  end

  def parent
    self.class.all.find do |document_type_selection|
      document_type_selection.options.pluck(:id).include?(id)
    end
  end

  class SelectionOption
    attr_reader :option

    def initialize(option)
      @option = option
    end

    def hash
      if option.is_a? String
        {
          id: option,
          type: "refine",
        }
      else
        selection_option = {
          id: option.keys.first,
          type: option["type"],
        }

        selection_option[:managed_elsewhere_url] = managed_elsewhere_url if option["type"] == "managed_elsewhere"

        selection_option
      end
    end

    def managed_elsewhere_url
      if option["hostname"]
        Plek.new.external_url_for(option.fetch("hostname")) + option.fetch("path")
      else
        option["path"]
      end
    end
  end
end
