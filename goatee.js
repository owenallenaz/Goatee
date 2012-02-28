/*** Built using revealing module pattern for public/private functions ***/
/*** Feel free to change the namespace, it will not alter the libraries functionality ***/
goatee = (function() {
	var fill = function(html, data) {
		var returnHTML = html;
		var matches = "";
		var value = ""
		var currentHTML = html;
		var tags = [];
		var index = 0;
		var lastValue = "";
		
		while(true) {
			matches = currentHTML.match(/\{\{(#|!|:|\/)(.*?)\}\}/);
			
			if (matches == null) {
				break;
			}
			
			value = "";
			
			if (matches[1].match(/[#:!]/) instanceof Array) {
				tags.push({ label : matches[2], index : index });
				returnHTML = returnHTML.replace(matches[0], matches[0].replace("}}", "_" + index + "}}"));
				currentHTML = currentHTML.replace(matches[0], "");
				index++;
			} else if (matches[1] == "/") {
				lastValue = tags[tags.length - 1].index;
				tags.splice(tags.length - 1,1);
				returnHTML = returnHTML.replace(matches[0], matches[0].replace("}}", "_" + lastValue + "}}"));
				currentHTML = currentHTML.replace(matches[0], "");
			}
		}
		
		return processTags(returnHTML, data);
	};
	var processTags = function(html, data) {
		var returnHTML = html;
		var matches = "";
		var value = "";

		while(true) {
			matches = returnHTML.match(/\{\{(#|!|:)(.*?)_(\d*?)\}\}([\s\S]*?)\{\{\/\2_\3\}\}/);

			if (matches == null) {
				break;
			}

			value = "";
			
			if (matches[1] == "#" && typeof data[matches[2]] != "undefined") {
				if (data[matches[2]] instanceof Array) {
					for(var i = 0; i < data[matches[2]].length; i++) {
						value += processTags(matches[4], data[matches[2]][i]);
					}
				} else if (data[matches[2]] instanceof Object) {
					value = processTags(matches[4], data[matches[2]]);
				}
			} else if (matches[1] == ":" && typeof data[matches[2]] != "undefined") {
				if (
					(typeof data[matches[2]] == "string" && data[matches[2]] != "" && data[matches[2]] != "false")
					|| 
					(data[matches[2]] instanceof Array && data[matches[2]].length > 0)
					||
					(typeof data[matches[2]] == "boolean" && data[matches[2]] != false)
					||
					(typeof data[matches[2]] == "number")
				) {
					value = matches[0].replace(new RegExp("\{\{(:|/)" + matches[2] + "_" + matches[3] + "\}\}", "g"), "");
				}
			} else if (matches[1] == "!" && (
					typeof data[matches[2]] == "undefined" 
					|| (
						(typeof data[matches[2]] == "string" && (data[matches[2]] == "" || data[matches[2]] == "false"))
						||
						(data[matches[2]] instanceof Array && data[matches[2]].length == 0)
						||
						(typeof data[matches[2]] == "boolean" && data[matches[2]] == false)
					)
				)) {
				value = matches[0].replace(new RegExp("\{\{(!|/)" + matches[2] + "_" + matches[3] + "\}\}", "g"), "");
			} 
			
			returnHTML = returnHTML.replace(matches[0], value);
		}
				
		while(true) {
			matches = returnHTML.match(/\{\{(\w*?)\}\}/);
			
			if (matches == null) {
				break;
			}

			value = "";
			if (typeof data[matches[1]] == "undefined") {
				value = "";
			} else if (typeof data[matches[1]] == "string" || typeof data[matches[1]] == "number") {
				/*** standard tags ***/
				value = data[matches[1]];
			} else if (typeof data[matches[1]].template != "undefined" && typeof data[matches[1]].data != "undefined") {
				/*** passing a template and data structure ***/
				
				/*** Is array loop over array ***/
				if (data[matches[1]].data instanceof Array) {
					for(var i = 0; i < data[matches[1]].data.length; i++) {
						value += fill(data[matches[1]].template, data[matches[1]].data[i]);
					}
				} else {
					value = fill(data[matches[1]].template, data[matches[1]].data);
				}
			}

			returnHTML = returnHTML.replace(new RegExp(matches[0], "g"), value);	
		}
		
		return returnHTML;
	};
	var unpreserve = function(html) {
		return html.replace(/\{\{\$/g, "{{");
	}
	
	/*** only reveal public methods ***/
	return {
		fill : fill,
		unpreserve : unpreserve
	}
})();