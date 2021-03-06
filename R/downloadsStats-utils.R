# downloadsStats-utils.R
#  -- M.Ponce




#################################################################################################
##	Main file for the Visualize.CRAN.Downloads package
#
#################################################################################################


### check number of records in packages
checkEntries <- function(pckg.tgt, pckg=NULL, t0,t1) {

	qualifier <- NULL

	if (!is.null(pckg)) {
		nbrEntries <- sum(pckg$count)
	} else {
		nbrEntries <- 0
	}

	if (nbrEntries == 0) {
		qualifier <- "NO data"
	} else if (nbrEntries < 5) {
		qualifier <- paste("very few entries (",nbrEntries,")")
	} else if (nbrEntries < 10) {
		qualifier <- paste("few entries (",nbrEntries,")")
	}

	if (!is.null(qualifier)) {
		msg <- paste("Package *",pckg.tgt,"* yields ",qualifier," in CRAN logs during the specified period of time (",t0,"...",t1,").")
		warning(msg)
	}
}


### retrieve package data
retrievePckgData <- function(pckg=NULL, t0=lastyear.date(), t1=today()){
#' function to download the data from the CRAN logs for an specific package
#' @param  pckg  is the name of the package to look for the downloads data
#' @param  t0  is the initial date
#' @param  t1  is the final date
#' @return a list composed of the stats from the original time frame and the last month
#'
#' @importFrom cranlogs  cran_downloads
#' @export
#'
#' @examples
#' \donttest{
#' retrievePckgData("ehelp")
#' retrievePckgData("ehelp","2018-01-01","2020-01-01")
#' }


	## function for error handling
	errorHandling.Msg <- function(condition,pkg) {
		message("A problem was detected when trying to retrieve the data for the package: ",pkg)
		if (grepl("curl",condition)) {
			message("It is possible that your internet connection is down! Please check!")
		} else {
                        message("It is possible that you misspeled the name of this package! Please check!")
		}
		message(condition,'\n')

		# update problems counter
		#pkg.env$problems <- pkg.env$problems + 1
	}

	###############################



	# to access the logs from CRAN
	loadLibrary("cranlogs")

	# check package name
	if (is.null(pckg)) stop("Need a valid package name to process!")

	# check dates
	dates <- checkDates(t0,t1)
	t0 <- dates[[1]]
	t1 <- dates[[2]]

	# Attempt to protect against bad internet conenction or misspelled package name
	tryCatch(
		{
	# retrieve data
	# TOTAL
	pckg.stats.total <- cran_downloads(pckg, from=t0, to=t1)

	# Last Month
	#pckg.stats.lstmnt <- cran_downloads(pckg, when='last-month')

	# check whether there is indeed available data, ie. an indirect indication of misspelling a package's name 
	nbrEntries <- sum(pckg.stats.total$count)
	checkEntries(pckg, pckg.stats.total, t0,t1)
	if (nbrEntries == 0) return(NULL)


	# identify first not null entry in the set...
	i0t <- which(pckg.stats.total$count>0, arr.ind=TRUE)[1]
	#print(i0t)
	#print(pckg.stats.total)
	if (i0t <= 5) i0t <- 1
	#i0m <- which(pckg.stats.lstmnt$count>0, arr.ind=TRUE)[1]
	#if (i0m <= 5) i0m <- 1

	#return(list(pckg.stats.total[i0t:length(pckg.stats.total$count),],pckg.stats.lstmnt[i0m:length(pckg.stats.lstmnt$count),]))
	return(list(pckg.stats.total[i0t:length(pckg.stats.total$count),]))

		},

		# warning
		warning = function(cond) {
				errorHandling.Msg(cond,pckg)
			},
		# error
		error = function(e){
				errorHandling.Msg(e,pckg)
			}
	)

}


### main wrapper fn
processPckg <- function(pckg.lst, t0=lastyear.date(), t1=today(), opts=list(), device="PDF",dirSave=NULL) {
#' main function to analyze a list of packages in a given time frame
#' @param  pckg.lst  list of packages to process
#' @param  t0  initial date, begining of the time period given in "YYYY-MM-DD" format
#' @param  t1  final date, ending of the time period given in "YYYY-MM-DD" format
#' @param  opts  a list of different options available for customizing the output 
#' @param  device  string to select the output format: 'PDF'/'PNG'/'JPEG' or 'screen'
#' @param  dirSave  name of a valid directory where to save the file, eg. do not specify this argument or enter "." for using the current working directory
#'
#' @export
#'
#' @examples
#' \donttest{
#' # device is set to "screen" so no files are generated and plots will appear on "screen"
#' # alternative to 'device' are "PDF"/"PNG"/"JPEG"
#' processPckg("ehelp", device="screen")
#' processPckg(c("ehelp","plotly","ggplot2"), "2001-01-01", device="screen")
#' processPckg(c("ehelp","plotly","ggplot2"), "2001-01-01", opts="nostatic", device="screen")
#' processPckg(c("ehelp","plotly","ggplot2"), "2001-01-01",
#'		opts=c("nostatic","nocombined","nointeractive"), device="screen")
#' }
#'
	# verify options...
	checkOpts <- function(opts,validOpts){
	# function to check arguments
	# @param  opts  list of options
	# @param  validOpts  list of valid options
	#
	# @keywords internal
	# flag to identify invalid arguments...
		invalid <- FALSE

		# check every argument
		for (opt in tolower(opts)) {
			if (!(opt %in% validOpts)) {
				message('"',opt,'"', " not recognized among valid options for the function, it will be ignored")
				invalid <- TRUE
			}
		}

		# check whether is necessary to remind the user about the possible options for the arguments
		if (invalid) message("Valid options are: ", '"',paste(validOpts,collapse='" "'),'"')
	}


	# check dates
	dates <- checkDates(t0,t1)
	t0 <- dates[[1]]
	t1 <- dates[[2]]

	# check options...
	validOpts <- tolower(c("nostatic","nointeractive", "nocombined", "noMovAvg","noConfBand", "noSummary", "compare"))
	checkOpts(opts,validOpts)


	# initialize lists for storaging info
	pckgDwnlds.lst <- list()
	pckg.stats.lstmnt <- list()


	for (pckg in pckg.lst) {
		# retrieve data
		pckgDwnlds <- retrievePckgData(pckg,t0,t1)

		# get the total data
		pckg.stats.total <- pckgDwnlds[[1]]

		# Last Month data
		#pckg.stats.lstmnt <- pckgDwnlds[[2]]

		# check whether there is indeed available data, ie. an indirect indication of misspelling a package's name
		if ( is.null(pckgDwnlds) || (sum(pckg.stats.total$count) == 0) ) {
			warning("Package *",pckg,"* yields no data in CRAN logs during the specified period of time (",t0,"...",t1,"); check that you have specified the correct name for the package.")
		} else {
			### Plots
			# set defaults
			cmb <- TRUE; noCBs <- FALSE; noMAvgs <- FALSE

			## static plots
			if ('nostatic' %in% tolower(opts)) {
				message("Will skip static plots...")
			} else {
				# alternate default values, depending on options provided by the user
				if ('nocombined' %in% tolower(opts))  cmb <- FALSE
				if ('noconfband' %in% tolower(opts))  noCBs <- TRUE
				if ('nomovavg' %in% tolower(opts))  noMAvgs <- TRUE

				staticPlots(pckg.stats.total, combinePlts=cmb, noMovAvg=noMAvgs, noConfBands=noCBs, device=device,dirSave=dirSave)
			}

			### interactive plots
			if ( "nointeractive" %in% tolower(opts) ) {
				message("will skip interactive plots...")
			} else {
				interactivePlots(pckg.stats.total,dirSave=dirSave,device=device)
			}

			### comparison between several packages
			if ( "compare" %in% tolower(opts) ) {
				if (length(pckg.lst) <= 1)
					warning("The 'compare' option is available when more than 1 package is indicated!")
				pckgDwnlds.lst <- c(pckgDwnlds.lst,pckgDwnlds)
			}

			# summaries
			#summaries(pckg.stats.total,pckg.stats.lstmnt)
			if (!("nosummary" %in% tolower(opts)) )  summaries(pckg.stats.total)
		}
	}

	if ( "compare" %in% tolower(opts) ) {
		comparison.Plt(pckgDwnlds.lst, t0,t1, cmb,noMAvgs,noCBs,device=device,dirSave=dirSave)
		return(invisible(pckgDwnlds.lst))
	}
}




# summaries
summaries <- function(data1, deltaTs=30) {
#' function to display the summary of the data
#' @param  data1  first dataset, eg. total data
#' @param  deltaTs  a numerical (integer) value, indicating the lenght --in days-- for selecting a subset of the original dataset; default value is 1 mont, ie. 30 days
#'
#' @export
#'
#' @examples
#' \donttest{
#' packageXdownloads <- retrievePckgData("ehelp")[[1]]
#' summaries(packageXdownloads)
#' }
#'
	printSummary <- function(data, time.orig="",hdr="--- \n") {


		# some descriptive statistics first,
		# ie. min, max, mean, median, ...

		cat("Stats from ",time.orig, paste0("(",length(data$date)-2," days)"), '\n')
        	cat(paste("period: ",data$date[1],' - ',data$date[length(data$date)]),'\n')
        	cat(hdr)

        	#print(summary(data))
		print(summary(data$count))
		cat('\n')
        	
		indicators <- c("Min.","Median","Mean","Max.")
        	selectedIndicators <- c("Min.","Max.")
        	sum1 <- summary(data$count)

		for (ind in indicators) {
			if (ind %in% selectedIndicators) {
				info <- paste('  ',paste(ind, sum1[ind], "__", data$date[which(data$count == sum1[ind])]),'\n')
			} else {
				info <- paste('  ',paste(ind, round(sum1[ind],2)),'\n')
			}
			cat(info)
		}
	}



	# define some headers and line-breaks...
	hdr <- paste(paste(rep("#",70),collapse=''), '\n')
	hdr2 <- paste(paste(rep("-",35),collapse=''), '\n')
	hdr3 <-  paste(paste(rep("~",60),collapse=''), '\n')

	# display info about the package...
	cat('\n'); cat(hdr)
	line1 <- paste("Processing Package",data1$package[1])
	len.line1 <- nchar(line1)
	p.line1 <- paste(paste(rep("#",(70-len.line1-2)/2),collapse=''))
	cat(p.line1,line1,p.line1,'\n')
	cat(hdr)

	printSummary(data1,"original selected period",hdr2)
	cat(hdr3)

	tot.days <- length(data1$date)

	deltaTs <- time.units(tot.days)
	#print(deltaTs)
	deltas.units <- c("day","week","month","trimester","semester","year","2 years","5 years")

        for (deltaT.ind in seq_along(deltaTs)) {
		deltaT <- deltaTs[deltaT.ind]
		#print(deltaT)
		if (deltaT > 1) {
			cat(hdr2)
			#cat("Stats from last",deltas.units[deltaT.ind], paste0("(",deltaT," days)"), '\n')
			emph.range <- (tot.days-(deltaT+1)):(tot.days)
			#print(emph.range)
			data2 <- data1[emph.range,]

			printSummary(data2,paste("last",deltas.units[deltaT.ind]),hdr2)
		}
	}

	# final line...
	cat(hdr)
	cat('\n\n\n')
}

