# CREATE LINEAR LINE
regX <- c(0, 0.005, 0.015, 0.025, 0.035, 0.045)
regY <- c(0, 0.005, 0.015, 0.025, 0.035, 0.045)
regDF <- data.frame(regX, regY)

# IMPORT DATA
setwd('/Users/mad/Desktop/Horse/Results/RESULTS')
library(ggplot2)
library(ggpmisc)
results <- read.table('resultsFile.txt', header = TRUE, sep = "\t", dec = ".", row.names = NULL)
colnames(results) <- c("s.generated", "s.infered", "s.var", "low.CI", "high.CI",
                       "NA", "maxLNL", "s.LNL", "h", "Ne", "sample", "rep.id")
results$s.generated <- as.numeric(results$s.generated)

# CALCULATE CONFIDENCE
results$confidence <- results$high.CI - results$low.CI
precision <- round(mean(results$confidence), digits = 4)

# PLOT ACCURACY
ggplot(data = results, aes(x=results$s.generated, y=results$s.infered)) +
  geom_pointrange(aes(ymin=results$low.CI, ymax=results$high.CI), position=position_jitter(width=0.0005)) +
  geom_line(aes(regX, regY, colour="red"), regDF) +
  stat_smooth(method="lm", se=FALSE, formula=y~x-1, colour="grey", size=0.5, fullrange = TRUE) +
  stat_poly_eq(formula = y~x-1,aes(label=paste(..eq.label.., ..rr.label.., sep="\n")), parse=TRUE, size = 5) +
  geom_text(x=0.041, y=0.40, label=paste("CI =", precision,
                                       "\n var =", round(mean(results$s.var), digits=4))) +
  theme_bw() +
  labs(x="selection coefficient generated", y="selection coefficient inferred") +
  #ylim(-0.4, 0.5) + #adjust scale size
  ggtitle("20 time series; Ne=55,000") +
  theme(plot.title = element_text(size=14, face="bold", hjust = 0.5))







