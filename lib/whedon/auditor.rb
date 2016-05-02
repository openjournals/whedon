module Whedon
  class Auditor
    attr_accessor :review_body

    def initialize(review_body)
      @review_body = review_body
    end

    def audit
      verify_author
      verify_version
      verify_repository
      verify_archive
    end

    def verify_author
      author = review_body[AUTHOR_REGEX]
      puts "Author: #{author}" if author
    end

    def verify_version
      version = review_body[VERSION_REGEX]
      puts "Version: #{version}" if version
    end

    def verify_repository
      repository_address = review_body[REPO_REGEX]
      puts "Repository: #{repository_address}" if repository_address
    end

    def verify_archive
      archive = review_body[ARCHIVE_REGEX]
      puts "Archive: #{archive}" if archive
    end
  end
end
