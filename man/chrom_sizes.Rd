% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dotplot.R
\name{chrom_sizes}
\alias{chrom_sizes}
\title{Extract the sizes of all sequences in a paf alignment}
\usage{
chrom_sizes(ali)
}
\arguments{
\item{ali}{pafr or tibble containing the genome alignment (as returned by
\code{\link{read_paf}})}
}
\value{
list with two elements (tlens and qlens)  Each element is a
dataframe with one column of sequence names and another column containing
the length of each sequence
}
\description{
Extract the sizes of all sequences in a paf alignment
}
\examples{
ali <- read_paf( system.file("extdata", "fungi.paf", package="pafr") )
chrom_sizes(ali)
}
