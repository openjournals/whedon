# Whedon::Bibtex is used to generate the citation string used in the Crossref
# metadata. It uses the bibtex RubyGem.

require 'bibtex'
require 'nokogiri'
require 'uri'

# => bib = Whedon::BibtexParser.new('paper.bib').generate_citations
module Whedon
  class BibtexParser
    # Initialize the Bibtex generator
    # Takes a path to bibtex file
    def initialize(bib_file)
      @bib_file = bib_file
      @ref_count = 1
      @citation_string = ""
    end

    def bibtex_keys
      entries = BibTeX.open(@bib_file, :filter => :latex)

      keys = []
      entries.each do |entry|
        next if entry.comment?
        next if entry.preamble?

        keys << "@#{entry.key}"
      end

      return keys
    end

    # Generates the <citations></citations> XML block for Crossref
    # Returns an XML fragment <citations></citations> with or
    # without citations within
    # TODO: should probably use Ruby builder templates here
    def generate_citations(citations=nil)
      entries = BibTeX.open(@bib_file, :filter => :latex)

      if entries.empty?
        @citation_string = ""
      else
        entries.each do |entry|
          next if entry.comment?
          next if entry.preamble?

          if citations
            next unless citations.include?("@#{entry.key}")
          end
          @citation_string << make_citation(entry)
          @ref_count += 1
        end
      end

      # This Nokogiri step is simply to pretty-print the XML of the citations
      doc = Nokogiri::XML("<citation_list>#{@citation_string}</citation_list>")
      return doc.root.to_xml
    end

    # Chooses what sort of citation to make based upon whether there is a DOI
    # present in the bibtex entry
    def make_citation(entry)
      if entry.has_field?('doi') && !entry.doi.empty?
        return doi_citation(entry)
      else
        return general_citation(entry)
      end
    end

    # Returns a simple <citation> XML snippet with the DOI
    def doi_citation(entry)
      # Crossref DOIs need to be strings like 10.21105/joss.01461 rather
      # than https://doi.org/10.21105/joss.01461
      bare_doi = entry.doi.to_s[/\b(10[.][0-9]{4,}(?:[.][0-9]+)*\/(?:(?!["&\'<>])\S)+)\b/]

      # Check for shortDOI formatted DOIs http://shortdoi.org
      if bare_doi.nil?
        bare_doi = entry.doi.to_s[/\b(10\/[a-bA-z0-9]+)\b/]
      end

      # Sometimes there are weird characters in the DOI. This escapes
      escaped_doi = bare_doi.encode(:xml => :text)
      "<citation key=\"ref#{@ref_count}\"><doi>#{escaped_doi}</doi></citation>"
    end

    # Returns a more complex <citation> XML snippet with keys for each of the
    # bibtex fields
    def general_citation(entry)
      citation = "<citation key=\"ref#{@ref_count}\"><unstructured_citation>"
      values = []
      entry.each_pair do |name, value|
        # Ultimately we should call entry.to_citeproce here to parse this properly.
        # https://github.com/inukshuk/bibtex-ruby/pull/139/files
        value = value.gsub('\urlhttp', 'http')
        values << value.encode(:xml => :text)
      end
      citation << values.join(', ')
      citation << "</unstructured_citation></citation>"

      return citation
    end
  end
end
