require_relative 'github'

require 'restclient'
require 'securerandom'
require 'yaml'

module Whedon
  class Processor
    include GitHub
    include Compilers

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
    attr_accessor :current_year
    attr_accessor :custom_path

    def initialize(review_issue_id, review_body, custom_path=nil)
      @review_issue_id = review_issue_id
      @review_body = review_body
      @repository_address = review_body[REPO_REGEX]
      @archive_doi = review_body[ARCHIVE_REGEX]
      @custom_path = custom_path
      # Probably a much nicer way to do this...
      @current_year = ENV["CURRENT_YEAR"].nil? ? Time.new.year : ENV["CURRENT_YEAR"]
      @current_volume = ENV["CURRENT_VOLUME"].nil? ? Time.new.year - (Time.parse(ENV['JOURNAL_LAUNCH_DATE']).year - 1) : ENV["CURRENT_VOLUME"]
      @current_issue = ENV["CURRENT_ISSUE"].nil? ? 1 + ((Time.new.year * 12 + Time.new.month) - (Time.parse(ENV['JOURNAL_LAUNCH_DATE']).year * 12 + Time.parse(ENV['JOURNAL_LAUNCH_DATE']).month)) : ENV["CURRENT_ISSUE"]
    end

    def set_paper(path)
      @paper = Whedon::Paper.new(review_issue_id, custom_path, path)
    end

    # Clone the repository... (assumes it's git)
    def clone
      repository_address = review_body[REPO_REGEX]

      # Optionally set the path to work in
      path = custom_path ? custom_path : "tmp/#{review_issue_id}"

      # Skip if the repo has already been cloned
      if File.exists?("#{path}/.git")
        puts "Looks like Git repo already exists at #{path}"
        return
      end

      # First make the folder
      FileUtils::mkdir_p("#{path}")

      # Then clone the repository
      `git clone #{repository_address} #{path}`
    end

    # Find possible papers to be compiled
    def find_paper_paths(search_path=nil)
      search_path ||= "tmp/#{review_issue_id}"
      paper_paths = []

      Find.find(search_path) do |path|
        paper_paths << path if path =~ /\bpaper\.tex$|\bpaper\.md$/
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
      generate_pdf(nil, false)
      generate_crossref
      # generate_jats
    end

    def citation_string
      paper_year ||= Time.now.strftime('%Y')
      paper_issue ||= @current_issue
      paper_volume ||= @current_volume

      return "#{paper.citation_author}, (#{paper_year}). #{paper.plain_title}. #{ENV['JOURNAL_NAME']}, #{paper_volume}(#{paper_issue}), #{paper.review_issue_id}, https://doi.org/#{paper.formatted_doi}"
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
                  :metadata => Base64.encode64(paper.deposit_payload.to_json),
                  :doi => paper.formatted_doi,
                  :archive_doi => archive_doi,
                  :citation_string => citation_string,
                  :title => paper.plain_title,
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
