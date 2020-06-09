FROM pandoc/latex:2.10

# Install additional LaTeX packages
RUN tlmgr install \
  environ \
  marginnote \
  pgf \
  preprint \
  seqsplit \
  tcolorbox \
  titlesec \
  trimspaces \
  xstring

# Copy templates, images, and other resources
COPY ./resources /usr/local/share/openjournals

ENV JOURNAL=joss

# Invoce pandoc with special defaults file. Input is read from `paper.md`,
# while output is written to `paper.pdf`
ENTRYPOINT pandoc \
  --defaults=/usr/local/share/openjournals/docker-defaults.yaml \
  --defaults=/usr/local/share/openjournals/${JOURNAL}/defaults.yaml
