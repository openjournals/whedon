# The Whedon::Auditor simply uses the regexes defined for a GitHub review issue
# body and prints them out.

module Whedon
  class Auditor
    attr_accessor :review_body

    def initialize(review_body)
      @review_body = review_body
    end

    def audit
      puts verify_author
      puts verify_version
      puts verify_repository
      puts verify_archive
    end

    def verify_author
      author = review_body[AUTHOR_REGEX]
      return "Author: #{author}" if author
    end

    def verify_version
      version = review_body[VERSION_REGEX]
      return "Version: #{version}" if version
    end

    def verify_repository
      repository_address = review_body[REPO_REGEX]
      return "Repository: #{repository_address}" if repository_address
    end

    def verify_archive
      archive = review_body[ARCHIVE_REGEX]
      return "Archive: #{archive}" if archive
    end
  end
end
