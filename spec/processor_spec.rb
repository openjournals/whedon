require_relative 'spec_helper'
require 'nokogiri'

describe Whedon::Processor do
  subject(:paper) { Whedon::Paper.new(17, 'fixtures/paper/paper.md') }
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
    allow(processor).to receive_message_chain(:find_bib_path, :first).and_return("fixtures/paper/paper.bib")
    generated = processor.generate_crossref
    expect(generated).to eql("fixtures/paper/10.21105.joss.00017.crossref.xml")
  end
end
