require_relative 'spec_helper'

describe Whedon do

  subject(:paper) { Whedon::Paper.new(17, nil, 'fixtures/paper/paper.md') }
  subject(:paper_with_one_author) { Whedon::Paper.new(17, nil, 'fixtures/paper/paper-single-author.md') }
  subject(:paper_with_harder_names) { Whedon::Paper.new(17, nil, 'fixtures/paper/paper-with-harder-names.md') }

  it "should initialize properly" do
    expect(paper.review_issue_id).to eql(17)
    expect(paper.authors.size).to eql(2)
    expect(paper.authors.first.affiliation).to eql('GitHub Inc., Disney Inc.')
    expect(paper.paper_path).to eql('fixtures/paper/paper.md')
    expect(paper.bibliography_path).to eql('paper.bib')
  end

  it "should know what the review_issue_url is" do
    expect(paper.review_issue_url).to eql("https://github.com/#{ENV['REVIEW_REPOSITORY']}/issues/17")
  end

  it "should know how to generate joss_id" do
    expect(paper.joss_id).to eql("joss.00017")
  end

  it "should know how to generate the formatted_doi" do
    expect(paper.formatted_doi).to eql("10.21105/joss.00017")
  end

  it "should know how to generate the filename_doi" do
    expect(paper.filename_doi).to eql("10.21105.joss.00017")
  end

  it "should know how to generate the joss_resource_url" do
    expect(paper.joss_resource_url).to eql("#{ENV['JOURNAL_URL']}/papers/10.21105/joss.00017")
  end

  it "should know how to generate the paper#pdf_url" do
    expect(paper.pdf_url).to eql("http://www.theoj.org/joss-papers-testing/joss.00017/10.21105.joss.00017.pdf")
  end

  it "should know what the paper#paper_org is" do
    expect(paper.paper_org).to eql("openjournals")
  end

  it "should know what the paper#paper_repo is" do
    expect(paper.paper_repo).to eql("joss-papers-testing")
  end

  it "should know what its tags are" do
    expect(paper.tags).to eql(["example", "tags", "for the paper"])
  end

  it "should know how generate_authors" do
    authors_xml = Nokogiri::XML(paper.crossref_authors)
    expect(authors_xml.search('person_name').size).to eql(2)
    expect(authors_xml.search('person_name[sequence="first"]').size).to eql(1)
    expect(authors_xml.search('person_name[sequence="additional"]').size).to eql(1)
    expect(authors_xml.xpath('//ORCID').first.text).to eql("http://orcid.org/0000-0002-3957-2474")
  end

  it "should know how to format citation strings for multi-author papers" do
    expect(paper.authors.size).to eql(2)
    expect(paper.authors.first.name).to eql('Arfon Smith')
    expect(paper.citation_author).to eql("Smith et al.")
  end

  it "should know how to format citation strings for single-author papers" do
    expect(paper_with_one_author.authors.size).to eql(1)
    expect(paper_with_one_author.citation_author).to eql("Smith, A. M.")
  end

  it "should know how to format citation strings for multi-author papers" do
    expect(paper_with_harder_names.authors.size).to eql(2)
    expect(paper_with_harder_names.citation_author).to eql("Smith et al.")
    expect(paper_with_harder_names.authors.last.last_name).to eq('van Dishoeck')
  end

  it "should fail to initialize when authors don't have affiliations" do
    expect { Whedon::Paper.new(17, nil, 'fixtures/paper/paper-with-missing-affiliations.md') }.to raise_error("Author (Arfon M Smith) is missing affiliation")
  end

  it "should fail to initialize when title is missing" do
    expect { Whedon::Paper.new(17, nil, 'fixtures/paper/paper_with_missing_title.md') }.to raise_error(/Paper YAML header is missing expected fields: title/)
  end

  it "should know how to generate the deposit_payload" do
    VCR.use_cassette('review') do
      %w{title tags languages authors doi archive_doi repository_address editor reviewers}.each do |attribute|
        expect(paper_with_harder_names.deposit_payload['paper'][attribute].nil?).to be_falsey
      end
    end
  end
end
