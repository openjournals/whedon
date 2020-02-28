module Whedon
  class Author
    require 'nameable'

    attr_accessor :name, :affiliation, :orcid

    AUTHOR_FOOTNOTE_REGEX = /^[^\^]*/

    # Initialized with authors & affiliations block in the YAML header from
    # a JOSS paper e.g. http://joss.theoj.org/about#paper_structure
    #
    def initialize(name, orcid, index, affiliations_yaml)
      name = strip_footnotes(name)
      @parsed_name = Nameable::Latin.new.parse(name)
      @name = @parsed_name.to_nameable
      @orcid = orcid
      @affiliation = build_affiliation_string(index, affiliations_yaml)
    end

    def to_h
      {
        :given_name => given_name,
        :middle_name => @parsed_name.middle,
        :last_name => last_name,
        :orcid => orcid,
        :affiliation => affiliation.strip
      }
    end

    # Input: Arfon Smith^[Corresponding author: arfon@example.com]
    # Output: Arfon Smith
    def strip_footnotes(name)
      name[AUTHOR_FOOTNOTE_REGEX]
    end

    # Use the Nameable gem to return last name
    def last_name
      @parsed_name.last
    end

    # Use the Nameable gem to return first name
    def given_name
      @parsed_name.first
    end

    def initials
      [@parsed_name.first, @parsed_name.middle].compact.map {|v| v[0]}.zip(['.', '.', '.']).map(&:join) * ' '
    end

    # Takes the author affiliation index and a hash of all affiliations and
    # associates them. Then builds (and assigns) the author affiliation string.
    def build_affiliation_string(index, affiliations_yaml)
      # Some people have two affiliations, if this is the case then we need
      # to parse each one and build the affiliation string.
      author_affiliations = []

      return nil if index.nil? # Some authors don't have an affiliation

      affiliations = if index.to_s.include?(',')
        index.split(',').map { |a| a.strip }
      else
        [ index.to_s ]
      end

      # We need to turn all of the affiliation YAML keys into strings
      # So that mixed integer and string affiliations work
      affiliations_yaml = affiliations_yaml.inject({}) {|hash, (key, val)| hash.merge(key.to_s => val) }

      # Raise if we can't parse the string, might be because of this bug :-(
      # https://bugs.ruby-lang.org/issues/12451
      affiliations.each do |a|
        raise "Problem with affiliations for #{self.name}, perhaps the \
affiliations index need quoting?" unless affiliations_yaml.has_key?(a)

        author_affiliations << affiliations_yaml[a]
      end

      return author_affiliations.join(', ')
    end
  end
end
