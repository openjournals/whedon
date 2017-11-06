require_relative 'spec_helper'

describe Whedon::Review do

  subject { Whedon::Review.new(17, ENV['REVIEW_REPOSITORY']) }

  it "can should return the correct number of review issues" do
    VCR.use_cassette('review') do
      expect(subject.issue_body).to match(/Submitting author/)
    end
  end
end
