require 'securerandom'

module Whedon
  class Crossref
    attr_accessor :doi_batch_id

    # Initialize the Crossref generator
    def initialize(bib_file)
      @citations = citations
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
