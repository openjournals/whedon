## What is Whedon?

Whedon is a collection of command-line utilities to manage JOSS submissions. He may one day be a sentient being that interacts with authors and reviewers during the review process on https://github.com/openjournals/joss-reviews

### Usage

```bash
# List all open reviews
GITHUB_TOKEN=your_github_token whedon list

# Show the status of a review
GITHUB_TOKEN=your_github_token whedon show {id}

# Prepare to accept paper into JOSS
GITHUB_TOKEN=your_github_token whedon prepare {id}

# Accept a paper into JOSS
GITHUB_TOKEN=your_github_token whedon accept {id}
```


