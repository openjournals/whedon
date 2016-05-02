require_relative 'github'
require 'tilt'
require 'securerandom'

module Whedon
  class Processor
    include GitHub

    attr_accessor :review_issue_id
    attr_accessor :review_body
    attr_accessor :paper_path
    attr_accessor :xml_path
    attr_accessor :doi_batch_id

    def initialize(review_issue_id, review_body)
      @review_issue_id = review_issue_id
      @review_body = review_body
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

    # Find XML paper
    def find_xml_paths
      xml_paths = []
      Find.find("tmp/#{review_issue_id}") do |path|
        xml_paths << path if path =~ /paper\.xml$/
      end

      return xml_paths
    end

    # Try and compile the paper target
    def compile
      latex_template_path = "#{Dir.pwd}/resources/latex.template"
      xml_template_path = "#{Dir.pwd}/resources/xml.template"
      paper_directory = File.dirname(paper_path)

      # TODO: may eventually want to swap out the latex template
      `cd #{paper_directory} && pandoc -S -o paper.pdf -V geometry:margin=1in --filter pandoc-citeproc #{File.basename(paper_path)} --template #{latex_template_path}`

      if File.exists?("#{paper_directory}/paper.pdf")
        `open #{paper_directory}/paper.pdf`
      else
        puts "Looks like we failed to compile the PDF"
      end

      `cd #{paper_directory} && pandoc -s -f markdown #{File.basename(paper_path)} -o paper.xml --template #{xml_template_path}`

      if File.exists?("#{paper_directory}/paper.xml")
        `open #{paper_directory}/paper.xml`
      else
        puts "Looks like we failed to compile the XML"
      end
    end

    def generate_crossref
      template = Tilt.new('templates/foo.erb')
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
