require_relative 'spec_helper'
require 'nokogiri'

describe Whedon::Processor do

  subject { Whedon::Processor.new(17, File.read('fixtures/review_body.txt')) }

  it "should know what the review_issue_url is" do
    expect(subject.review_issue_url).to eql("https://github.com/openjournals/joss-reviews/issues/17")
  end

  it "should know how to generate joss_id" do
    expect(subject.joss_id).to eql("joss.00017")
  end

  it "should know how to generate the formatted_doi" do
    expect(subject.formatted_doi).to eql("10.21105/joss.00017")
  end

  it "should know how to generate the filename_doi" do
    expect(subject.filename_doi).to eql("10.21105.joss.00017")
  end

  it "should know how to generate the joss_resource_url" do
    expect(subject.joss_resource_url).to eql("http://joss.theoj.org/papers/10.21105/joss.00017")
  end

  it "should know how generate_authors" do
    authors_xml = Nokogiri::XML(subject.generate_crossref_authors('fixtures/paper/paper.md'))
    expect(authors_xml.search('person_name').size).to eql(2)
    expect(authors_xml.search('person_name[sequence="first"]').size).to eql(1)
    expect(authors_xml.search('person_name[sequence="additional"]').size).to eql(1)
    expect(authors_xml.xpath('//ORCID').first.text).to eql("http://orcid.org/0000-0002-3957-2474")
  end
end
