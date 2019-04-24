require 'octokit'
require 'redcarpet'
require 'redcarpet/render_strip'
require 'time'

require 'dotenv'
Dotenv.load

require_relative 'whedon/auditor'
require_relative 'whedon/author'
require_relative 'whedon/bibtex_parser'
require_relative 'whedon/compilers'
require_relative 'whedon/github'
require_relative 'whedon/orcid_validator'
require_relative 'whedon/processor'
require_relative 'whedon/review'
require_relative 'whedon/reviews'
require_relative 'whedon/version'

module Whedon

  def self.root
    File.dirname __dir__
  end

  def self.resources
    File.join root, 'resources'
  end

  AUTHOR_REGEX = /(?<=\*\*Submitting author:\*\*\s)(\S+)/
  REPO_REGEX = /(?<=\*\*Repository:\*\*.<a\shref=)"(.*?)"/
  VERSION_REGEX = /(?<=\*\*Version:\*\*\s)(\S+)/
  ARCHIVE_REGEX = /(?<=\*\*Archive:\*\*.<a\shref=)"(.*?)"/

  class Paper
    include GitHub

    attr_accessor :review_issue_id
    attr_accessor :review_repository
    attr_accessor :review_issue_body
    attr_accessor :title, :tags, :authors, :date, :paper_path, :bibliography_path

    EXPECTED_MARKDOWN_FIELDS = %w{
      title
      tags
      authors
      affiliations
      date
      bibliography
    }

    EXPECTED_LATEX_FIELDS = %w{
      title
      keywords
      authors
      affiliations
      date
      bibliography
    }

    def self.list
      reviews = Whedon::Reviews.new(ENV['REVIEW_REPOSITORY']).list_current
      return "No open reviews" if reviews.nil?

      reviews.each do |issue_id, vals|
        puts "#{issue_id}: #{vals[:url]} (#{vals[:opened_at]})"
      end
    end

    # Initialized with JOSS paper including YAML header
    # e.g. http://joss.theoj.org/about#paper_structure
    # Optionally return early if no paper_path is set
    def initialize(review_issue_id, paper_path=nil)
      @review_issue_id = review_issue_id
      @review_repository = ENV['REVIEW_REPOSITORY']
      return if paper_path.nil?

      parsed = load_yaml(paper_path)

      check_fields(parsed, paper_path)
      check_orcids(parsed)

      @paper_path = paper_path
      @authors = parse_authors(parsed)
      @title = parsed['title']
      @tags = parsed['tags']
      @date = parsed['date']
      @bibliography_path = parsed['bibliography']
    end

    def load_yaml(paper_path)
      if paper_path.include?('.tex')
        return YAML.load_file(paper_path.gsub('.tex', '.yml'))
      else
        return YAML.load_file(paper_path)
      end
    end

    def latex_source?
      paper_path.end_with?('.tex')
    end

    def markdown_source?
      paper_path.end_with?('.md')
    end

    # Check that the paper has the expected YAML header. Raise if missing fields
    def check_fields(parsed, paper_path)
      if paper_path.include?('.tex')
        expected_fields = EXPECTED_LATEX_FIELDS
      else
        expected_fields = EXPECTED_MARKDOWN_FIELDS
      end
      fields = expected_fields - parsed.keys
      raise "Paper YAML header is missing expected fields: #{fields.join(', ')}" if !fields.empty?
    end

    # Check that the user-defined ORCIDs look valid
    def check_orcids(parsed)
      authors = parsed['authors']
      authors.each do |author|
        next unless author.has_key?('orcid')
        raise "Problem with ORCID (#{author['orcid']}) for #{author['name']}" unless OrcidValidator.new(author['orcid']).validate
      end
    end

    def plain_title
      renderer = Redcarpet::Markdown.new(Redcarpet::Render::StripDown)
      return renderer.render(self.title).strip
    end

    def parse_authors(yaml)
      returned = []
      authors_yaml = yaml['authors']
      affiliations = parse_affiliations(yaml['affiliations'])

      # Loop through the authors block and build up the affiliation
      authors_yaml.each do |author|
        affiliation_index = author['affiliation']

        returned << Author.new(author['name'], author['orcid'], affiliation_index, affiliations)
      end

      returned
    end

    def parse_affiliations(affliations_yaml)
      returned = {}
      affliations_yaml.each do |affiliation|
        returned[affiliation['index']] = affiliation['name']
      end

      returned
    end

    # A 5-figure integer used to produce the JOSS DOI
    # Note, this doesn't actually include the string 'joss' in the DOI any
    # longer (it's now generalized) but the method name remains
    def joss_id
      id = "%05d" % review_issue_id
      "#{ENV['JOURNAL_ALIAS']}.#{id}"
    end

    def pdf_url
      "http://www.theoj.org/#{ENV['PAPER_REPOSITORY']}/#{joss_id}/#{ENV['DOI_PREFIX']}.#{joss_id}.pdf"
    end

    def review_issue_url
      "https://github.com/#{ENV['REVIEW_REPOSITORY']}/issues/#{review_issue_id}"
    end

    def directory
      File.dirname(paper_path)
    end

    def bibtex_path
      "#{directory}/#{bibliography_path}"
    end

    # The full DOI e.g. 10.21105/00001
    def formatted_doi
      "#{ENV['DOI_PREFIX']}/#{joss_id}"
    end

    # User when generating the citation snipped, returns either:
    # 'Smith et al' for multiple authors or 'Smith' for a single author
    def citation_author
      surname = authors.first.last_name

      if authors.size > 1
        return "#{surname} et al."
      else
        return "#{surname}"
      end
    end

    def authors_string
      authors_array = []

      authors.each_with_index do |author, index|
        authors_array << "#{author.name}"
      end

      return authors_array.join(', ')
    end

    # Returns an XML snippet to be included in the Crossref XML
    def crossref_authors
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.contributors {
          authors.each_with_index do |author, index|
            given_name = author.given_name
            surname = author.last_name
            orcid = author.orcid
            if index == 0
              sequence = "first"
            else
              sequence = "additional"
            end
            xml.person_name(:sequence => sequence, :contributor_role => "author") {
              xml.given_name given_name.encode(:xml => :text)
              xml.surname surname.encode(:xml => :text)
              xml.ORCID "http://orcid.org/#{author.orcid}" if !orcid.nil?
            }
          end
        }
      end

      return builder.doc.xpath('//contributors').to_xml
    end

    def google_scholar_authors
      authors_string = ""

      authors.each_with_index do |author, index|
        given_name = author.given_name
        surname = author.last_name

        authors_string << "<meta name=\"citation_author\" content=\"#{surname}, #{given_name}\">"
      end

      return authors_string
    end

    # A slightly modified DOI string for writing out files
    # 10.21105/00001 -> 10.21105.00001
    def filename_doi
      formatted_doi.gsub('/', '.')
    end

    # The JOSS site url for a paper
    # e.g. http://joss.theoj.org/papers/10.21105/00001
    def joss_resource_url
      "#{ENV['JOURNAL_URL']}/papers/#{formatted_doi}"
    end

    # Return the Review object associated with the Paper
    def review_issue
      review = Whedon::Review.new(review_issue_id, review_repository)
      @review_issue_body = review.issue_body
      return review
    end

    def audit
      review_issue if review_issue_body.nil?
      Whedon::Auditor.new(review_issue_body).audit
    end

    def download
      review_issue if review_issue_body.nil?
      Whedon::Processor.new(review_issue_id, review_issue_body).clone
    end

    def compile
      review_issue if review_issue_body.nil?
      processor = Whedon::Processor.new(review_issue_id, review_issue_body)
    end
  end
end
