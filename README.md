## What is Whedon?

Whedon is a collection of command-line utilities to manage JOSS submissions. He may one day be a sentient being that interacts with authors and reviewers during the review process on https://github.com/openjournals/joss-reviews

### Usage

```bash
# List all open reviews
whedon reviews

# Open the browser for a review
whedon open {id}

# Verify the submission is complete
whedon verify {id}

# This does the following:
#   1. Reads the issue in joss-reviews
#   2. Checks that the repository address can be cloned
#   3. Checks that the archive address resolves
#   4. Looks for the paper.md
#   5. Compiles the markdown to a custom XML: pandoc -s -f markdown paper.md -o paper.xml --template xml.template
#   6. Checks that the compiled XML document has certain attributes (title, authors, summary etc.)

# Prepare to accept paper into JOSS
whedon prepare {id}

# This does the following:
#   1. Compiles the PDF with: pandoc -S -o paper.pdf -V geometry:margin=1in --filter pandoc-citeproc paper.md --template latex.template
#   2. Uploads the compiled PDF somewhere and update the review issue with a link to the PDF

# Generate Crossref metadata
GITHUB_TOKEN=your_github_token whedon generate_crossref {id}

# This does the following:
#   1. Uses the compiled XML document to generate crossref.xml
#   2. Uses https://github.com/inukshuk/bibtex-ruby to try and parse citations (see lib/bibtex.rb)
#   3. Generates the full XML (see lib/crossref.rb)
#   4. Saves the

# Accept a paper into JOSS
GITHUB_TOKEN=your_github_token whedon accept {id}
```

### What happens when someone submits

1. We pick up the new paper with `whedon list`
2. Then we prepare the submission `whedon prepare`
