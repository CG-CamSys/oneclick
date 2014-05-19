/*
 * global function to implement a delay timer
 * only execute callback when the final event is detected
 */
var waitForFinalEvent = (function () {
  var timers = {};
  return function (callback, ms, uniqueId) {
    if (!uniqueId) {
      uniqueId = "Don't call this twice without a uniqueId";
    }
    if (timers[uniqueId]) {
      clearTimeout (timers[uniqueId]);
    }
    timers[uniqueId] = setTimeout(callback, ms);
  };
})();

$(function () {
	var tripContainerId = 'tripContainer'; //id of trip container Div
	var legendContainerId = "legendContainer"; //id of legend container div
	var filterContainerId = "filterContainer"; //id of legend container div
	var modeContainerId = "modeContainer"; //id of mode filter container div
	var transferSliderId = "transferSlider"; //id of transfer filter slider
	var costSliderId = "costSlider"; //id of cost filter slider
	var durationSliderId = "durationSlider"; //id of duration filter slider
	
	var intervalStep = 30; //30min
	var barHeight = 20; //20pixel
	var tripPlanDivPrefix = "trip_plan_"; //prefix of each trip plan div
	var missInfoDivPrefix = "tripRestriction"; //prefix of each trip restriction modal dialog
	
	 //chart tooltip
	var chartTooltipDiv = d3.select("body").append("div")   
	.attr("class", "chart-tooltip")               
	.style("opacity", 0);
	
	/**
	 * Process trip results response from service
	 * @param {object} tripResponse 
	 */
	function processTripResponse(tripResponse) {
		//check if response is object
		if(typeof tripResponse != 'object') {
			return;
		}
		
		//check response status
		if(tripResponse.status === 0) {
			console.log('something went wrong');
			return;
		}
		
		var tripParts = tripResponse.trip_parts;
		//check if trip_parts is Array
		if(! tripParts instanceof Array) {
			return;
		}
		
		var resizeChartArray = [];
		//process each trip
		tripParts.forEach(function(trip) {
			var newTripChartArray = addTripHtml(trip);
			newTripChartArray.forEach(function(tripChart) {
				resizeChartArray.push(tripChart);
			});
		});
		
		//process legends
		addLegendHtml(tripParts);
		
		//process filters
		addFilterHtml(tripParts);
		
				
		//windows resize needs to update charts
		window.onresize = function(event) {
			waitForFinalEvent( function() {
				resizeChartArray.forEach(function(param) {
					resizeChart (param.id, param.startTime, param.endTime, intervalStep, barHeight);
				});
			}, 100, 'window resize');
		};
		
		//clicking Select button to change styles
		$('.single-plan-review .single-plan-select').click( function() {
			$(this).parents('.single-plan-review')
				.removeClass('single-plan-unselected')
				.addClass('single-plan-selected');
			$(this).parents('.single-plan-review').siblings()
				.removeClass('single-plan-selected')
				.addClass('single-plan-unselected');
		});
	}
	
	/**
	 * Given each trip part, render to UI
	 * @param {object} trip
	 */
	function addTripHtml(trip) {
		//check if trip is object
		if(typeof trip != 'object') {
			return;
		}
		
		var isDepartAt = trip.is_depart_at; //departing at or arriving at??
		var tripId = trip.trip_part_id;
		var tripStartTime = parseDate(trip.start_time);
		var tripEndTime = parseDate(trip.end_time);
		
		if(! tripStartTime instanceof Date || ! tripEndTime instanceof Date || tripEndTime <= tripStartTime) {
			return;
		}
		
		var tripTags = "<div class='col-xs-12 well' style='padding: 0px;'>";
		
		var tickLabels = getTickLabels(tripStartTime, tripEndTime, intervalStep);
		//process header
		var tripHeaderTags = addTripHeaderHtml(trip.description, tickLabels, intervalStep, isDepartAt);
		tripTags +=  tripHeaderTags;
		
		//process each trip plan
		var tripPlans = trip.itineraries;
		tripPlans.forEach(function(tripPlan) {
			if(typeof(tripPlan) === 'object') {
				tripTags += addTripPlanHtml(
					tripId,
					tripPlan,
					trip.start_time,
					trip.end_time,
					isDepartAt
				);
			}
		});
		
		tripTags += "</div>";
		
		//render HTML
		$('#' + tripContainerId).append(tripTags);
		
		//render Chart
		var resizeChartArray = [];

		tripPlans.forEach(function(tripPlan) {
			if(typeof(tripPlan) === 'object') {
				var tripPlanChartId = tripPlanDivPrefix + tripId + "_" + tripPlan.id;
				createChart(
					tripPlanChartId, 
					tripPlan.legs, 
					tripStartTime, 
					tripEndTime, 
					intervalStep, 
					barHeight
				);
				
				resizeChartArray.push({
					id: tripPlanChartId,
					startTime: tripStartTime,
					endTime: tripEndTime
				});
				
				addTripStrictionUpdateButtonClickListener(tripPlan.missing_information, tripId, tripPlan.id);
			}
		});
		
		return resizeChartArray;
	}
	
	/*
	 * add on-click listener for Update button in each trip restriction modal dialog
	 * @param {Object} missingInfo
	 * @param {number} t
	 */
	function addTripStrictionUpdateButtonClickListener(missingInfo, tripId, planId) {
		var isMissingInfoFound = (typeof(missingInfo) === 'object' && missingInfo.hasOwnProperty('success_condition'));
		if(!isMissingInfoFound) {
			return;
		}
		
		var tripPlanChartDivId = tripPlanDivPrefix + tripId + '_' + planId;
		var missInfoDivId = missInfoDivPrefix + tripId + '-' + planId;
		var updateButtons = $('#' + missInfoDivId + ' .btn-primary');
		
		var successCondition = missingInfo.success_condition;
		$('#' + missInfoDivId + ' .btn-primary').click(function(){
			var dialog = $('#' + missInfoDivId);
			var formVals =dialog.find('.form-inline').serializeArray();
			if(formVals.length === 0) {
				return;
			}
			
			var val = formVals[0].value;
			try {
				var tripPlanDiv = $('#' + tripPlanChartDivId).parents('.single-plan-review');
				if(eval(val + successCondition)) {
					tripPlanDiv.find('.single-plan-question').remove();
					tripPlanDiv.find('.single-plan-select').css('visibility', '');
				} else {
					tripPlanDiv.remove();
				}
				
				dialog.modal('hide');
			}
			catch(evalError) {
				console.log(evalError);
			}
		});
	}
	
	/**
	 * Render trip header
	 * @param {string} tripDescription 
	 * @param {number} intervelStep 
	 * @param {Array} tickLabels 
	 * @param {bool} isDepartAt: true if departing at, false if arriving at
	 * @param {string} tripHeaderTags: html tags of the whole trip header
	 */
	function addTripHeaderHtml(tripDescription, tickLabels,intervelStep, isDepartAt) {		
		//trip description
		var tripDescTag = '<label class="col-sm-12">' + tripDescription + '</label>';
		
		var tickLabelTags = '';
		if(tickLabels instanceof Array && tickLabels.length > 1) {
			var labelCount = tickLabels.length;
			
			var xsShowIndexArray = [0, labelCount - 1];
			var smShowIndexArray = [0, labelCount - 1];
			
			var midIndex = parseInt(labelCount/2);
			if(xsShowIndexArray.indexOf(midIndex) < 0) {
				xsShowIndexArray.push(midIndex);
			} 
			
			if(smShowIndexArray.indexOf(midIndex) < 0) {
				smShowIndexArray.push(midIndex);
			} 
			
			var isEvenCount = (labelCount % 2 === 0);
			var smBase = 2;
			while(smBase <= labelCount -1) {
				if(isEvenCount && smBase === (midIndex - 1)) {
					smBase += 1;
				}
				if(smShowIndexArray.indexOf(smBase) <= 0) {
					smShowIndexArray.push(smBase);
				}
				
				smBase += 2;
			}
			
			var labelWidthPct = 1 / (labelCount - 1) * 100 + '%';
			var labelIndex = 0;
			tickLabels.forEach(function(tickLabel){	
				var className = '';
				if(xsShowIndexArray.indexOf(labelIndex) < 0) {
					className = ' tick-label-hidden-xs';
				} 
				
				if(smShowIndexArray.indexOf(labelIndex) < 0){
					className += ' tick-label-hidden-sm';
				} 
				
				className += ' tick-label-visible-md';
				
				var marginTag = '';
				if(labelIndex === 0) {
					marginTag = 'margin: 0px 0px 0px -20px';
				} else {
					marginTag = 'margin: 0px;';
				}
				tickLabelTags +=
			 	'<span class="' + className + '" style="display:inline-block;width:' + labelWidthPct + ';border: none;text-align:left;' + marginTag + ';">' + tickLabel + '</span>';
				labelIndex ++;
			});
		}
		
		var tripHeaderTags = tripDescTag +
				"<div class='col-xs-12 single-plan-header' style='padding: 0px;'>" +
					"<div class='col-xs-2' style='padding: 0px;'>" +
						(isDepartAt ? ("<button class='btn btn-default btn-xs pull-right prev-period'> -" + intervelStep + "</button>") : "") +
					"</div>" +
					"<div class='col-xs-9 " + (isDepartAt ? "highlight-left-border" : "highlight-right-border") + "' style='padding: 0px;white-space: nowrap;'>" +
						(
							isDepartAt ? 
							("<button class='btn btn-default btn-xs pull-left next-period'> +" + intervelStep + "</button>") : 
							("<button class='btn btn-default btn-xs pull-right prev-period'> -" + intervelStep + "</button>")
						) +
					"</div>" +
					"<div class='col-xs-1 select-column' style='padding: 0px;'>" +	
						(isDepartAt ? "" : ("<button class='btn btn-default btn-xs pull-left next-period'> +" + intervelStep + "</button>")) +
					"</div>" +
					"<div class='col-xs-2' style='padding: 0px;'>" +
					"</div>" +
					"<div class='col-xs-9 " + (isDepartAt ? "highlight-left-border" : "highlight-right-border") + "' style='padding: 0px;white-space: nowrap;'>" +
					 	tickLabelTags +
					"</div>" +
					"<div class='col-xs-1 select-column' style='padding: 0px;'>" +	
					"</div>" +
				"</div>";
		return tripHeaderTags;
	}

	/**
	 * Render trip part
	 * @param {number} tripId
	 * @param {Object} tripPlan
	 * @param {string} strStartTime: trip start time
	 * @param {string} strEndTime: trip end time
	 * @param {bool} isDepartAt: true if departing at, false if arriving at
	 * @return {string} HTML tags of each trip plan
	 */
	function addTripPlanHtml(tripId, tripPlan, strStartTime, strEndTime, isDepartAt) {
		if(typeof(tripPlan)!= 'object') {
			return "";
		}
		var planId = tripPlan.id;
		var mode = tripPlan.mode;
		var modeName = tripPlan.mode_name; 
		var serviceName = tripPlan.service_name;
		var contact_information = tripPlan.contact_information; 
		var cost = tripPlan.cost;
		var missingInfo = tripPlan.missing_information; 
		var transfers = tripPlan.transfers;
		var duration = tripPlan.duration;
						
		var cssName = "trip-" + removeSpace(modeName.toLowerCase()) + "-" + removeSpace(serviceName.toLowerCase());
		var modeServiceUrl = "";
		if(typeof(contact_information) === 'object' ) {
			modeServiceUrl = contact_information.url;
		}

		//check if missing info found; if so, need to us Question button instead of Select button
		var isMissingInfoFound = (typeof(missingInfo) === 'object' && missingInfo.hasOwnProperty('success_condition'));
		var missInfoDivId = missInfoDivPrefix + tripId + "-" + planId; //id of missing info modal dialog
		
		//assign data values to each plan div
		var dataTags = 
			" data-trip-id='" + tripId + "'" +
			" data-plan-id='" + planId + "'" +
			" data-start-time='" + strStartTime + "'" +
			" data-end-time='" + strEndTime + "'" +
			" data-mode='" + mode + "'" +
			" data-transfer='" + transfers.toString() + "'" +
			" data-cost='" + (typeof(cost) === 'object' ? cost.price : '') + "'" +
			" data-duration='" + (typeof(duration) === 'object' ? duration.sortable_duration : '') + "'";
		var tripPlanTags = 
			"<div class='col-xs-12 single-plan-review single-plan-unselected' style='padding: 0px;'" + dataTags +">" +
				"<div class='col-xs-2 trip-plan-first-column' style='padding: 0px; height: 100%;'>" +
					"<table>" +
						"<tbody>" +
							"<tr>" +
								"<td class='trip-mode-icon'>" +
									"<a href='" + modeServiceUrl + "' target='_blank'" + 
										(typeof(modeServiceUrl) === 'string' && modeServiceUrl.trim().length > 0 ? "" : " onclick='return false'") + //if there is no url, then make this hyperlink inactive
										" class='" + cssName + "'>" + serviceName + " " + modeName +
									"</a>" +
								"</td>" +
								"<td class='trip-mode-cost'>" +
									"<div class='itinerary-text'>" +
										(typeof(cost) === 'object' ? "$" + cost.price : '') + 
									"</div>" +
								"</td>" +
							"</tr>" +
						"</tbody>" +
					"</table>" +
				"</div>" +
				"<div class='col-xs-9 " + 
					(isDepartAt ? "highlight-left-border regular-right-border" : "highlight-right-border regular-left-border") + 
					"' style='padding: 0px; height: 100%;' id='" + tripPlanDivPrefix + tripId + "_" + planId + "'>" +
				"</div>" +
				"<div class='col-xs-1 select-column' style='padding: 0px; height: 100%;'>" +
					(
						isMissingInfoFound ?
						(
							"<button class='btn btn-default btn-xs single-plan-question action-button' " +
							"data-toggle='modal' data-target='#" + missInfoDivId + "'>?</button>" +
							"<button class='btn btn-default btn-xs single-plan-select action-button' style='visibility: hidden;'>Select</button>"
						) :
						"<button class='btn btn-default btn-xs single-plan-select action-button'>Select</button>"
					) +
				"</div>" +
			"</div>";
		//tags for missing info div
		if(isMissingInfoFound) {
			tripPlanTags += addTripRestrictionDialogHtml(missingInfo, missInfoDivId);
		}
		
		return tripPlanTags;
	}
	
	/*
	 * generate html tags for trip restrictions dialog
	 * @param {Object} missingInfo
	 * @param {string} missInfoDivId
	 * @return {string} html tags
	 */
	function addTripRestrictionDialogHtml(missingInfo, missInfoDivId){
			if(typeof(missingInfo) != 'object' || typeof(missInfoDivId) != 'string') {
				return '';
			}
			
			var infoShortDesc = missingInfo.short_desc;
			var infoLongDesc = missingInfo.long_desc;
			var infoType = missingInfo.type;
			var successCondition = missingInfo.success_condition;
			
			var answersTags = '';
			switch(toCamelCase(infoType)) {
				case 'Radio':
					var infoOptions = missingInfo.options;
					if(infoOptions instanceof Array && infoOptions.length > 0) {
						infoOptions.forEach(function(infoOption) {
							if(typeof(infoOption) === 'object') {
								answersTags += 
								'<label class="radio-inline">' +
  									'<input type="radio" name="' + missInfoDivId + '-options" ' + 
  										'value="' + infoOption.value + '" ' +
  										(infoOption.is_default ? 'checked' : '') +
  									'>' + infoOption.text + 
  								'</label>';				
							}
						});
					}
					break;
				case 'Age':
					answersTags += '<input type="text" class="form-control" name="' + missInfoDivId + '-options" label="false"/>';
					break;
				default:
					break;
			}

			var missInfoTags = 
			'<div class="modal fade" data-backdrop="static" id="' + missInfoDivId + '" tabindex="-1" role="dialog" aria-labelledby="'+ missInfoDivId + '-title" aria-hidden="true">' +
			  '<div class="modal-dialog">' +
			    '<div class="modal-content">' +
			      '<div class="modal-header">' +
			        '<button type="button" class="close" data-dismiss="modal" aria-hidden="true">?</button>' +
			        '<b class="modal-title" id="' + missInfoDivId + '-title">Trip Restrictions</b>' +
			      '</div>' +
			      '<div class="modal-body">' +
			      	'<form class="form-inline" role="form">' +
				      	'<div class="form-group">' +
				        	'<span>' + infoShortDesc + '</span>' +
				        '</div>' +
				      	'<div class="form-group">' +
				        	'<label class="sr-only">' + infoLongDesc + '</label>' +
				        	'<label class="control-label"style="margin-right: 10px;">' + infoLongDesc + '</label>' +
				        	answersTags +
				        '</div>' +
			        '</form>' + 
			      '</div>' +
			      '<div class="modal-footer">' +
			        '<button type="button" class="btn btn-primary">Update</button>' +
			        '<button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button>' +
			      '</div>' +
			    '</div>' +
			  '</div>' +
			'</div>';
			
		return missInfoTags;	
	}
	
	/**
	 * Html of legends
	 * @param {Array} trips 
	 */
	function addLegendHtml(trips) {
		if(! trips instanceof Array) {
			return;
		}
		
		var legendTags = '';
		var legendClassNames = [];
		trips.forEach(function(trip) {
			if(typeof(trip) != 'object' || ! trip.itineraries instanceof Array) {
				return;
			}
			var tripPlans = trip.itineraries;
			tripPlans.forEach(function(tripPlan) {
				if(typeof(tripPlan) != 'object' || ! tripPlan.legs instanceof Array) {
					return;
				}
				var legs = tripPlan.legs;
				legs.forEach(function(leg) {
					if(typeof(leg) != 'object' || typeof(leg.type) != 'string') {
						return;
					}
					
					var className = "travel-legend-" + removeSpace(leg.type.toLowerCase());
					var legendText = toCamelCase(leg.type);
					
					if(!legendClassNames[className]) {
						legendClassNames[className] = legendText;
						legendTags += 
							"<div class='travel-legend-container'>" + 
							"<div class='travel-legend " + className + "'/>" +
							"<span>" + legendText + "</span>" +
							"</div>";
					}
				});
			});
		});
		
		$('#' + legendContainerId).append(legendTags);
	}
	
	/*
	 * Html of filters
	 * @param {Array} trips 
	 */
	function addFilterHtml(trips) {
		if(! trips instanceof Array) {
			return;
		}
		
		var filterTags = '';
		
		var modes = [];
		var minTransfer = -1;
		var maxTransfer = -1;
		var minCost = -1;
		var maxCost = -1;
		var minDuration = -1;
		var maxDuration = -1;
		
		trips.forEach(function(trip) {
			if(typeof(trip) != 'object' || ! trip.itineraries instanceof Array) {
				return;
			}
			var tripPlans = trip.itineraries;
			tripPlans.forEach(function(tripPlan) {
				if(typeof(tripPlan) != 'object' ) {
					return;
				}
				
				//transfers
				var transfer = parseInt(tripPlan.transfers);
				if(transfer >= 0) {
					if(minTransfer < 0 || transfer < minTransfer) {
						minTransfer = transfer;
					}
					
					if(minTransfer < 0 || transfer > maxTransfer) {
						maxTransfer = transfer;
					}
				}
				
				//cost
				var costInfo = tripPlan.cost;
				if(typeof(costInfo) === 'object') {
					var cost = parseFloat(costInfo.price);
					if(cost >= 0) {
						if(minCost < 0 || cost < minCost) {
							minCost = cost;
						}
						
						if(maxCost < 0 || cost > maxCost) {
							maxCost = cost;
						}
					}
				}
				
				//duration
				var durationInfo = tripPlan.duration;
				if(typeof(durationInfo) === 'object') {
					var duration = parseFloat(durationInfo.sortable_duration);
					if(duration >= 0) {
						if(minDuration < 0 || duration < minDuration) {
							minDuration = duration;
						}
						
						if(maxDuration < 0 || duration > maxDuration) {
							maxDuration = duration;
						}
					}
				}
				
				//modes
				if(! modes.hasOwnProperty(tripPlan.mode)){
					modes[tripPlan.mode] = toCamelCase(tripPlan.mode_name);
				}
			});
		});
		
		//insert modes filter tags
		if(modes.length > 0) {
			filterTags +=
				'<div class = "col-sm-12">' + 
					'<label class="sr-only">Modes</label>' +
					'<label class="col-sm-12">Modes</label>' +
				'</div>';
			for(var modeId in modes) {
					filterTags +=
					'<div class="col-sm-12" id="' + modeContainerId + '">' +
					'<div class="checkbox" style="margin:0px 0px 0px 10px;">' +
					  '<label>' +
					    '<input type="checkbox" checked=true value=' + modeId + '>' +
					    modes[modeId] +
					  '</label>' +
					'</div>'+
					'</div>';
			}
		}
		
		var sliderConfigs = [];
		//insert transfer fitler tags
		var transferFilter = getTransferFilterHtml(minTransfer, maxTransfer);
		if(typeof(transferFilter) === 'object') {
			filterTags += transferFilter.tags;
			sliderConfigs['transfer'] = transferFilter.sliderConfig;
		}
		//insert cost fitler tags
		var costFilter = getCostFilterHtml(minCost, maxCost);
		if(typeof(costFilter) === 'object') {
			filterTags += costFilter.tags;
			sliderConfigs['cost'] = costFilter.sliderConfig;
		}
		//insert duration fitler tags
		var durationFilter = getDurationFilterHtml(minDuration, maxDuration);
		if(typeof(durationFilter) === 'object') {
			filterTags += durationFilter.tags;
			sliderConfigs['duration'] = durationFilter.sliderConfig;
		}
		
		//render
		$('#' + filterContainerId).append(filterTags);
		
		//enable mode checkbox event
		$('#' + modeContainerId + ' .checkbox').on('change', function() {
        	waitForFinalEvent(filterPlans, 100, 'mode change');
		});
		
		//enable sliders
		for(var sliderIndex in sliderConfigs) {
			var slider = sliderConfigs[sliderIndex];
			addSliderTooltip(slider);
		}
		
	}
	
	/*
	 * create html tags for transfer filter
	 * @param {number}: minTransfer
	 * @param {number}: maxTransfer
	 */
	function getTransferFilterHtml(minTransfer, maxTransfer){
		var tags = '';
		var sliderConfig = null;
		if(typeof(maxTransfer) === 'number' && typeof(minTransfer) === 'number' && maxTransfer > minTransfer) {
			tags = 
			'<div class = "col-sm-12">' + 
				'<label class="sr-only">Number of transfers</label>' +
				'<label class="col-sm-12">Number of transfers</label>' +
			'</div>' +
			'<div class="col-sm-12">' +
				'<div id="' + transferSliderId + '">' +
				'</div>' +
			'</div>' +
			'<div class="col-sm-12" style="margin-bottom: 5px;">' + 
				'<span class="pull-left">' + minTransfer.toString() + '</span>'	+
				'<span class="pull-right">' + maxTransfer.toString() + '</span>'	+
			'</div>';	
			sliderConfig = {
				id: transferSliderId,
				values: [minTransfer, maxTransfer],
				min: minTransfer,
				max: maxTransfer,
				step: 1,
				range: true
			};
		}
		
		return {
			tags: tags,
			sliderConfig: sliderConfig
		};
	}
	
	/*
	 * create html tags for cost filter
	 * @param {number}: minCost
	 * @param {number}: maxCost
	 */
	function getCostFilterHtml(minCost, maxCost){
		var tags = '';
		var sliderConfig = null;
		if(typeof(maxCost) === 'number' && typeof(minCost) === 'number' && maxCost > minCost) {
			tags = 
			'<div class = "col-sm-12">' + 
				'<label class="sr-only">Cost</label>' +
				'<label class="col-sm-12">Cost</label>' +
			'</div>' +
			'<div class="col-sm-12">' +
				'<div id="' + costSliderId + '">' +
				'</div>' +
			'</div>' +
			'<div class="col-sm-12" style="margin-bottom: 5px;">' + 
				'<span class="pull-left">$' + minCost.toString() + '</span>'	+
				'<span class="pull-right">$' + maxCost.toString() + '</span>'	+
			'</div>';	
			sliderConfig = {
				id: costSliderId,
				values: [minCost, maxCost],
				min: minCost,
				max: maxCost,
				step: 1,
				range: true
			};
		}
		
		return {
			tags: tags,
			sliderConfig: sliderConfig
		};
	}
	
	/*
	 * create html tags for durtion filter
	 * @param {number}: minDuration
	 * @param {number}: maxDuration
	 */
	function getDurationFilterHtml(minDuration, maxDuration){
		var tags = '';
		var sliderConfig = null;
		if(typeof(maxDuration) === 'number' && typeof(minDuration) === 'number' && maxDuration > minDuration) {
			tags = 
			'<div class = "col-sm-12">' + 
				'<label class="sr-only">Time</label>' +
				'<label class="col-sm-12">Time</label>' +
			'</div>' +
			'<div class="col-sm-12">' +
				'<div id="' + durationSliderId + '">' +
				'</div>' +
			'</div>' +
			'<div class="col-sm-12" style="margin-bottom: 5px;">' + 
				'<span class="pull-left">' + minDuration.toString() + 'min</span>'	+
				'<span class="pull-right">' + maxDuration.toString() + 'min</span>'	+
			'</div>';	
			sliderConfig = {
				id: durationSliderId,
				values: [minDuration, maxDuration],
				min: minDuration,
				max: maxDuration,
				step: 1,
				range: true
			};
		}
		
		return {
			tags: tags,
			sliderConfig: sliderConfig
		};
	}
	
	/*
	 * add tooltip for each slider
	 * @param {Object} slider
	 */
	function addSliderTooltip(slider) {
		var sliderId = "#" + slider.id;
		$(sliderId).slider(slider);
		
		$(sliderId).on('slide', function( event, ui ) {
				var minVal = ui.values[0];
				var maxVal = ui.values[1];
				$(sliderId + ' .ui-slider-handle:first').append('<div class="tooltip top slider-tip"><div class="tooltip-arrow"></div><div class="tooltip-inner">' + minVal + '</div></div>');
				$(sliderId + ' .ui-slider-handle:last').append('<div class="tooltip top slider-tip"><div class="tooltip-arrow"></div><div class="tooltip-inner">' + maxVal + '</div></div>');
        		
        		waitForFinalEvent(filterPlans, 100, slider.Id + ' sliding');
		});
		
		$(sliderId + " .ui-slider-handle").mouseleave(function() {
			$(sliderId  + ' .ui-slider-handle').empty();
		});
		$(sliderId + " .ui-slider-handle").mouseenter(function() {
			var values = $(sliderId).slider( "option", "values" );
			var minVal = values[0];
			var maxVal = values[1];
			$(sliderId + ' .ui-slider-handle:first').append('<div class="tooltip top slider-tip"><div class="tooltip-arrow"></div><div class="tooltip-inner">' + minVal + '</div></div>');
			$(sliderId + ' .ui-slider-handle:last').append('<div class="tooltip top slider-tip"><div class="tooltip-arrow"></div><div class="tooltip-inner">' + maxVal + '</div></div>');
		});
		
	}
	
	/*
	 * given time range, create tick labels
	 * @param {Date} tripStartTime
	 * @param {Date} tripEndTime
	 * @param {number} intervalStep
	 * @return {Array} tickLabels
	 */
	function getTickLabels(tripStartTime, tripEndTime, intervalStep) {
		var tickLabels = [];
		var labelFormat = d3.time.format('%H:%M %p');
		var ticks = d3.time.scale()
			.domain([tripStartTime, tripEndTime])
			.nice(d3.time.minute, intervalStep)
			.ticks(d3.time.minute, intervalStep)
			.forEach(function(tick) {
				tickLabels.push(labelFormat(tick));
			});
			
		return tickLabels;
	}
	
	/**
	 * Create a timeline chart
	 * @param {string} chartDivId 
	 * @param {Array} tripLegs
	 * @param {Date} tripStartTime
	 * @param {Date} tripEndTime
	 * @param {number} intervalStep
	 * @param {number} barHeight
	 */
	function createChart(chartDivId, tripLegs, tripStartTime, tripEndTime, intervalStep, barHeight) {
		if(! tripStartTime instanceof Date || ! tripEndTime instanceof Date || 
			! tripLegs instanceof Array || typeof(intervalStep) != 'number' || typeof(barHeight) != 'number') {
			return;
		}
		var $chart = $('#' + chartDivId);
		if($chart.length === 0) { //this chart div doesnt exist
			return;
		}
		
		var width = $chart.width();
		var height = $chart.height();
		var chart = d3.select('#' + chartDivId) 
		  .append('svg')
		  .attr('class', 'chart')
		  .attr('width', width)
		  .attr('height', height);
		
		//create d3 time scale 
		var xScale = d3.time.scale()
			.domain([tripStartTime, tripEndTime])
			.nice(d3.time.minute, intervalStep);
		var x = xScale
		    .range([0, width]);

		var y = d3.scale.linear()
		   .domain([0, 2])
		   .range([0, height]);
		
		//generate ticks
		var ticks = xScale
			.ticks(d3.time.minute, intervalStep);
		
		//draw tick lines without first and last (this is styled by border)
		if(ticks.length > 0) {
			ticks.splice(0, 1);
			
			if(ticks.length > 0) {
				ticks.splice(ticks.length -1, 1);
			}
		}
		
		chart.selectAll("line")
		  .data(ticks)
		  .enter().append("line")
		  .attr("x1", function(d) { return x(d); })
		  .attr("x2", function(d) { return x(d); })
		  .attr("y1", 0)
		  .attr("y2", height);
		
		var tipText = "";
		tripLegs.forEach(function(leg) {
			tipText += leg.description + "<br>";
		});
		
		chart.selectAll("rect")
		   .data(tripLegs)
		   .enter().append("rect")
		   .attr('class', function(d) { return "travel-type-" + d.type; })
		   .attr("x", function(d) { return x(parseDate(d.start_time)); })
		   .attr("y", y(1) - barHeight/2)
		   .attr("width", function(d) { return x(parseDate(d.end_time)) - x(parseDate(d.start_time)); })
		   .attr("height", barHeight)
		   .on("mouseover", function(d) {
				chartTooltipDiv.transition()        
					.duration(200)      
					.style("opacity", .9);
				chartTooltipDiv.html(tipText) //d.description if for each leg  
					.style("left", d3.event.pageX + "px")     
					.style("top", (d3.event.pageY) + "px");
				})                  
			.on("mouseout", function(d) {       
				chartTooltipDiv.transition()        
					.duration(500)      
					.style("opacity", 0);
			});
	};
	
	/**
	 * Create a timeline chart
	 * @param {string} chartDivId 
	 * @param {Date} tripStartTime
	 * @param {Date} tripEndTime
	 * @param {number} intervalStep
	 * @param {number} barHeight
	 */
	function resizeChart (chartDivId, tripStartTime, tripEndTime, intervalStep, barHeight) {
		if(! tripStartTime instanceof Date || ! tripEndTime instanceof Date || 
			typeof(intervalStep) != 'number' || typeof(barHeight) != 'number') { //type check
			return;
		}
		var $chart = $('#' + chartDivId);
		if($chart.length === 0) { //this chart div doesnt exist
			return;
		}
		
		var width = $chart.width();
		var height = $chart.height();
		var svgSelector = '#' + chartDivId + ">svg";
		var chart = d3.select(svgSelector)
			.attr('width', width);
		
		//create d3 time scale 
		var xScale = d3.time.scale()
			.domain([tripStartTime, tripEndTime])
			.nice(d3.time.minute, intervalStep);
		var x = xScale
		    .range([0, width]);

		var y = d3.scale.linear()
		   .domain([0, 2])
		   .range([0, height]);
		
		//update tick lines
		chart.selectAll("line")
		  .attr("x1", function(d) { return x(d); })
		  .attr("x2", function(d) { return x(d); })
		  .attr("y1", 0)
		  .attr("y2", height);
		
		//update chart items
		chart.selectAll("rect")
		   .attr("x", function(d) { return x(parseDate(d.start_time)); })
		   .attr("y", y(1) - barHeight/2)
		   .attr("width", function(d) { return x(parseDate(d.end_time)) - x(parseDate(d.start_time)); })
		   .attr("height", barHeight);
	};
	
	/*
	 * main filtering function that handles modes, transfer, cost, and duration
	 */
	function filterPlans(){
		var modes = [];
		var modeCheckboxs = $('#' + modeContainerId + ' .checkbox :checked');
		for(var i=0, modeCount=modeCheckboxs.length; i<modeCount; i++) {
			var modeCheckbox = modeCheckboxs[i];
			var modeVal = modeCheckbox.attributes['value'].value;
			if(typeof(modeVal) ==='string' && modeVal.trim().length > 0) {
				modes.push(parseInt(modeVal));
			} else if(typeof(modeVal) === 'number') {
				modes.push(modeVal);
			}
		}
		
		var transferValues = $('#' + transferSliderId).slider( "option", "values" );
		
		
		var costValues = $('#' + costSliderId).slider( "option", "values" );
		
		
		var durationValues = $('#' + durationSliderId).slider( "option", "values" );
		
		
		var allPlans = d3.selectAll('.single-plan-review')[0];
		allPlans.forEach(function(plan) {
			processPlanFiltering(modes, transferValues, costValues, durationValues, plan);
		});
	}
	
	function processPlanFiltering(modes, transferValues, costValues, durationValues, plan){
			var modeVisible = false;
			if(modes instanceof Array) {
				modeVisible = filterPlansByMode(modes, plan);
			}
		
			var transferVisible = false;
			if(transferValues instanceof Array && transferValues.length === 2) {
				transferVisible = filterPlansByTransfer(transferValues[0], transferValues[1], plan);
			}
			
			var costVisible = false;
			if(costValues instanceof Array && costValues.length === 2) {
				costVisible = filterPlansByCost(costValues[0], costValues[1], plan);
			}
			
			var durationVisible = false;
			if(durationValues instanceof Array && durationValues.length === 2) {
				durationVisible = filterPlansByDuration(durationValues[0], durationValues[1], plan);
			}
		
			if(modeVisible && transferVisible && costVisible && durationVisible) {
				plan.style.display = 'block';
				
				var tmpTripId = plan.attributes['data-trip-id'].value;
				var tmpPlanId = plan.attributes['data-plan-id'].value;
				var tmpTripStartTime = parseDate(plan.attributes['data-start-time'].value);
				var tmpTripEndTime = parseDate(plan.attributes['data-end-time'].value);		
				var tmpChartDivId = tripPlanDivPrefix + tmpTripId + "_" + tmpPlanId;	
				resizeChart(tmpChartDivId, tmpTripStartTime, tmpTripEndTime, intervalStep, barHeight);
			} else {
				plan.style.display = 'none';
			}
	}
	
	/*
	 * Filter trip plans by modes
	 * @param {Array} modes: an array of mode Ids
	 * @param {object} plan
	 * @return {bool} visible
	 */
	function filterPlansByMode(modes, plan) {
		var visible =false;
		if(!modes instanceof Array || typeof(plan) != 'object' || ! plan.hasOwnProperty('attributes')) {
			return visible;
		}
					
		var mode = plan.attributes['data-mode'].value;
		visible = (modes.indexOf(parseInt(mode)) >= 0);
		
		return visible;
	}
	
	/*
	 * Filter trip plans by number of transfer
	 * @param {number} minCount
	 * @param {number} maxCount
	 * @param {object} plan
	 * @return {bool} visible
	 */
	function filterPlansByTransfer(minCount, maxCount, plan) {
		var visible = false;
		if(typeof(minCount) != 'number' || typeof(maxCount) != 'number'  || typeof(plan) != 'object' || ! plan.hasOwnProperty('attributes')) {
			return visible;
		}
					
		var transfer = parseInt(plan.attributes['data-transfer'].value);
		visible = (typeof(transfer) === 'number' && transfer >= minCount && transfer <= maxCount);
		
		return visible;
	}
	
	/*
	 * Filter trip plans by total cost
	 * @param {number} minCost
	 * @param {number} maxCost
	 * @param {object} plan
	 * @return {bool} visible
	 */
	function filterPlansByCost(minCost, maxCost, plan) {
		var visible = false;
		if(typeof(minCost) != 'number' || typeof(maxCost) != 'number' || typeof(plan) != 'object' || ! plan.hasOwnProperty('attributes')) {
			return visible;
		}
					
		var cost = parseFloat(plan.attributes['data-cost'].value);
		visible = (typeof(cost) === 'number' && cost >= minCost && cost <= maxCost);
		
		return visible;
	}
	
	/*
	 * Filter trip plans by total duration
	 * @param {number} minDuration
	 * @param {number} maxDuration
	 * @param {object} plan
	 * @return {bool} visible
	 */
	function filterPlansByDuration(minDuration, maxDuration, plan) {
		var visible = false;
		if(typeof(minDuration) != 'number' || typeof(maxDuration) != 'number'  || typeof(plan) != 'object' || ! plan.hasOwnProperty('attributes')) {
			return visible;
		}
					
		var duration = parseFloat(plan.attributes['data-duration'].value);
		visible = (typeof(duration) === 'number' && duration >= minDuration && duration <= maxDuration);
		
		return visible;
	}
	
	/*
	 * Generate Camel case
	 * @param {string} str
	 */
	function toCamelCase(str) {
	    return str.replace(/(?:^|\s)\w/g, function(match) {
	        return match.toUpperCase();
	    });
	}
	
	/*
	 * remove spaces within a string
	 * @param {string} str
	 */
	function removeSpace(str) {
	    return str.replace(/\s+/g, '');
	}
	
	/*
	 * parse data in format: %Y-%m-%d %H:%M
	 * @param {string} dateStr
	 */
	function parseDate(dateStr) {
		if(typeof(dateStr) != 'string') {
			return null;
		}
	    var format = d3.time.format("%Y-%m-%d %H:%M");
		return format.parse(dateStr.trim()); 
	}
	
	//Test data
	var resp = {
		"status" : 1,		// return 0 if something went wrong, interpret anything else as success
		"trip_parts" : [				// Trips in order (from Origin 1 -> D 1, then Origin 2 -> D 2, etc.
			{
				"trip_part_id": 1,	//ActiveRecord ID
				"description" : "Outbound - 40 Courtland Street NE Atlanta, GA 30308 to Atlanta VA Medical Center",
				"start_time" : '2014-06-13 09:05 ',	// UTC time of the trip as a string, per ISO 8601
				"end_time" : '2014-06-13 13:05 ',	// UTC time of the trip as a string, per ISO 8601
				"is_depart_at": true,
				"itineraries" : [		// List of potential trip parts
					{	// individual itinerary
						"id" : 2, 		// ActiveRecord ID
						"missing_information" : {
							"short_desc" : "Must be older than 65 to user this service.",	// A short version of the information required
							"long_desc"	 : "Date of birth",	// The complete description of information required from user
							"type"		 : "Age",	// Type of response required.  Options determined by Eligibility Questions
							
							"success_condition": ">= 65"
						},
						"mode" : 1,	// t(Mode.code)
						"mode_name" : 'Bus', 	// Mode.name
						"service_name" : 'Marta',
						"contact_information" : {
							'url': 'http://www.itsmarta.com/'
						},
						"cost" : {
							"price" : 26,	// If a cost is known, cost, else null
							"comments" : ''	// Any textual information required pertaining to price, e.g. 
						},
						"duration" : {
							"sortable_duration": 80
						},
						"transfers" : 2,
						"legs" : [				//Each portion of the itinerary, equivalent to a single colored box within a racelane from the wireframes
							{
								"type" : 'walk',
								"description" : 'walk to main st',		// Textural description of the step involved, e.g. "Walk to Bleecker St"
								"start_time": '2014-06-13 09:05 ',
								"end_time": '2014-06-13 09:20 ',
								"time_description" : "4:44 PM to 4:48 PM"
							},
							{
								"type" : 'vehicle',
								"description" : 'bus 1',		// Textural description of the step involved, e.g. "Walk to Bleecker St"
								"start_time": '2014-06-13 09:20 ',
								"end_time": '2014-06-13 10:05 ',
								"time_description" : "4:44 PM to 4:48 PM"
							},
							{
								"type" : 'transfer',
								"description" : 'transfer',		// Textural description of the step involved, e.g. "Walk to Bleecker St"
								"start_time": '2014-06-13 10:05 ',
								"end_time": '2014-06-13 10:10 ',
								"time_description" : "4:44 PM to 4:48 PM"
							},
							{
								"type" : 'vehicle',
								"description" : 'bus 2',		// Textural description of the step involved, e.g. "Walk to Bleecker St"
								"start_time": '2014-06-13 10:10 ',
								"end_time": '2014-06-13 13:05 ',
								"time_description" : "4:44 PM to 4:48 PM"
							}
						],
					},
				]
			},
			{
				"trip_part_id": 2,
				"description" : "Return - 40 Courtland Street NE Atlanta, GA 30308 to Atlanta VA Medical Center",
				"start_time" : '2014-06-13 09:05 ',	// UTC time of the trip as a string, per ISO 8601
				"end_time" : '2014-06-13 13:05 ',	// UTC time of the trip as a string, per ISO 8601
				"is_depart_at": false,
				"itineraries" : [		// List of potential trip parts
					{	// individual itinerary
						"id" : 2, 		// ActiveRecord ID
						"missing_information" : {
							"short_desc" : "You must be a veteran to use this service",	// A short version of the information required
							"long_desc"	 : "are you a military veteran?",	// The complete description of information required from user
							"type"		 : "Radio",	// Type of response required.  Options determined by Eligibility Questions
							"options"	 : [		// Options available to the user for selection.
								{	//An individual selection option
									"text" : "Yes", // Displayable description of option
									"value": 1, // Internal value of option (for instance on checkbox or radiobutton)
								},
								{	//An individual selection option
									"text" : "No", // Displayable description of option
									"value": 0, // Internal value of option (for instance on checkbox or radiobutton)
									"is_default": true
								},
							],
							"success_condition": "== 1"
						},
						"mode" : 2,	// t(Mode.code)
						"mode_name" : 'Taxi', 	// Mode.name
						"service_name" : '',
						"cost" : {
							"price" : 200,	// If a cost is known, cost, else null
							"comments" : ''	// Any textual information required pertaining to price, e.g. 
						},
						"duration" : {
							"sortable_duration": 130
						},
						"transfers" : 3,
						"legs" : [				//Each portion of the itinerary, equivalent to a single colored box within a racelane from the wireframes
							{
								"type" : 'walk',
								"description" : 'walk to main st',		// Textural description of the step involved, e.g. "Walk to Bleecker St"
								"start_time": '2014-06-13 09:05 ',
								"end_time": '2014-06-13 09:20 ',
								"time_description" : "4:44 PM to 4:48 PM"
							},
							{
								"type" : 'vehicle',
								"description" : 'bus 1',		// Textural description of the step involved, e.g. "Walk to Bleecker St"
								"start_time": '2014-06-13 09:20 ',
								"end_time": '2014-06-13 10:05 ',
								"time_description" : "4:44 PM to 4:48 PM"
							},
							{
								"type" : 'transfer',
								"description" : 'transfer',		// Textural description of the step involved, e.g. "Walk to Bleecker St"
								"start_time": '2014-06-13 10:05 ',
								"end_time": '2014-06-13 10:10 ',
								"time_description" : "4:44 PM to 4:48 PM"
							},
							{
								"type" : 'vehicle',
								"description" : 'bus 2',		// Textural description of the step involved, e.g. "Walk to Bleecker St"
								"start_time": '2014-06-13 10:10 ',
								"end_time": '2014-06-13 13:05 ',
								"time_description" : "4:44 PM to 4:48 PM"
							}
						],
					},
				]
			}
		]
	};

	
	//render
	processTripResponse(resp);
});