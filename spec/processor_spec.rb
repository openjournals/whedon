require_relative 'spec_helper'
require 'nokogiri'

describe Whedon::Processor do
  subject(:paper) { Whedon::Paper.new(17, 'fixtures/paper/paper.md') }
  subject(:paper_with_funky_bib_path) { Whedon::Paper.new(17, 'fixtures/paper/paper-bib.md') }

  subject(:processor) { Whedon::Processor.new(17, File.read('fixtures/review_body.txt')) }

  before do
    ENV["JOURNAL_LAUNCH_DATE"] = Time.now.strftime('%F')
    processor.paper = paper
  end

  after do
    FileUtils.rm_rf("fixtures/paper/10.21105.joss.00017.crossref.xml")
  end

  it "should know how to initialize properly" do
    expect(processor.review_issue_id).to eql(17)
    expect(processor.current_volume).to eql(1)
    expect(processor.current_issue).to eql(1)
  end

  it "should know how to find papers to be compiled" do
    expect(processor.find_paper_paths('fixtures/test_paper').size).to eql(2)
    expect(processor.find_paper_paths('fixtures/test_paper')).to include("fixtures/test_paper/paper.md")
  end

  it "should know how to compile Crossref XML" do
    expect(paper_with_funky_bib_path.bibtex_path).to eq("fixtures/paper/weird-bib-path.bib")
    generated = processor.generate_crossref
    expect(generated).to eql("fixtures/paper/10.21105.joss.00017.crossref.xml")
  end

  it "should know what to do with extra references" do
    expect{processor.check_for_extra_bibtex_entries}.to raise_error SystemExit
  end

  it "should return an error message about the extraneous references" do
    expect {
      begin processor.check_for_extra_bibtex_entries
      rescue SystemExit
      end
    }.to output("Can't compile the PDF, the bibtex file has 6 extraneous references: `@SWIFT07, @SWIFT09, @SWIFT11, @PEGASUS05, @PEGASUS04, @AIMES15`\n").to_stderr
  end
end
