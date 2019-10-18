#' Remove secondary alignments form a pafr alignment
#' @param ali genomic alignment in \code{pafr} or \code{tbl_df} format, as
#' returned by \code{\link{read_paf}}
#' @param remove_inversions, logical, if \code{TRUE} also remove inversions (tp
#' flag 'I' or 'i') from alignment.
#' @examples
#' ali <- read_paf( system.file("extdata", "fungi.paf", package = "pafr") ) 
#' ali
#' filter_secondary_alignments(ali)
#' @export
filter_secondary_alignments <- function(ali, remove_inversions=FALSE) {
    if ("tp" %in% names(ali)) {
        if (remove_inversions) {
            return(ali[ali$tp == "P", ])
        }
        return(ali[ali$tp %in% c("I", "i", "P"), ])
    }
    stop("No 'tp' flag in alignment, cannot filter secondary alignments")
}
