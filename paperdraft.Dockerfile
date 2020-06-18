FROM pandoc/latex:2.10

# Install additional LaTeX packages
RUN tlmgr install \
  algorithmicx \
  algorithms \
  booktabs \
  caption \
  collection-xetex \
  environ \
  etoolbox \
  fancyvrb \
  float \
  fontspec \
  latexmk \
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

# Create entrypoint script: invoke pandoc with special defaults files.
ARG openjournals_dir=/usr/local/share/openjournals
RUN printf "#!/bin/sh\n/usr/bin/pandoc --defaults=%s --defaults=%s \"\$@\"\n" \
           "$openjournals_dir/docker-defaults" \
           "$openjournals_dir/\${JOURNAL}/defaults.yaml" \
           > /usr/local/bin/paperdraft \
  && chmod +x /usr/local/bin/paperdraft

# Copy templates, images, and other resources
COPY ./resources $openjournals_dir

ENV JOURNAL=joss

# Input is read from `paper.md` by default, but can be overridden. Output is
# written to `paper.pdf`
ENTRYPOINT ["/usr/local/bin/paperdraft"]
CMD ["paper.md"]
