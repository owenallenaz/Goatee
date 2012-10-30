/*** Built using revealing module pattern for public/private functions ***/
/*** Feel free to change the namespace, it will not alter the libraries functionality ***/
goatee = (function() {
	var fill = function(html, data) {
		var currentHTML = html;
		
		// lowercase data keys
		var myData = lcaseKeys(data);
		
		var context = {
			tags : [],
			start : 0,
			inner : html,
			innerStart : 0,
			innerEnd : html.length,
			end : html.length
		};
		var myContext = context;
		var previousContext = [];
		while(true) {
			var matches = currentHTML.match(/\{\{([##!:%\/-]?)(.*?)\}\}/);
			
			if (matches == null) {
				break;
			}
			
			if (matches[1] != "/") {
				myContext.tags.push({ label : matches[2].toLowerCase(), type : matches[1], start : matches.index, end : matches[0].length + matches.index, innerStart : matches[0].length + matches.index, innerEnd : "", tags : [] });
				
				if (matches[1] != "" && matches[1] != "%") {
					previousContext.push(myContext);
					myContext = myContext.tags[myContext.tags.length - 1];
				}
			} else {
				myContext.end = matches[0].length + matches.index;
				myContext.innerEnd = matches.index;
				myContext.inner = html.substring(myContext.innerStart, myContext.innerEnd);
				myContext = previousContext[previousContext.length - 1];
				previousContext.splice(previousContext.length - 1, 1);
			}
			
			var temp = [];
			for(var i = 0; i < matches[0].length; i++) {
				temp.push("-");
			}
			currentHTML = currentHTML.replace(matches[0], temp.join(""));
		}
		
		return processTags(html, context, [ myData ]);
	};
	
	var processTags = function(html, context, data) {
		var returnArray = [];
		
		var position = context.innerStart;
		for(var i = 0; i < context.tags.length; i++) {
			returnArray.push(html.substring(position, context.tags[i].start));
			position = context.tags[i].end;
			
			if (context.tags[i].type == "-") {
				if (data.length > 1) {
					var newData = data.slice();
					newData.splice(data.length - 1, 1);
					returnArray.push(processTags(html, context.tags[i], newData));
				}
				continue;
			}
			
			var myData = data[data.length - 1][context.tags[i].label];
			
			if (context.tags[i].type == "" || context.tags[i].type == "%") {
				if (typeof myData == "undefined") {
					// do nothing
				} else if (typeof myData == "string" || typeof myData == "number") {
					/*** standard tags ***/
					if (context.tags[i].type == "") {
						returnArray.push(myData)
					} else {
						returnArray.push(myData.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;'));
					}
				} else if (typeof myData.template != "undefined" && typeof myData.data != "undefined") {
					/*** passing a template and data structure ***/
					
					/*** Is array loop over array ***/
					if (myData.data instanceof Array) {
						for(var j = 0; j < myData.data.length; j++) {
							returnArray.push(fill(myData.template, myData.data[j]));
						}
					} else {
						returnArray.push(fill(myData.template, myData.data));
					}
				}
			} else if (context.tags[i].type == "#") {
				if (typeof myData != "undefined") {
					if (myData instanceof Array) {
						for(var j = 0; j < myData.length; j++) {
							var newData = data.slice();
							newData.push(myData[j]);
							returnArray.push(processTags(html, context.tags[i], newData));
						}
					} else if (myData instanceof Object && !isEmpty(myData)) {
						var newData = data.slice();
						newData.push(myData);
						returnArray.push(processTags(html, context.tags[i], newData));
					}
				}
			} else if (context.tags[i].type == ":") {
				if (
					typeof myData != "undefined" && (
						(typeof myData == "string" && myData != "" && myData != "false")
						|| 
						(myData instanceof Array && myData.length > 0)
						||
						(myData instanceof Object && !isEmpty(myData))
						||
						(typeof myData == "boolean" && myData != false)
						||
						(typeof myData == "number")
					)
				) {
					returnArray.push(processTags(html, context.tags[i], data));
				}
			} else if (context.tags[i].type == "!") {
				if (
					typeof myData == "undefined" 
					|| (
						(typeof myData == "string" && (myData == "" || myData == "false"))
						||
						(myData instanceof Array && myData.length == 0)
						||
						(myData instanceof Object && isEmpty(myData))
						||
						(typeof myData == "boolean" && myData == false)
					)
				) {
					returnArray.push(processTags(html, context.tags[i], data));
				}
			}
		}
		
		if (position < context.end) {
			returnArray.push(html.substring(position, context.innerEnd));
		}
		
		return returnArray.join("");
		
		while(true) {
			matches = returnHTML.match(/\{\{(%?)(\w*?)\}\}/);
			
			if (matches == null) {
				break;
			}
			
			value = "";
			if (typeof data[matches[2]] == "undefined") {
				value = "";
			} else if (typeof data[matches[2]] == "string" || typeof data[matches[2]] == "number") {
				/*** standard tags ***/
				value = data[matches[2]];
			} else if (typeof data[matches[2]].template != "undefined" && typeof data[matches[2]].data != "undefined") {
				/*** passing a template and data structure ***/
				
				/*** Is array loop over array ***/
				if (data[matches[2]].data instanceof Array) {
					for(var i = 0; i < data[matches[2]].data.length; i++) {
						value += fill(data[matches[2]].template, data[matches[2]].data[i]);
					}
				} else {
					value = fill(data[matches[2]].template, data[matches[2]].data);
				}
			}
			
			if (matches[1] == "%") {
				value = value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
			}
			
			returnHTML = returnHTML.replace(new RegExp(matches[0], "g"), value);	
		}
		
		return returnHTML;
	};
	
	/*** Cross browser way to test if an object has no keys ***/
	var isEmpty = function(obj) {
		for(var prop in obj) {
			if(obj.hasOwnProperty(prop)) {
				return false;
			}
		}
		
		return true;
	};
	
	// lower cases the keys in our passed in data to make lookups possible
	var lcaseKeys = function(data) {
		if (data instanceof Array) {
			var newData = [];
			
			for(var i = 0; i < data.length; i++) {
				newData[i] = lcaseKeys(data[i]);
			}
			
			return newData;
		} else if (typeof data == "object" && data !== null) {
			var newData = {};
			
			for(var i in data) {
				newData[i.toLowerCase()] = lcaseKeys(data[i]);
			}
			
			return newData;
		} else {
			return data;
		}
	};
	
	var unpreserve = function(html) {
		return html.replace(/\{\{\$/g, "{{");
	};
	
	/*** only reveal public methods ***/
	return {
		fill : fill,
		unpreserve : unpreserve
	}
})();