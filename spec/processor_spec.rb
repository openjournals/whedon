require_relative 'spec_helper'
require 'nokogiri'

describe Whedon::Processor do
  subject(:paper) { Whedon::Paper.new(17, nil, 'fixtures/paper/paper.md') }
  subject(:paper_with_funky_bib_path) { Whedon::Paper.new(17, nil, 'fixtures/paper/paper-bib.md') }

  subject(:processor) { Whedon::Processor.new(17, File.read('fixtures/review_body.txt')) }

  context "Without CURRENT_ISSUE and CURRENT_VOLUME in ENV" do
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

    it "should know how to find latex papers to be compiled" do
      expect(processor.find_paper_paths('fixtures/latex_paper').size).to eql(1)
      expect(processor.find_paper_paths('fixtures/latex_paper')).to include("fixtures/latex_paper/paper.tex")
    end

    it "should know how to compile Crossref XML" do
      VCR.use_cassette('joss-lookup') do
        ENV['JOURNAL_URL'] = 'http://joss.theoj.org'
        expect(paper_with_funky_bib_path.bibtex_path).to eq("fixtures/paper/weird-bib-path.bib")
        generated = processor.generate_crossref
        expect(generated).to eql("fixtures/paper/10.21105.joss.00017.crossref.xml")
      end
    end
  end

  context "with CURRENT_ISSUE and CURRENT_VOLUME overridden" do
    before do
      ENV["JOURNAL_LAUNCH_DATE"] = Time.now.strftime('%F')
      ENV["CURRENT_ISSUE"] = "12344"
      ENV["CURRENT_VOLUME"] = "12"
      processor.paper = paper
    end

    after do
      FileUtils.rm_rf("fixtures/paper/10.21105.joss.00017.crossref.xml")
      ENV["CURRENT_ISSUE"] = nil
      ENV["CURRENT_VOLUME"] = nil
    end

    it "should know how to initialize properly" do
      expect(processor.review_issue_id).to eql(17)
      expect(processor.current_volume).to eql("12")
      expect(processor.current_issue).to eql("12344")
    end
  end
end
