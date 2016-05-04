require 'octokit'

require_relative 'whedon/auditor'
require_relative 'whedon/bibtex'
require_relative 'whedon/github'
require_relative 'whedon/processor'
require_relative 'whedon/review'
require_relative 'whedon/reviews'
require_relative 'whedon/version'

require 'dotenv'
Dotenv.load

module Whedon

  AUTHOR_REGEX = /(?<=\*\*Submitting author:\*\*\s)(\S+)/
  REPO_REGEX = /(?<=\*\*Repository:\*\*.<a\shref=)"(.*?)"/
  VERSION_REGEX = /(?<=\*\*Version:\*\*\s)(\S+)/
  ARCHIVE_REGEX = /(?<=\*\*Archive:\*\*.<a\shref=)"(.*?)"/

  class Paper
    include GitHub

    attr_accessor :review_issue_id
    attr_accessor :review_repository
    attr_accessor :review_issue_body

    def self.list
      Whedon::Reviews.new(ENV['JOSS_REVIEW_REPO']).list_current
    end

    def initialize(review_issue_id)
      @review_issue_id = review_issue_id
      @review_repository = ENV['JOSS_REVIEW_REPO']
    end

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

    def generate_crossref

    end
  end
end
