require_relative 'github'

module Whedon
  class Reviews
    include GitHub

    attr_accessor :review_repository_url

    def initialize(review_repository_url)
      @review_repository_url = review_repository_url
    end

    def list_current
      current_reviews = client.list_issues(@review_repository_url)
      return "No open reviews" if current_reviews.empty?

      current_reviews.each do |issue|
        puts issue.html_url
        puts "Opened: #{issue.created_at}"
        puts ""
      end
      nil
    end
  end
end
