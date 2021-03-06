#' Read genomic intervals in bed format
#'
#' The first three columns of the file specified by \code{file_name} must
#' contain data in the standard bed format (i.e., a genomic interval
#' represented by 0-based half-open interval with seq-id, start and end position). 
#' These columns will be renamed to 'chrom', 'start' and 'end', respectively. Any
#' other columns present in the data will be left unmodified.
#' 
#' The file is read into memory with \code{\link{read.table}}, with the
#' argument \code{sep} set to \code{'\t'} and \code{stringsAsFactors} set to
#' FALSE. All other arguments are left as default, but arguments can be passed
#' from \code{read_bed} to \code{read.table}.

#' @param file_name  Path to the bed file to be read in
#' @param tibble logical  If TRUE, the genomic intervals are returned as
#' a tidy \code{tbl_df}.
#' @param ...  Other arugments passed to \code{read.table}
#' @return Either a \code{data.frame} or a \code{tbl_df} with at least three
#' columns named 'chrom', 'start' and 'end'
#' @importFrom tibble as_tibble
#' @importFrom utils read.table
#' @examples
#' bed_path <- system.file("extdata", "Q_centro.bed", package="pafr")
#' centro <- read_bed(bed_path)
#' centro
#' # Can pass arguments to read.table
#' miss_two <- read_bed(bed_path, skip=2)
#' miss_two 
#' @export
read_bed <- function(file_name, tibble = FALSE, ...) {
    res <- read.table(file_name, sep = "\t", stringsAsFactors = FALSE, ...)
    if (ncol(res) < 3) {
        stop("Bed file must have at least three columns, data has", ncol(res))
    }
    names(res)[1:3] <- c("chrom", "start", "end")
    if (tibble) {
        return(as_tibble(res))
    }
    res
}


.make_numeric <- function(df, cols) {
    for (i in cols) {
        df[, i] <- as.numeric(df[, i])
    }
    df
}

# paf tags encode their data type. This function returns the function
# responsible for changing the 'character' representation of tag values into
# the appropriate type (used by process tags and read_paf).
tag_to_type_fxn <- function(tag_tokens) {
    if (tag_tokens[[2]] %in% c("f", "H", "i")) {
        return(as.numeric)
    }
    identity
}

.one_tag_row <- function(tags) {
    tokens <- strsplit(tags, ":")
    F <- sapply(tokens, tag_to_type_fxn)
    structure(lapply(1:(length(tokens)),
          function(i) F[[i]](tokens[[i]][3])), .Names = sapply(tokens, "[[", 1))
}

#' @importFrom dplyr bind_rows
process_tags <- function(tag_rows) {
    tag_tibble <- dplyr::bind_rows(lapply(tag_rows, .one_tag_row))
    as.data.frame(tag_tibble) #base format is df, so force it back here
}

#' Read a genomic alignment in PAF format
#'
#' See the package vignette for detailed information on the file format and its
#' representation as an R object.
#
#' @param file_name  Path to the .paf file
#' @param tibble logical  If TRUE, the genomic alignments are returned as
#' a tidy \code{tbl_df}
#' @return Either a \code{pafr} object, which acts as a \code{data.frame}, or a
#' \code{tbl_df} containing information on genomic alignments
#' @importFrom tibble as_tibble
#' @examples
#' ali <- read_paf( system.file("extdata", "fungi.paf", package="pafr") )
#' ali
#' @export
read_paf <- function(file_name, tibble=FALSE) {
    lines <- scan(file_name, "", sep = "\n", quiet = TRUE)
    tokens <-  strsplit(lines, "\t")
    res <- do.call(rbind.data.frame, 
                   c(lapply(tokens, "[", 1:12), 
                   stringsAsFactors = FALSE))
    names(res) <- c("qname", "qlen", "qstart", "qend", "strand",
                          "tname", "tlen", "tstart", "tend", "nmatch",
                          "alen", "mapq")

    res <- .make_numeric(res, c(2, 3, 4, 7:12))
    #first 12 columns are always the paf alignment. Anything after this is a
    #tag.
    if (any(lengths(tokens) > 12)) {
        raw_tags <- sapply(tokens, function(x) paste(x[13:length(x)]))
        res <- cbind.data.frame(res, process_tags(raw_tags))
    }
    if (tibble) {
        return(as_tibble(res))
    }
    class(res) <- c("pafr", "data.frame")
    res
}

#' @export
print.pafr <- function(x, ...) {
    if (nrow(x) == 1) {
        print_alignment(x)
        return(invisible(x))
    }
    print_pafr_rows(x)
    return(invisible(x))
}
    
print_pafr_rows <- function(x) {
    cat("pafr object with ", nrow(x), " alignments (",
        round(sum(x$alen) / 1e6, 1), "Mb)\n", sep = "")
    cat(" ", length(unique(x$qname)), " query seqs\n", sep = "")
    cat(" ", length(unique(x$tname)), " target seqs\n", sep = "")
    ntags <- ncol(x) - 12
    if (ntags < 12) {
        if (ntags > 0) {
            tags <- paste(names(x)[13:ncol(x)], collapse = ", ")
        } else {
            tags <- ""
        }

    } else {
        tags <- paste(paste(names(x)[13:23], collapse = ", "), "...")
    }
    cat(" ", ntags, " tags: ", tags, "\n", sep = "")
}

print_alignment <- function(x) {
    ali_str <- paste0(x[["qname"]], ":", x[["qstart"]], "-", x[["qend"]], " v ",
                      x[["tname"]], ":", x[["tstart"]], "-", x[["tend"]])
    cat("Single pafr alignment:\n")
    cat(" ", ali_str, "\n", sep = "")
}
