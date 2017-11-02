require_relative 'spec_helper'

describe Whedon do

  subject(:paper) { Whedon::Paper.new(17, 'fixtures/paper/paper.md') }
  # TODO - should raise an error when initializing a paper with no title
  # subject(:paper_without_title) { Whedon::Paper.new(17, 'fixtures/paper/paper_with_missing_title.md') }

  it "should initialize properly" do
    expect(subject.review_issue_id).to eql(17)
    expect(subject.authors.size).to eql(2)
    expect(subject.authors.first.affiliation).to eql('GitHub Inc., Disney Inc.')
    expect(subject.paper_path).to eql('fixtures/paper/paper.md')
    expect(subject.bibliography_path).to eql('paper.bib')
  end

  it "should know what the review_issue_url is" do
    expect(subject.review_issue_url).to eql("https://github.com/openjournals/#{Whedon::REVIEW_REPOSITORY}/issues/17")
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
    expect(subject.joss_resource_url).to eql("#{Whedon::JOURNAL_URL}/papers/10.21105/joss.00017")
  end

  it "should know how generate_authors" do
    authors_xml = Nokogiri::XML(subject.crossref_authors)
    expect(authors_xml.search('person_name').size).to eql(2)
    expect(authors_xml.search('person_name[sequence="first"]').size).to eql(1)
    expect(authors_xml.search('person_name[sequence="additional"]').size).to eql(1)
    expect(authors_xml.xpath('//ORCID').first.text).to eql("http://orcid.org/0000-0002-3957-2474")
  end

  it "should raise an error if missing fields" do
  end
end
