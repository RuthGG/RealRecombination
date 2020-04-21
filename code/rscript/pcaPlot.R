#!/usr/bin/env Rscript
# Ruth Gómez Graciani
# 18 04 2020

###############################################################################
# Description:                                                                
# Create plots for PCA analysis                                      
###############################################################################

# LOAD ARGUMENTS 
# =========================================================================== #
args = commandArgs(trailingOnly=TRUE)

  # Test if there is at least one argument: if not, return an error
  if (length(args)<3) {
    stop("One input file, one population file for the references and one output file must be provided.", call.=FALSE)
  } 

# Example
# args[1]<-"analysis/2020-04-18_04_runPca/pcaResult.Rdata"
# args[2]<-"data/raw/1000genomes_hg19/integrated_call_samples_v3.20130502.ALL.panel"
# args[3]<-"tmp/"

# LOAD PACKAGES
# =========================================================================== #

  # First specify the packages of interest
  packages = c("ggplot2", "ggrepel", "cowplot")

  # Now load or install&load all
  lapply(packages,FUN = function(x) {
    if (!require(x, character.only = TRUE)) {
      install.packages(x, dependencies = TRUE)
      library(x, character.only = TRUE)
    }
  })

# MAKE FUNCTION
# It will take PC1, PC2 and PC3 in all their cominations.
# =========================================================================== #
  
make_plot<-function(pca, pop){
  
  # Transform to data frame
  out <- as.data.frame(t(pca), stringsAsFactors = FALSE)

  # Get clean column names
  tmpnames<-data.table::transpose(strsplit(colnames(out), "_"))
  colnames(out)<-tmpnames[[length(tmpnames)]]
  
  # Make full populations table
  
    # Identify new individuals
      new<-rownames(out)[! (rownames(out) %in% rownames(pop))]
    # Make generic populations table content for new individuals
      content<-matrix(rep(c("Unknown", "Unknown", "male"), length(new)), byrow = TRUE, ncol = 3)
    # Name generic content table
      rownames(content)<-new
      colnames(content)<-colnames(pop)
    # Join to populations table 
      populations<-rbind(pop, content)
  
  # Add population info to table
  out$Metapopulation<-populations[rownames(out),"super_pop"]
  
  # Make subset with new individuals, which are unknown 
  incognita<-out[out$Metapopulation == "Unknown",]
  incognita$individual<-rownames(incognita)
  
  # This step is specific for Avery data, can be removed for other datasets as needed!
  incognita$individual<-matrix(unlist(strsplit(incognita$individual, "[.]")), ncol=2, byrow = TRUE)[,2]
   
    # Plot PC1 vs PC2
  set1<-ggplot(out)+geom_point(aes(x = PC1, y = PC2, color = Metapopulation), alpha = 0.5, size = 2.5)+ 
    geom_text_repel(data=incognita,
                    aes(x = PC1,y = PC2,label=individual)) 
   # Plot PC1 vs PC3
  set2<-ggplot(out)+geom_point(aes(x = PC1, y = PC3, color = Metapopulation), alpha = 0.5, size = 2.5)+  
    geom_text_repel(data=incognita,
                    aes(x = PC1,y = PC3,label=individual))
  
  # Plot PC2 vs PC3
  set3<-ggplot(out)+geom_point(aes(x = PC2, y = PC3, color = Metapopulation), alpha = 0.5, size = 2.5)+ 
    geom_text_repel(data=incognita,
                    aes(x = PC2,y = PC3,label=individual))+theme_grey()
  
  
  # Return plots
  return(list(set1, set2, set3))
}

# LOAD DATA
# =========================================================================== #

  load(args[1]) # pca
  pop<-read.table(args[2], row.names = 1, stringsAsFactors = FALSE, header = TRUE)

# SET AESTHETICS
# =========================================================================== #

  theme_ed <- theme(
    legend.position = "bottom",
    panel.background = element_rect(fill = NA),
    panel.border = element_rect(fill = NA, color = "grey75"),
    axis.ticks = element_line(color = "grey85"),
    panel.grid.major = element_line(color = "grey80", size = 0.2, linetype = "longdash"),
    panel.grid.minor = element_line(color = "grey80", size = 0.2, linetype = "longdash"),
    legend.key = element_blank())

  colors<-scale_color_manual(values=c("#8a89e8","#64addf","#67cd9f","#7ed44d","#c0c45c","#d59145"))
  
# MAKE PLOT
# =========================================================================== #

  # Make plots
  plots<-make_plot(pca, pop)

  # Save legend
  legend <- cowplot::get_legend(plots[[1]]+colors+ guides(shape = guide_legend(override.aes = list(size = 5))))
  
  # Make plot grid
  prow <- plot_grid(
    plots[[1]] + theme_ed + theme(legend.position="none") +colors,
    plots[[2]] + theme_ed + theme(legend.position="none")+colors,
    plots[[3]] + theme_ed + theme(legend.position="none")+colors,
    align = 'vh',
    labels = c("A", "B", "C"),
    hjust = -1,
    nrow = 2
  )

  # Now add in the legend
  plot_row<-  prow + draw_grob(legend, 1/4, -1/4, 1, 1)
  
  # Create title
  title <- ggdraw() + 
    draw_label(
      "PCA analysis using 1K Genomes as reference",
      x = 0.01,
      hjust = 0
    ) +   theme( plot.margin = margin(0, 0, 0, 7)
    )

  # Final product
  final_plot<-plot_grid(
    title, plot_row,
    ncol = 1,
    # rel_heights values control vertical title margins
    rel_heights = c(1/20, 1)
  )

# SAVE PLOT
# =========================================================================== #

  png(paste0(args[3], "/PCAplot.png"), width = 25 , height = 25 , units = "cm", res = 300)
  
  final_plot

  dev.off()
  