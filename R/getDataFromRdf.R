#' Aggregate the slot data.
#' 
#' \code{processSlots} gets slot data from a rdf list and aggregates it as specified.
#' 
#' @param slotsAnnualize A string vector with three entries.  \code{slotsAnnualize[1]} is the
#' slot to process. \code{slotsAnnualize[2]} is the aggregation method to use. 
#' \code{slotsAnnualize[3]} is the threshold or scaling factor to use. \code{slotsAnnualize[4]}
#' is the variable name to use. If \code{slotsAnnualize[4]} is \code{NA}, then the variable
#' name is constructed as \code{slotsAnnualize[1]}_\code{slotsAnnualize[2]}_\code{slotsAnnualize[3]}.
#' @param rdf The rdf list returned by \code{\link{read.rdf}} to get the slot data from.  
#' @param rdfName String of the rdf name.
#' @return A data frame table with the aggregated slot data.
#' @keywords internal
processSlots <- function(slotsAnnualize, rdf, rdfName)
{
	ann <- slotsAnnualize[2]
	thresh <- as.numeric(slotsAnnualize[3])
	thresh[is.na(thresh)] = 1 # can use thresh as a scale also.  If it is not specified,
	# then multiply by 1.
	slot <- slotsAnnualize[1]

	if(!(slot %in% getSlotsInRdf(rdf))){
		stop(paste("slot:", slot, "not found in rdf:", rdfName))
	}
	slot <- rdfSlotToMatrix(rdf, slot)
	
	startData <- strsplit(rdf$runs[[1]]$start, '-')[[1]] # start year
	endData <- strsplit(rdf$runs[[1]]$end, '-')[[1]] # end year

	yy <- seq(as.numeric(startData[1]), as.numeric(endData[1]), 1)
	
	tsUnit <- rdf$runs[[1]]$time_step_unit # should either be 'year' or 'month'
	if(!(tsUnit %in% c('month','year'))){
	  stop(paste('rdf:', rdfName,'contains data that is on a timestep other than year or month.\n',
	             'Currently, RWDataPlot can only handle monthly and annual rdf data.'))
	}
	
	if(tsUnit == 'year' & ann != 'AnnualRaw'){
	  # data is annual, so none of the aggregation methods besides annualRaw make sense
	  warning(paste('rdf contains annual data, but the aggregation method is not "AnnualRaw".\n',
	                'Processing using "AnnualRaw" instead. Edit the slotAggList and call getDataForAllScens again, if necessary. '))
	  ann = 'AnnualRaw'
	}
	
	# XXX
	# Need to add other summerization methods to this area
	# XXX
	# now summarize in some way
	if(ann == 'AnnMin'){
		slot <- apply(slot, 2, returnMinAnn) # minimum annual value
		rownames(slot) <- yy
	} else if(ann == 'EOWY'){
	  slot <- slot[seq(9, nrow(slot), 12),,drop = FALSE] # 9 is september
	  slot[is.nan(slot)] <- 0
	  slot <- slot * thresh
	  rownames(slot) <- yy
	} else if(ann == 'EOCY'){
	  slot <- slot[seq(12, nrow(slot), 12),,drop = FALSE] 
		slot[is.nan(slot)] <- 0
		slot <- slot * thresh
		rownames(slot) <- yy
	} else if(ann == 'BOCY'){
	  slot <- slot[seq(1, nrow(slot), 12),,drop = FALSE] 
	  slot[is.nan(slot)] <- 0
	  slot <- slot * thresh
	  rownames(slot) <- yy
	} else if(ann == 'AnnMax'){
		slot <- apply(slot, 2, returnMaxAnn) # maximum annual value
		slot <- slot * thresh
		rownames(slot) <- yy
	} else if(ann == 'AnnualSum'){
		slot <- sumMonth2Annual(slot,thresh)
		rownames(slot) <- yy
	} else if(ann == 'AnnMinLTE'){
		slot <- apply(slot, 2, returnMinAnn) # minimum annual value
		slot[slot <= thresh] <- 1
		slot[slot > thresh] <- 0
		slot <- slot * 100
		rownames(slot) <- yy
	} else if(ann == 'Monthly'){
		# XXX
		# need to update to use time series from zoo library
		yy <- matrix(t(matrix(rep(yy, 12),ncol = 12, byrow = F)), ncol = 1, byrow = F)
		rownames(slot) <- paste(rep(month.abb, nrow(slot)/12),yy,sep = '-')
		slot <- slot*thresh
	} else if(ann == 'WYMinLTE'){
		slot <- rbind(slot[1,],slot[1,],slot[1,],slot)
		slot <- slot[1:(nrow(slot)-3),]
		slot <- apply(slot, 2, returnMinAnn) # minimum annual value
		slot[slot <= thresh] <- 1
		slot[slot > thresh] <- 0
		slot <- slot * 100
		rownames(slot) <- yy
	} else if(ann == 'EOCYLTE'){
		slot <- slot[seq(12, nrow(slot), 12),,drop = FALSE]
		slot[is.nan(slot)] <- 0
		slot[slot <= thresh] <- 1
		slot[slot > thresh] <- 0
		slot <- slot*100
		rownames(slot) <- yy
	} else if(ann == 'EOCYGTE'){
		slot <- slot[seq(12, nrow(slot), 12),, drop = FALSE]
		slot[is.nan(slot)] <- 0
		slot[slot < thresh] <- 0
		slot[slot >= thresh] <- 1 
		slot <- slot*100
		rownames(slot) <- yy
	} else if(ann == 'AnnualRaw'){
		if(tsUnit == 'month'){
		  # data is monthly, so will use EOCY
		  warning(paste('User specified aggregation is "AnnualRaw", but the rdf contains monthly data.\n',
		          'Will use EOCY aggregation instead. If other aggregation method is desired, please\n',
		          'edit the slot agg list and call getDataForAllScens again.'))
		  slot <- slot[seq(12, nrow(slot), 12),] 
		  slot[is.nan(slot)] <- 0
		  slot <- slot * thresh
		  rownames(slot) <- yy
		} else{
	    # data is annual
		  rownames(slot) <- yy
		  slot <- slot*thresh
		}
	} else{
		stop('Invalid aggregation method variable')
	}
	
	
	colnames(slot) <- 1:ncol(slot)
	
	if(ann != 'Monthly'){
		slot <- reshape2::melt(slot, value.name = 'Value', varnames = c('Year','Trace'))
		slot <- cbind(slot, rep(ifelse(is.na(slotsAnnualize[4]),paste(slotsAnnualize[1],ann,thresh,sep = '_'),
                                   slotsAnnualize[4]),nrow(slot)))
		colnames(slot)[ncol(slot)] <- 'Variable'
		slot <- subset(slot,select = c(Trace, Year, Variable, Value))
	} else{
		slot <- reshape2::melt(slot, value.name = 'Value', varnames = c('Month','Trace'))
		mm <- simplify2array(strsplit(as.character(slot$Month), '-'))
		slot$Month <- mm[1,]
		slot$Variable <- rep(ifelse(is.na(slotsAnnualize[4]),paste(slotsAnnualize[1],ann,thresh,sep = '_'),
                            slotsAnnualize[4]),nrow(slot))
		slot$Year <- mm[2,]
		#colnames(slot)[(ncol(slot)-1):ncol(slot)] <- c('Variable','Year')
		slot <- subset(slot,select = c(Trace, Month, Year, Variable, Value))
	}
	slot
}

#' Get and aggregate data from a single rdf file.
#' 
#' \code{getSlots} gets all of the slots contained in a single rdf file and aggregates them
#' as specified by the summary functions in \code{slotAggList}. 

#' @param slotAggList The slot aggregation list. A list containing the slots that will be 
#' imported and aggregated, the aggregation method(s) to use, and the rdf files that 
#' contain the slots. See \code{\link{createSlotAggList}}.
#' @param scenPath A relative or absolute path to the scenario folder.
#' @keywords internal
 
getSlots <- function(slotAggList, scenPath)
{
  rdf <- slotAggList$rdf
  rdf <- read.rdf2(paste(scenPath,'/',rdf,sep = ''))
  
  if(slotAggList$slots[1] == 'all'){
	  # if slots is all, then need to create the slotAggList from createSlotAggList
	  # after reading in all the slot names
    slots <- RWDataPlot::getSlotsInRdf(rdf)
    nSlots <- length(slots)
    if(rdf$runs[[1]]$time_step_unit == 'month'){
      aggMeth <- 'Monthly'
    } else if (rdf$runs[[1]]$time_step_unit == 'year'){
      aggMeth <- 'AnnualRaw'
    } else{
      stop(paste('The', slotAggList$rdf, 'contains data of an unexpected timestep.'))
    }
    
    slotAggList <- RWDataPlot::createSlotAggList(cbind(rep(slotAggList$rdf,nSlots),
                                                       slots,
                                                       rep(aggMeth, nSlots),
                                                       rep(NA,nSlots)))
    slotAggList <- slotAggList[[1]] # go in one level into the list as that is what happens when
    # this function is called if using the normal slotAggList structure
	}
  
  slotsAnnualize <- rbind(slotAggList$slots, slotAggList$annualize, slotAggList$varNames)

	allSlots <- apply(slotsAnnualize, 2, processSlots, rdf, slotAggList$rdf)
	allSlots <- do.call(rbind, lapply(allSlots, function(X) X))
	allSlots
}

#' Get and aggregate data from rdf file(s) for one scenario.
#' 
#' \code{getAndProcessAllSlots} gets data for a single scenario.  The slots from each
#' rdf are processed and aggregated together.
#' 
#' @param scenPath A relative or absolute path to the scenario folder.
#' @inheritParams getDataForAllScens
#' @seealso \code{\link{getDataForAllScens}}
#' @keywords internal
#' 
getAndProcessAllSlots <- function(scenPath, slotAggList)
{
	sPath <- scenPath[1]
	sName <- scenPath[2]
	zz <- lapply(slotAggList, getSlots, sPath)

	allRes <- do.call(rbind, lapply(zz, function(X) X))
	nn = colnames(allRes)

	allRes$Scenario <- rep(sName, nrow(allRes))
	allRes <- subset(allRes, select=c('Scenario', nn))
	
	allRes
}

#' Get data from an rdf file(s) for multiple scenarios and save it as a data table.
#' 
#' \code{getDataForAllScens} gets slot data from multiple rdf files and for multiple scenarios.
#' The slot data can be aggregated in multiple ways (see \code{\link{createSlotAggList}}). Slot data is then converted to a molten data frame using \code{reshaphe2::melt}
#' and saved as a txt file for later use.
#' 
#' @param scenFolders A string vector containing the folder names (scenarios) that the rdf files
#' are saved in.
#' @param scenNames A string vector containing the scenario names.  This should be the same length
#' as \code{scenFolders}. The scenario names are used as attributes to the data in the "Scenario"
#' column.
#' @param slotAggList The slot aggregation list. A list containing the slots that will be 
#' imported and aggregated, the aggregation method(s) to use, and the rdf files that 
#' contain the slots. Either created by calling \code{\link{createSlotAggList}} with a specified
#' set of slots, or a list of lists with each entry containing an rdf file and the keyword 
#' 'all' for the slots, e.g., \code{list(list(rdf = 'KeySlots.rdf',slots = 'all'))}, which will
#' return all of the slots found in an rdf file. If this option is used, the code will return
#' monthly, or annual data, i.e., no aggregation methods will be applied to the data in the rdf
#' file. 
#' @param scenPath An absolute or relative path to the folder containing \code{scenFolders}.
#' @param oFile An absolute or relative path with the file name of the location the table will
#' be saved to. Valid file types are .csv, .txt, or .feather. 
#' @param retFile If \code{TRUE}, the data frame will be saved to \code{oFile} and returned. 
#' If \code{FALSE}, the data frame will only be saved to \code{oFile}.
#' @return If \code{retFile} is \code{TRUE}, a dataframe, otherwise nothing is returned.
#' 
#' @examples 
#' # get a specified set of slots and apply some aggregation method to them
#' scenFolders <- c('DNF,CT,IG', 'DNF,CT,IG,Ops1') # get the data from two scenarios
#' scenNames <- scenFolders
#' # slotAggTable.csv lists the slots to obtain, and the aggregation method to apply to them
#' slotAggList <- createSlotAggList(system.file('extdata','SlotAggTable.csv',package = 'RWDataPlot'))
#' scenPath <- system.file('extdata','Scenario/',package = 'RWDataPlot')
#' oFile <- 'tmp.feather'
#' retFile <- TRUE # return the data, instead of only save it as a text file
#' keyData <- getDataForAllScens(scenFolders, scenNames, slotAggList, scenPath, oFile, retFile)
#' 
#' # get all of the data from the KeySlots rdf file
#' scenFolders <- scenNames <- scenNames[1] # only one scenario
#' slotAggList <- list(list(rdf = 'KeySlots.rdf', slots = 'all'))
#' # will return monthly data for all slots in KeySlots.rdf
#' allData <- getDataForAllScens(scenFolders, scenNames, slotAggList, scenPath, oFile, retFile)
#' 
#' @seealso \code{\link{createSlotAggList}}
#' 
#' @export
#' 
getDataForAllScens <- function(scenFolders, scenNames, slotAggList, scenPath, oFile, retFile = FALSE)
{
  # determine file type to save data as:
  oFile <- gsub('\\', '/', oFile, fixed = TRUE)
  fName <- utils::tail(strsplit(oFile,'/', fixed = T)[[1]],1)
  fExt <- utils::tail(strsplit(fName,'.', fixed = TRUE)[[1]],1)
  if(!(fExt %in% c('txt', 'csv', 'feather'))){
    stop(paste0('oFile has an invalid file exention.\n',
                'getDataForAllScens does not know how to handle ".', fExt,
                '" extensions.'))
  }
  
	scenPath = paste(scenPath,'/',scenFolders,sep = '')
	scen = cbind(scenPath, scenNames)
	zz = apply(scen, 1, getAndProcessAllSlots, slotAggList)
	zz <- do.call(rbind, lapply(zz, function(X) X))
	
	
	if(fExt == 'txt'){
	  utils::write.table(as.matrix(zz), oFile, row.names = F, sep = '\t')
	} else if(fExt == 'csv'){
	  utils::write.csv(as.matrix(zz), oFile, row.names = F)
	} else if(fExt == 'feather'){
	  feather::write_feather(zz, oFile)
	}
	
	if(retFile){
	  zz
	}
}

