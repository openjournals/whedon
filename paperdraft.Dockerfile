FROM pandoc/latex:2.11.2

# Update tlmgr
RUN tlmgr update --self

# Install additional LaTeX packages
RUN tlmgr install \
  algorithmicx \
  algorithms \
  biblatex \
  booktabs \
  caption \
  collection-xetex \
  draftwatermark \
  environ \
  etoolbox \
  everypage \
  fancyvrb \
  float \
  fontspec \
  latexmk \
  lineno \
  listings \
  logreq \
  marginnote \
  mathspec \
  pgf \
  preprint \
  seqsplit \
  tcolorbox \
  titlesec \
  trimspaces \
  xcolor \
  xkeyval \
  xstring

# Copy templates, images, and other resources
ARG openjournals_path=/usr/local/share/openjournals
COPY ./resources $openjournals_path
COPY ./resources/docker-entrypoint.sh /usr/local/bin/paperdraft

ENV JOURNAL=joss
ENV OPENJOURNALS_PATH=$openjournals_path

# Input is read from `paper.md` by default, but can be overridden. Output is
# written to `paper.pdf`
ENTRYPOINT ["/usr/local/bin/paperdraft"]
CMD ["paper.md"]
