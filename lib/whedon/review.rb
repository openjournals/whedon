require_relative 'github'
require 'pry'

module Whedon
  class Review
    include GitHub

    attr_accessor :review_issue_id
    attr_accessor :review_repository

    AUTHOR_REGEX = /(?<=\*\*Submitting author:\*\*\s)(\S+)/
    REPO_REGEX = /(?<=\*\*Repository:\*\*\s)(\S+)/
    VERSION_REGEX = /(?<=\*\*Version:\*\*\s)(\S+)/
    ARCHIVE_REGEX = /(?<=\*\*Archive:\*\*\s)(\S+)/

    def initialize(review_issue_id, repository)
      @review_issue_id = review_issue_id
      @review_repository = repository
    end

    def issue_body
      review = client.issue(review_repository, review_issue_id)
      return review.body
    end

    def verify
      author = issue_body[AUTHOR_REGEX]
      puts "Author: #{author}" if author

      repository_address = issue_body[REPO_REGEX]
      puts "Repository: #{repository_address}" if repository_address

      version = issue_body[VERSION_REGEX]
      puts "Version: #{version}" if version

      archive = issue_body[ARCHIVE_REGEX]
      puts "Archive: #{archive}" if archive
    end
  end
end
