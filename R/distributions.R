#' Bar plotter
#' @description  Plots barplot for all sample in dataframes.
#' If length(sampleNames) == 1, then the bars will also have
#' y-values (or x if horizontal plot) labels on them.
#' Use 'perc' to control if the values are percentages.
#'
#' @include util.R
#' @import ggplot2
#'
#' @param dataframes  list type. List of dataframes
#' @param sampleNames vector type. 1-1 correspondence to dataframes.
#' @param plotTitle string type.
#' @param vert boolean type. True if the plot should be vertical
#' @param xlabel string type
#' @param ylabel string type
#' @param perc boolean type. True if data's axis is a percentage
#' proportion (instead of 0-1) only used if length(sampleNames) == 1
#' @param subs string type
#' @param sorted boolean type. True if bar plot should be sorted in descending
#' order
#' @param cutoff int type. Number of maximum ticks to show (x on vert plots,
#' y on hori plots).
#' @param legendPos string type. Where to position legend (see ggplot's theme())
#'
#' @return ggplot2 object
.plotDist <-
    function(dataframes,
             sampleNames,
             plotTitle,
             vert = TRUE,
             xlabel = "",
             ylabel = "",
             perc = TRUE,
             subs = "",
             sorted = TRUE,
             cutoff = 15,
             legendPos = "right") {
        frames <- length(dataframes)
        # sanity check
        if (length(sampleNames) != frames) {
            stop(
                paste(
                    "Expected equal number of sample names and dataframes, got",
                    length(sampleNames),
                    "samples and",
                    frames,
                    "dataframes."
                )
            )
        }

        # If there was a cutoff, caps will display the right message,
        #  by default it's empty
        caps <- ""

        # if it was percentage, put a % sign in labels, otherwise just normal values
        if (perc) {
            placeholder <- "%0.2f%%"
        } else {
            placeholder <- "%0.2f"
        }

        # ------------  cleaning & transforming data   ----------- #
        for (i in seq_len(frames)) {
            df <- dataframes[[i]]

            # for each dataframe, append a new column 'sample'
            # to indicate where this df came from
            df$sample <- sampleNames[i]

            # sort the values by descending order (strictly speaking,
            # not necessary because it's already sorted
            # - but better be safe than sorry)
            if (sorted) {
                if (vert) {
                    dataframes[[i]] <- df[with(df, order(-y)),]
                } else {
                    dataframes[[i]] <- df[with(df, order(-x)),]
                }
            } else {
                dataframes[[i]] <- df
            }

            # canonicalize NaN, NA, and N/As to NA.
            dataframes[[i]][is.na(dataframes[[i]])] <- "NA"
            dataframes[[i]][dataframes[[i]] == "N/A"] <- "NA"
        }

        # keep a copy of the original list of dataframes without cutoff applied
        originals <- dataframes

        # make sure only the top cutoff is considered
        for (i in seq_len(frames)) {
            df <- dataframes[[i]]
            if (nrow(df) > cutoff) {
                caps <- "Cutoff at top 15"
                dataframes[[i]] <- head(df, cutoff)
            }
        }

        # --------- complete: cleaning & transforming data -------- #


        # merge dataframes into one
        df.union <- do.call("rbind", dataframes)


        # need to compensate for topN in each dataframe
        # 1. gather unique x/y
        # 2. if x/y is in original table but not in top N table,
        #    append row to df.union
        # 3. otherwise, do nothing

        if (frames > 1) {
            colName <- if (vert) 'x' else 'y'
            topN <- unique(df.union[[colName]])
            for (maybeMissing in topN) {
                for (j in seq_len(frames)) {
                    ori <- originals[[j]]
                    if (maybeMissing %in% ori[[colName]]
                        && !(maybeMissing %in% dataframes[[j]][[colName]])) {
                        newRow <- ori[ori[[colName]] == maybeMissing, ]
                        df.union <- rbind(df.union, newRow)
                    } # else, do nothing
                }
            }
        }

        if (missing(ylabel)) {
            ylabel <- "Proportion"
            if (perc) {
                ylabel <- paste(ylabel, "(%)")
            }
        }

        # start plotting --------------------------------

        # abseqPy will flip the x and y values when the plot is "horizontal"
        if (!vert) {
            colnames(df.union)[colnames(df.union) == "x"] <- "xold"
            colnames(df.union)[colnames(df.union) == "y"] <- "x"
            colnames(df.union)[colnames(df.union) == "xold"] <- "y"
        }

        if (sorted) {
            # horizontal: decreasing order from top to bottom
            # vertical: decreasing order from left to right
            coeff <- if (vert) -1 else 1
            g <- ggplot(df.union,
                        aes(x = reorder(x, y * coeff),
                            y = y,
                            label = sprintf(placeholder, y)))
        } else {
            df.union$x <- factor(df.union$x, levels = unique(df.union$x))
            g <- ggplot(df.union, aes(x, y, label = sprintf(placeholder, y)))
        }

        if (!vert) {
            g <- g + coord_flip()
        }

        if (frames == 1) {
            # only maually add fill colour and geom_text if it's a
            # single sample
            g <- g +  geom_bar(stat = 'identity',
                               fill = BLUEHEX,
                               show.legend = FALSE)
            if (vert) {
                g <- g + geom_text(vjust = -0.5, size = 3)
            } else {
                g <- g + geom_text(hjust = 0.50,
                                   vjust = -0.5,
                                   size = 3,
                                   angle = -90)
            }
        } else {
            g <- g + geom_bar(stat = 'identity', aes(fill = sample),
                              position = 'dodge')
        }

        g <- g + theme(text = element_text(size = 10),
                       legend.position = legendPos) +
            labs(
                title = plotTitle,
                subtitle = subs,
                x = xlabel,
                y = ylabel,
                caption = caps
            )
        return(g)
    }


#' Spectratype plotter
#' @description Plots length distribution
#'
#' @import ggplot2
#'
#' @param dataframes list type. List of dataframes.
#' @param sampleNames vector type. 1-1 correspondance with dataframes
#' @param region string type. Region that will be displayed in the plot title.
#' This specifies which region this spectratype belongs to. If not supplied,
#' a default (start, end) range will be displayed instead
#' @param title string type. Ignored if region is specified.
#' @param subtitle string type
#' @param xlabel string type
#' @param ylabel string type
#' @param showLabel bool type. Show geom_text? - Ignored if samples > 1
#'
#' @return ggplot2 object
.plotSpectratype <- function(dataframes,
                             sampleNames,
                             region,
                             title = "Spectratype",
                             subtitle = "",
                             xlabel = "Length(AA)",
                             ylabel = "Distribution",
                             showLabel = FALSE) {
    nsample <- length(dataframes)
    if (nsample != length(sampleNames)) {
        stop(
            paste(
                "Expected equal number of sample names and dataframes, got",
                length(sampleNames),
                "samples and",
                nsample,
                "dataframes."
            )
        )
    }

    # pre-processing
    for (i in seq_len(nsample)) {
        df <- dataframes[[i]]
        df$sample <- sampleNames[i]
        df$percent <- df$count / sum(df$count)
        dataframes[[i]] <- df
    }

    # merge
    df.union <- do.call("rbind", dataframes)

    # title logic
    # if reion is not missing, it's a spectratype for FR/CDRs
    # else, it's a 'general' spectratype plot.
    # Can be reused for other length distributions E.G.: whole seq length
    subtitle <-
        paste(subtitle, paste(unlist(lapply(dataframes, function(x) {
            sum(x$count)
        })), collapse = ", "), "sequences with")
    if (!missing(region)) {
        plotTitle <- paste(region, "amino acid spectratype")
        plotSubTitle <- paste(
            subtitle ,
            "distribution of",
            region,
            "amino acid lengths",
            min(df.union$length),
            "to",
            max(df.union$length)
        )
    } else {
        plotTitle <- title
        plotSubTitle <-
            paste(subtitle,
                  "lengths",
                  min(df.union$length),
                  "to",
                  max(df.union$length))
    }
    # Always name your sample(s)!
    plotTitle <-
        paste(plotTitle, "in", paste(sampleNames, collapse = ", "))

    g <- ggplot(df.union, aes(length, percent))

    if (nsample == 1) {
        g <- g + geom_bar(
            stat = "identity",
            show.legend = FALSE,
            fill = BLUEHEX
        )
        if (showLabel) {
            g <- g + geom_text(aes(label = count),
                               vjust = -1,
                               size = 3)
        }
    } else {
        g <- g + geom_bar(stat = "identity",
                          aes(fill = sample),
                          position = "dodge")
    }
    g <- g + labs(
        title = plotTitle,
        subtitle = plotSubTitle,
        x = xlabel,
        y = ylabel
    )
    #geom_smooth(aes(colour=round), se=F,
    # method="glm", formula=y~ns(x, 3), lwd=0.7)+
    #geom_text_repel(aes(label = count), size = 3) +
    #geom_text(aes(label = count), vjust=-1, size = 3) +
    return(g)
}


#' Creates a box plot
#'
#' @import ggplot2
#'
#' @param dataframes list type. List of sample dataframes
#' @param sampleNames vector type. 1-1 with dataframes
#' @param plotTitle string type
#' @param xlabel string type
#' @param ylabel string type
#' @param subs string type
#'
#' @return ggplot2 object
.boxPlot <- function(dataframes,
                     sampleNames,
                     plotTitle,
                     xlabel = "",
                     ylabel = "",
                     subs = "") {
    frames <- length(dataframes)

    if (length(sampleNames) != frames) {
        stop(
            paste(
                "Expected equal number of sample names and dataframes, got",
                length(sampleNames),
                "samples and",
                frames,
                "dataframes."
            )
        )
    }

    # add samplename into new "sample" column
    dataframes <- Map(cbind, dataframes, sample = sampleNames)

    # merge
    df.union <- do.call("rbind", dataframes)

    if (frames == 1) {
        g <- ggplot(df.union,
                    aes(x = x, y = y)) +
            geom_boxplot(varwidth = TRUE, fill = BLUEHEX)
    } else {
        g <- ggplot(df.union, aes(x = sample, y = y)) +
            geom_boxplot(varwidth = TRUE, fill = BLUEHEX) +
            facet_grid( ~ x) +
            theme(axis.text.x = element_text(angle = 75, hjust = 1))
    }
    g <-
        g + labs(
            title = plotTitle,
            sutitle = subs,
            x = xlabel,
            y = ylabel
        )
    return(g)
}
