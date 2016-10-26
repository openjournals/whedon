require_relative 'github'
require 'yaml'
require 'securerandom'

module Whedon
  class Processor
    include GitHub

    attr_accessor :review_issue_id
    attr_accessor :review_body
    attr_accessor :repository_address
    attr_accessor :archive_doi
    attr_accessor :paper_path
    attr_accessor :xml_path
    attr_accessor :doi_batch_id

    def initialize(review_issue_id, review_body)
      @review_issue_id = review_issue_id
      @review_body = review_body
      @repository_address = review_body[REPO_REGEX]
      @archive_doi = review_body[ARCHIVE_REGEX]
    end

    # Clone the repository... (assumes it's git)
    def clone
      repository_address = review_body[REPO_REGEX]

      # Skip if the repo has already been cloned
      if File.exists?("tmp/#{review_issue_id}/.git")
        puts "Looks like Git repo already exists at tmp/#{review_issue_id}"
        return
      end

      # First make the folder
      FileUtils::mkdir_p("tmp/#{review_issue_id}")

      # Then clone the repository
      `git clone #{repository_address} tmp/#{review_issue_id}`
    end

    # Find possible papers to be compiled
    def find_paper_paths
      paper_paths = []
      Find.find("tmp/#{review_issue_id}") do |path|
        paper_paths << path if path =~ /paper\.md$/
      end

      return paper_paths
    end

    # Find possible papers to be compiled
    def find_bib_path
      bib_paths = []
      Find.find("tmp/#{review_issue_id}") do |path|
        bib_paths << path if path =~ /.bib$/
      end

      return bib_paths
    end

    # Find XML paper
    def find_xml_paths
      xml_paths = []
      Find.find("tmp/#{review_issue_id}") do |path|
        xml_paths << path if path =~ /paper\.xml$/
      end

      return xml_paths
    end

    # Upload docs to joss-papers repo
    def upload_pdfs

    end

    def review_issue_url
      "https://github.com/openjournals/joss-reviews/issues/#{review_issue_id}"
    end

    def paper_url
      "https://github.com/openjournals/joss-papers/blob/master/#{joss_id}/#{DOI_PREFIX}.#{joss_id}.pdf"
    end

    def joss_id
      id = "%05d" % review_issue_id
      "joss.#{id}"
    end

    def formatted_doi
      "#{DOI_PREFIX}/#{joss_id}"
    end

    def filename_doi
      formatted_doi.gsub('/', '.')
    end

    def joss_resource_url
      "http://joss.theoj.org/papers/#{formatted_doi}"
    end

    # Need to split authors into firstname and surname for Crossref :-\
    # HACK HACK HACK
    def generate_crossref_authors(paper_path)
      parsed = Psych.load(File.open(paper_path, 'r').read)
      authors_string = "<contributors>"

      parsed['authors'].each_with_index do |author, index|
        given_name = author['name'].split(' ').first.strip
        surname = author['name'].gsub(given_name, '').strip
        if index == 0
          authors_string << '<person_name sequence="first" contributor_role="author">'
        else
          authors_string << '<person_name sequence="additional" contributor_role="author">'
        end

        authors_string << "<given_name>#{given_name}</given_name>"
        authors_string << "<surname>#{surname}</surname>"
        authors_string << "<ORCID>http://orcid.org/#{author['orcid']}</ORCID>" if author.has_key?('orcid')
        authors_string << "</person_name>"
      end

      authors_string << "</contributors>"
      return authors_string
    end

    def generate_google_scholar_authors(paper_path)
      parsed = Psych.load(File.open(paper_path, 'r').read)
      authors_string = ""

      parsed['authors'].each_with_index do |author, index|
        given_name = author['name'].split(' ').first.strip
        surname = author['name'].gsub(given_name, '').strip

        authors_string << "<meta name=\"citation_author\" content=\"#{surname}, #{given_name}\">"
      end

      return authors_string
    end

    def paper_directory
      File.dirname(paper_path)
    end

    # Try and compile the paper target
    def compile
      generate_pdf
      generate_xml
      generate_html
      generate_crossref
    end

    def generate_pdf
      latex_template_path = "#{Dir.pwd}/resources/latex.template"

      # TODO: may eventually want to swap out the latex template
      `cd #{paper_directory} && pandoc \
      -V repository=#{repository_address} \
      -V archive_doi=#{archive_doi} \
      -V paper_url=#{paper_url} \
      -V formatted_doi=#{formatted_doi} \
      -V review_issue_url=#{review_issue_url} \
      -S -o #{filename_doi}.pdf -V geometry:margin=1in \
      --filter pandoc-citeproc #{File.basename(paper_path)} \
      --template #{latex_template_path}`

       File.exists?("#{paper_directory}/#{filename_doi}.pdf")
        `open #{paper_directory}/#{filename_doi}.pdf`
      else
        puts "Looks like we failed to compile the PDF"
      end
    end

    def generate_xml
      xml_template_path = "#{Dir.pwd}/resources/xml.template"

      `cd #{paper_directory} && pandoc \
      -V repository=#{repository_address} \
      -V archive_doi=#{archive_doi} \
      -V formatted_doi=#{formatted_doi} \
      -V paper_url=#{paper_url} \
      -V review_issue_url=#{review_issue_url} \
      -s -f markdown #{File.basename(paper_path)} -o #{filename_doi}.xml \
      --filter pandoc-citeproc \
      --template #{xml_template_path}`

      if File.exists?("#{paper_directory}/#{filename_doi}.xml")
        `open #{paper_directory}/#{filename_doi}.xml`
      else
        puts "Looks like we failed to compile the XML"
      end
    end

    def generate_html
      html_template_path = "#{Dir.pwd}/resources/html.template"
      google_authors = generate_google_scholar_authors(paper_path)

      `cd #{paper_directory} && pandoc \
      -V repository=#{repository_address} \
      -V archive_doi=#{archive_doi} \
      -V formatted_doi=#{formatted_doi} \
      -V google_authors='#{google_authors}' \
      -V timestamp=#{Time.now.strftime('%Y/%m/%d')} \
      -V paper_url=#{paper_url} \
      -V review_issue_url=#{review_issue_url} \
      -s -f markdown #{File.basename(paper_path)} -o #{filename_doi}.html \
      --filter pandoc-citeproc \
      --ascii \
      --template #{html_template_path}`

      if File.exists?("#{paper_directory}/#{filename_doi}.html")
        `open #{paper_directory}/#{filename_doi}.html`
      else
        puts "Looks like we failed to compile the HTML"
      end
    end

    def generate_crossref
      cross_ref_template_path = "#{Dir.pwd}/resources/crossref.template"
      bibtex = Bibtex.new(find_bib_path.first)
      citations = bibtex.generate_citations
      authors = generate_crossref_authors(paper_path)
      paper_directory = File.dirname(paper_path)

      `cd #{paper_directory} && pandoc \
      -V timestamp=#{Time.now.strftime('%Y%m%d%H%M%S')} \
      -V doi_batch_id=#{generate_doi_batch_id} \
      -V formatted_doi=#{formatted_doi} \
      -V joss_resource_url=#{joss_resource_url} \
      -V citations='#{citations}' \
      -V authors='#{authors}' \
      -V month=#{Time.now.strftime('%m')} \
      -V day=#{Time.now.strftime('%d')} \
      -V year=#{Time.now.strftime('%Y')} \
      -V issue=#{CURRENT_ISSUE} \
      -V volume=#{CURRENT_VOLUME} \
      -s -f markdown #{File.basename(paper_path)} -o #{filename_doi}.crossref.xml \
      --template #{cross_ref_template_path}`

      if File.exists?("#{paper_directory}/#{filename_doi}.crossref.xml")
        `open #{paper_directory}/#{filename_doi}.crossref.xml`
      else
        puts "Looks like we failed to compile the Crossref XML"
      end
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
