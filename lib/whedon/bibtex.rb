require 'bibtex'

# => bib = Whedon::Bibtex.new('paper.bib').generate_citations
module Whedon
  class Bibtex
    # Initialize the Bibtex generator
    # Takes a path to bibtex file
    def initialize(bib_file)
      @bib_file = bib_file
      @ref_count = 1
      @citation_string = ""
    end

    # Generates the <citations></citations> XML block for Crossref
    # Returns an XML fragment <citations></citations> with or
    # without citations within
    # TODO: should probably use Ruby builder templates here
    def generate_citations
      entries = BibTeX.open(@bib_file)

      if entries.empty?
        @citation_string = ""
      else
        entries.each do |entry|
          @citation_string << make_citation(entry)
          @ref_count += 1
        end
      end

      return "<citations>#{@citation_string}</citations>"
    end

    # Chooses what sort of citation to make based upon whether there is a DOI
    # present in the bibtex entry
    def make_citation(entry)
      if entry.has_field?('doi')
        return doi_citation(entry)
      else
        return general_citation(entry)
      end
    end

    # Returns a simple <citation> XML snippet with the DOI
    def doi_citation(entry)
      "<citation key='ref#{@ref_count}'><doi>#{entry.doi.to_s}</doi></citation>"
    end

    # Returns a more complex <citation> XML snippet with keys for each of the
    # bibtex fields
    def general_citation(entry)
      citation = "<citation key='ref#{@ref_count}'>"
      entry.each_pair do |name, value|
        citation << "<#{name}>#{value}</#{name}>"
      end
      citation << "</citation>"

      return citation
    end
  end
end
