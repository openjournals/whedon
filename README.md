## What is Whedon?

Whedon is a collection of command-line utilities to manage JOSS submissions. He may one day be a sentient being that interacts with authors and reviewers during the review process on https://github.com/openjournals/joss-reviews

### Usage

```bash
# List all open reviews
GITHUB_TOKEN=your_github_token whedon list

# Show the status of a review
GITHUB_TOKEN=your_github_token whedon show {id}

# Verify the submission is complete
GITHUB_TOKEN=your_github_token whedon verify {id}

# This does the following:
#   1. Reads the issue in joss-reviews
#   2. Checks that the repository address can be cloned
#   3. Checks that the archive address resolves
#   4. Looks for the paper.md
#   5. Compiles the markdown to a custom XML: pandoc -s -f markdown paper.md -o paper.xml --template xml.template
#   6. Checks that the compiled XML document has certain attributes (title, authors, summary etc.)

# Prepare to accept paper into JOSS
GITHUB_TOKEN=your_github_token whedon prepare {id}

# This does the following:
#   1. Compiles the PDF with: pandoc -S -o paper.pdf -V geometry:margin=1in --filter pandoc-citeproc paper.md --template latex.template
#   2. Uploads the compiled PDF somewhere and update the review issue with a link to the PDF

# Generate Crossreg metadata
GITHUB_TOKEN=your_github_token whedon generate_crossref {id}

# This does the following:
#   1. Uses the compiled XML document to generate crossref.xml
#   2. Uses https://github.com/inukshuk/bibtex-ruby to try and parse citations
#   3. http://www.crossref.org/help/samples/references.xml
#
#   <citation key="ref1">
#     <journal_title>Current Opinion in Oncology</journal_title>
#     <author>Chauncey</author>
#     <volume>13</volume>
#     <first_page>21</first_page>
#     <cYear>2001</cYear>
#   </citation>
#   
#   <citation key="ref2">
#     <doi>10.5555/small_md_0001</doi>
#   </citation>
#
#   <citation key="ref=3">
#     <unstructured_citation>
#       Clow GD, McKay CP, Simmons Jr. GM, and Wharton RA, Jr. 1988. Climatological observations and predicted sublimation rates at Lake Hoare, Antarctica. Journal of Climate 1:715-728.
#     </unstructured_citation>
#   </citation>

# Accept a paper into JOSS
GITHUB_TOKEN=your_github_token whedon accept {id}
```

### What happens when someone submits

1. We pick up the new paper with `whedon list`
2. Then we prepare the submission `whedon prepare`
