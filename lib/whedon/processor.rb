require_relative 'github'
require 'restclient'
require 'securerandom'
require 'yaml'
require 'uri'
require 'json'

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
    attr_accessor :paper
    attr_accessor :current_volume
    attr_accessor :current_issue

    def initialize(review_issue_id, review_body)
      @review_issue_id = review_issue_id
      @review_body = review_body
      @repository_address = review_body[REPO_REGEX]
      @archive_doi = review_body[ARCHIVE_REGEX]
      # Probably a much nicer way to do this...
      @current_volume = Time.new.year - (Time.parse(ENV['JOURNAL_LAUNCH_DATE']).year - 1)
      @current_issue = 1 + ((Time.new.year * 12 + Time.new.month) - (Time.parse(ENV['JOURNAL_LAUNCH_DATE']).year * 12 + Time.parse(ENV['JOURNAL_LAUNCH_DATE']).month))
    end

    def set_paper(path)
      @paper = Whedon::Paper.new(review_issue_id, path)
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
    def find_paper_paths(search_path=nil)
      search_path ||= "tmp/#{review_issue_id}"
      paper_paths = []

      Find.find(search_path) do |path|
        paper_paths << path if path =~ /paper\.md$/
      end

      return paper_paths
    end

    # Find possible bibtex to be compiled
    def find_bib_path(search_path=nil)
      search_path ||= "tmp/#{review_issue_id}"
      bib_paths = []

      Find.find(search_path) do |path|
        bib_paths << path if path =~ /paper.bib$/
      end

      return bib_paths
    end

    # Find XML paper
    def find_xml_paths(search_path=nil)
      search_path ||= "tmp/#{review_issue_id}"
      xml_paths = []

      Find.find(search_path) do |path|
        xml_paths << path if path =~ /paper\.xml$/
      end

      return xml_paths
    end

    # Try and compile the paper target
    def compile
      generate_pdf
      generate_crossref
    end

    # Generate the paper PDF
    # Optionally pass in a custom branch name as first param
    def generate_pdf(custom_branch=nil,paper_issue=nil, paper_volume=nil, paper_year=nil)
      latex_template_path = "#{Whedon.resources}/latex.template"
      csl_file = "#{Whedon.resources}/apa.csl"

      # TODO: Sanitize all the things!
      paper_title = paper.title.gsub!('_', '\_')
      paper_year ||= Time.now.strftime('%Y')
      paper_issue ||= @current_issue
      paper_volume ||= @current_volume
      # FIX ME - when the JOSS application has an actual API this could/should
      # be cleaned up
      submitted = `curl #{ENV['JOURNAL_URL']}/papers/lookup/#{@review_issue_id}`
      published = Time.now.strftime('%d %B %Y')

      # Optionally pass a custom branch name
      `cd #{paper.directory} && git checkout #{custom_branch} --quiet` if custom_branch

      # TODO: may eventually want to swap out the latex template
      `cd #{paper.directory} && pandoc \
      -V repository="#{repository_address}" \
      -V archive_doi="#{archive_doi}" \
      -V paper_url="#{paper.pdf_url}" \
      -V journal_name='#{ENV['JOURNAL_NAME']}' \
      -V formatted_doi="#{paper.formatted_doi}" \
      -V review_issue_url="#{paper.review_issue_url}" \
      -V graphics="true" \
      -V issue="#{paper_issue}" \
      -V volume="#{paper_volume}" \
      -V page="#{paper.review_issue_id}" \
      -V logo_path="#{Whedon.resources}/#{ENV['JOURNAL_ALIAS']}-logo.png" \
      -V year="#{paper_year}" \
      -V submitted="#{submitted}" \
      -V published="#{published}" \
      -V formatted_doi="#{paper.formatted_doi}" \
      -V citation_author="#{paper.citation_author}" \
      -V paper_title='#{paper.title}' \
      -V footnote_paper_title='#{paper.plain_title}' \
      -o #{paper.filename_doi}.pdf -V geometry:margin=1in \
      --pdf-engine=xelatex \
      --filter pandoc-citeproc #{File.basename(paper.paper_path)} \
      --from markdown+autolink_bare_uris \
      --csl=#{csl_file} \
      --template #{latex_template_path}`

      if File.exists?("#{paper.directory}/#{paper.filename_doi}.pdf")
        puts "#{paper.directory}/#{paper.filename_doi}.pdf"
      else
        abort("Looks like we failed to compile the PDF")
      end
    end

    def citation_string
      paper_year ||= Time.now.strftime('%Y')
      paper_issue ||= @current_issue
      paper_volume ||= @current_volume

      return "#{paper.citation_author}, (#{paper_year}). #{paper.plain_title}. #{ENV['JOURNAL_NAME']}, #{paper_volume}(#{paper_issue}), #{paper.review_issue_id}, https://doi.org/#{paper.formatted_doi}"
    end

    def authors_map
      authors = {}
      paper.authors.each_with_index do |a, index|
        authors[index] = {'name' => a.name, 'orcid' => a.orcid}
      end
      return authors
    end

    def deposit
      crossref_deposit
      joss_deposit

      puts "p=dat #{@review_issue_id};p.doi='#{paper.formatted_doi}';"\
           "p.archive_doi=#{archive_doi};p.accepted_at=Time.now;"\
           "p.citation_string='#{citation_string}';"\
           "p.authors='#{paper.authors_string}';p.title='#{paper.title}';"
    end

    def joss_deposit
      puts "Depositing with JOSS..."
      request = RestClient::Request.new(
                :method => :post,
                :url => "#{ENV['JOURNAL_URL']}/papers/api_deposit",
                :payload => {
                  :id => paper.review_issue_id,
                  :doi => paper.formatted_doi,
                  :archive_doi => archive_doi,
                  :citation_string => citation_string,
                  :title => paper.plain_title,
                  :authors => URI.encode_www_form_component(authors_map.to_json),
                  :secret => ENV['WHEDON_SECRET']
                })

      response = request.execute
      if response.code == 201
        puts "Deposit looks good."
      else
        puts "Something went wrong with this deposit."
      end
    end

    def crossref_deposit
      if File.exists?("#{paper.directory}/#{paper.filename_doi}.crossref.xml")
        puts "Depositing with Crossref..."
        request = RestClient::Request.new(
                  :method => :post,
                  :url => "https://doi.crossref.org/servlet/deposit",
                  :payload => {
                    :multipart => true,
                    :fname => File.new("#{paper.directory}/#{paper.filename_doi}.crossref.xml", 'rb'),
                    :login_id => ENV['CROSSREF_USERNAME'],
                    :login_passwd => ENV['CROSSREF_PASSWORD']
                  })

        response = request.execute
        if response.code == 200
          puts "Deposit looks good. Check your email!"
        else
          puts "Something went wrong with this deposit."
        end
      else
        puts "Can't deposit Crossref metadata - deposit XML is missing"
      end
    end

    def generate_crossref(paper_issue=nil, paper_volume=nil, paper_year=nil, paper_month=nil, paper_day=nil)
      cross_ref_template_path = "#{Whedon.resources}/crossref.template"
      bibtex = Bibtex.new(paper.bibtex_path)
      citations = bibtex.generate_citations
      authors = paper.crossref_authors
      # TODO fix this when we update the DOI URLs
      # crossref_doi = archive_doi.gsub("http://dx.doi.org/", '')

      paper_day ||= Time.now.strftime('%d')
      paper_month ||= Time.now.strftime('%m')
      paper_year ||= Time.now.strftime('%Y')
      paper_issue ||= @current_issue
      paper_volume ||= @current_volume

      `cd #{paper.directory} && pandoc \
      -V timestamp=#{Time.now.strftime('%Y%m%d%H%M%S')} \
      -V doi_batch_id=#{generate_doi_batch_id} \
      -V formatted_doi=#{paper.formatted_doi} \
      -V archive_doi=#{archive_doi} \
      -V review_issue_url=#{paper.review_issue_url} \
      -V paper_url=#{paper.pdf_url} \
      -V joss_resource_url=#{paper.joss_resource_url} \
      -V journal_alias=#{ENV['JOURNAL_ALIAS']} \
      -V journal_abbrev_title=#{ENV['JOURNAL_ALIAS'].upcase} \
      -V journal_url=#{ENV['JOURNAL_URL']} \
      -V journal_name='#{ENV['JOURNAL_NAME']}' \
      -V journal_issn=#{ENV['JOURNAL_ISSN']} \
      -V citations='#{citations}' \
      -V authors='#{authors}' \
      -V month=#{paper_month} \
      -V day=#{paper_day} \
      -V year=#{paper_year} \
      -V issue=#{paper_issue} \
      -V volume=#{paper_volume} \
      -V page=#{paper.review_issue_id} \
      -V title='#{paper.plain_title}' \
      -f markdown #{File.basename(paper.paper_path)} -o #{paper.filename_doi}.crossref.xml \
      --template #{cross_ref_template_path}`

      if File.exists?("#{paper.directory}/#{paper.filename_doi}.crossref.xml")
        "#{paper.directory}/#{paper.filename_doi}.crossref.xml"
      else
        abort("Looks like we failed to compile the Crossref XML")
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
