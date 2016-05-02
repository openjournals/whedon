require 'securerandom'

module Whedon
  class Crossref
    attr_accessor :review_issue_id
    attr_accessor :review_repository

    # Initialize the Crossref generator
    def initialize(review_issue_id, repository)
      @review_issue_id = review_issue_id
      @review_repository = repository
    end

    # Find XML paper
    def find_xml_paths
      xml_paths = []
      Find.find("tmp/#{review_issue_id}") do |path|
        xml_paths << path if path =~ /paper\.xml$/
      end

      return xml_paths
    end

    # http://www.crossref.org/help/schema_doc/4.3.7/4.3.7.html
    # Publisher generated ID that uniquely identifies the DOI submission
    # batch. It will be used as a reference in error messages sent by the MDDB, and can be
    # used for submission tracking. The publisher must insure that this number is unique
    # for every submission to CrossRef.
    def generate_doi_batch_id
      @doi_batch_id = SecureRandom.hex
    end
  end
end
