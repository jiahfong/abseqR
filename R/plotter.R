#' Monolith AbSeq Plot function - the "driver" program
#'
#' @include abundanceAnalysis.R
#' @include annotationAnalysis.R
#' @include distributions.R
#' @include diversityAnalysis.R
#' @include primerAnalysis.R
#' @include productivityAnalysis.R
#' @include upstreamAnalysis.R
#' @include util.R
#'
#' @import ggplot2
#'
#'
#' @param sampleNames vector type. Vector of sample names in strings
#' @param directories vector type. Vector of directories in strings, must be
#' 1-1 with sampleNames
#' @param analysis vector / list type. What analysis to plot for. If sampleNames
#' or directories is > 1 (i.e. AbSeqCRep), then make sure that it's
#' an intersection of all analysis conducted by the repertoires, otherwise, it
#' wouldn't make sense
#' @param outputDir string type. Where to dump the output
#' @param primer5Files vector / list type. Collection of strings that the sample
#' used for primer5 analysis. If sample N doesn't have a primer 5 file,
#' leave it as anthing but a valid file path.
#' @param primer3Files vector / list type. Collection of strings that the sample
#' used for primer 3 analysis. If sample N doesn't have a primer 3 file,
#' leave it as anthing but a valid file path.
#' @param upstreamRanges list type. Collection of "None"s or vector
#' denoting upstreamStart and upstreamEnd for each sample.
#' @param skipDgene logical type. Whether or not to skip D gene distribution plot
#'
#' @return none
.plotSamples <-
    function(sampleNames,
             directories,
             analysis,
             outputDir,
             primer5Files,
             primer3Files,
             upstreamRanges,
             skipDgene = FALSE) {
        if (!dir.exists(outputDir)) {
            dir.create(outputDir)
        }
        # mashedNames are "file-system" friendly names, we collapse them
        # with an underscore (from here on out, all plot names will be
        # <mashedNames>_<...>.png)
        mashedNames <- paste(sampleNames, collapse = "_")

        # combinedNames are "human" friendly names, we combine them with
        # commas (from here on out, plot titles will be
        # "<combinedNames> <...>")
        combinedNames <- paste(sampleNames, collapse = ", ")

        ##################################################
        #                                                #
        #               ANNOTATION PLOTS                 #
        #                                                #
        ##################################################
        if (ABSEQ_DIR_ANNOT %in% analysis) {
            annotOut <- file.path(outputDir, ABSEQ_DIR_ANNOT)
            if (!file.exists(annotOut)) {
                dir.create(annotOut)
            }
            annotDirectories <-
                vapply(directories, file.path, ABSEQ_DIR_ANNOT,
                       USE.NAMES = FALSE, FUN.VALUE = "")
            .annotAnalysis(annotDirectories, annotOut, sampleNames, mashedNames)
        }

        ##################################################
        #                                                #
        #               ABUNDANCE PLOTS                  #
        #                                                #
        ##################################################
        if (ABSEQ_DIR_ABUN %in% analysis) {
            abunOut <- file.path(outputDir, ABSEQ_DIR_ABUN)
            if (!file.exists(abunOut)) {
                dir.create(abunOut)
            }
            abundanceDirectories <-
                vapply(directories, file.path, ABSEQ_DIR_ABUN,
                       USE.NAMES = FALSE, FUN.VALUE = "")
            .abundanceAnalysis(
                abundanceDirectories,
                abunOut,
                sampleNames,
                combinedNames,
                mashedNames,
                skipDgene = skipDgene
            )
        }

        ##################################################
        #                                                #
        #              PRODUCTIVITY PLOTS                #
        #                                                #
        ##################################################
        if (ABSEQ_DIR_PROD %in% analysis) {
            prodOut <- file.path(outputDir, ABSEQ_DIR_PROD)
            if (!file.exists(prodOut)) {
                dir.create(prodOut)
            }
            productivityDirectories <-
                vapply(directories, file.path,
                       ABSEQ_DIR_PROD, USE.NAMES = FALSE, FUN.VALUE = "")
            .productivityAnalysis(productivityDirectories,
                                  prodOut,
                                  sampleNames,
                                  combinedNames,
                                  mashedNames)
        }

        ##################################################
        #                                                #
        #               DIVERSITY PLOTS                  #
        #                                                #
        ##################################################
        if (ABSEQ_DIR_DIV %in% analysis) {
            diversityOut <- file.path(outputDir, ABSEQ_DIR_DIV)
            if (!file.exists(diversityOut)) {
                dir.create(diversityOut)
            }
            diversityDirectories <-
                vapply(directories, file.path,
                       ABSEQ_DIR_DIV, USE.NAMES = FALSE, FUN.VALUE = "")
            .diversityAnalysis(diversityDirectories,
                               diversityOut,
                               sampleNames,
                               mashedNames)
        }

        ##################################################
        #                                                #
        #               CLONOTYPE PLOTS                  #
        #                                                #
        ##################################################
        # pairwise clonotype comparison analyses only occurs when there's
        # > 1 sample
        if (length(sampleNames) > 1 &&
            ABSEQ_DIR_DIV %in% analysis) {
            pairwiseOut <- file.path(outputDir, ABSEQ_DIR_PAIR)
            if (!file.exists(pairwiseOut)) {
                dir.create(pairwiseOut)
            }
            diversityDirectories <- vapply(directories, file.path,
                                           ABSEQ_DIR_DIV, USE.NAMES = FALSE,
                                           FUN.VALUE = "")
            .clonotypeAnalysis(diversityDirectories,
                               pairwiseOut,
                               sampleNames,
                               mashedNames)
        }

        ##################################################
        #                                                #
        #               PRIMER.S  PLOTS                  #
        #                                                #
        ##################################################
        if (ABSEQ_DIR_PRIM %in% analysis) {
            primerOut <- file.path(outputDir, ABSEQ_DIR_PRIM)
            if (!file.exists(primerOut)) {
                dir.create(primerOut)
            }
            primerDirectories <- vapply(directories,
                                        file.path,
                                        ABSEQ_DIR_PRIM,
                                        USE.NAMES = FALSE,
                                        FUN.VALUE = "")
            .primerAnalysis(
                primerDirectories,
                primer5Files,
                primer3Files,
                primerOut,
                sampleNames,
                combinedNames,
                mashedNames
            )
        }

        ##################################################
        #                                                #
        #               UPSTREAM 5UTR PLOTS              #
        #                                                #
        ##################################################
        if (ABSEQ_DIR_5UTR %in% analysis) {
            utr5Out <- file.path(outputDir, ABSEQ_DIR_5UTR)
            if (!file.exists(utr5Out)) {
                dir.create(utr5Out)
            }
            utr5Directories <-
                vapply(directories, file.path, ABSEQ_DIR_5UTR,
                       USE.NAMES = FALSE, FUN.VALUE = "")
            .UTR5Analysis(
                utr5Directories,
                utr5Out,
                sampleNames,
                combinedNames,
                mashedNames,
                upstreamRanges
            )
        }

        ##################################################
        #                                                #
        #               UPSTREAM SEC.S PLOTS             #
        #                                                #
        ##################################################
        if (ABSEQ_DIR_SEC %in% analysis) {
            secOut <- file.path(outputDir, ABSEQ_DIR_SEC)
            if (!file.exists(secOut)) {
                dir.create(secOut)
            }
            secDirectories <-
                vapply(directories, file.path, ABSEQ_DIR_SEC,
                       USE.NAMES = FALSE, FUN.VALUE = "")
            .secretionSignalAnalysis(
                secDirectories,
                secOut,
                sampleNames,
                combinedNames,
                mashedNames,
                upstreamRanges
            )
        }
    }
