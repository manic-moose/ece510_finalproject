function makeHttpObject() {
var isIE = true;
	try {
		return [new ActiveXObject("Msxml2.XMLHTTP"), isIE];
	} catch (e) {
		try {
			return new ActiveXObject("Microsoft.XMLHTTP");
		} catch (e) {
			try {
				isIE = false;
				return [new XMLHttpRequest(), isIE];
			} catch (e) {
				alert("Error: HTTP request object could not be created. Please try different browser");
			}
		}
	}

	throw new Error("Could not create HTTP request object.");
}

function errorLoadingSourceFile(table)
{
		var table_rows = table.rows;
		/* delete all rows from the table and print the error message */
		while (table_rows.length > 1) {
			/* starting from 1 to escape the file name row */
			table.tBodies[0].removeChild(table_rows[1]);
		}
		
		var newCell;
		var newRow = document.createElement('TR');
		
		newCell = document.createElement('TD');
		newCell.className = "srcLine";
		newCell.innerHTML = "&nbsp;";
		newRow.appendChild(newCell);
		
		newCell = document.createElement('TD');
		newCell.className = "srcStmt";
		newCell.innerHTML = "&nbsp;";
		newRow.appendChild(newCell);
		
		newCell = document.createElement('TD');
		newCell.className = "covNorm";
		newCell.innerHTML = "&nbsp;";
		newRow.appendChild(newCell);
		
		newCell = document.createElement('TD');
		newCell.className = "srcNorm";
		newCell.setAttribute("style", "color:red;");
		newCell.innerHTML = "Error: HTTP request could not be created. Make sure that the source file \""
		                    + table.id
							+ "\" exists<br />If the problem persists, try different browser, or "
							+ "try generating the report using the switch -stmtaltflow";
		newRow.appendChild(newCell);
		
		table.tBodies[0].appendChild(newRow);
		return;
}

function buildStmtTable(divId)
{
    var isUnableToLoadHtmlSrcFile = 0;
	var show_excl_button = 0;
	
	var divObj = document.getElementById(divId);
	var table = 0;
	var buttonsTable = 0;
	var t=0;
	for (; t < divObj.childNodes.length ; t++ ) {
		if (typeof divObj.childNodes[t].tagName === "undefined") {
			continue; /* This is not an HTML dom element */
		}
		if (divObj.childNodes[t].tagName.match("TABLE") == null) {
			continue; /* not a table element */
		}
		if (divObj.childNodes[t].className.match("buttons") ) {
			buttonsTable = divObj.childNodes[t];
			continue;
		}
		
		/* found the table. Break */
		table = divObj.childNodes[t];
		break;
	}
	
	if (table == 0) {
		return;
	}
	
	var old_rows = table.rows;
	
	var prevRow;
	var isIE = true;
	
	
	var prevRow;
	var isIE = true;
	var request = 0;
	try {
		request = makeHttpObject();
		isIE = request[1];
		request = request[0];
	request.open("GET", table.id, false);
	request.send(null);
} catch (e) {
		errorLoadingSourceFile(table);
		return;
}

if (isIE) {
	var xmlDocument = new ActiveXObject("Microsoft.XMLDOM");
	xmlDocument.async = "false";
	try {
		if (!xmlDocument.loadXML(request.responseText))
		throw e;
	} catch(e) {
			errorLoadingSourceFile(table);
			return;
	}
	ttNode = xmlDocument.documentElement.childNodes[1].childNodes[0];
} else {
	try {
		ttNode = request.responseXML.getElementsByTagName("tt")[0];
		if (ttNode == undefined)
			throw e;
	} catch (e) {
			errorLoadingSourceFile(table);
			return;
	}
}

	var firstLine = old_rows[1].getAttribute("z").match(/^([^$]+)\$([^$]*)\$([^$]*)\$([^$]*)$/i);
for (var v=0; v < firstLine[0+1] - 1;) {
	if (ttNode.childNodes[0] == undefined) {
		alert("Lines in the source page \""+table.id+"\" are not enough");
		throw e;
	}
	if (ttNode.childNodes[0].nodeName.match(/^a$/i) && ttNode.childNodes[0].getAttribute("name")) {
		v++;
	}
	ttNode.removeChild(ttNode.childNodes[0]); 
}

	for (var i = 1; i < old_rows.length; i++) {
		var dataInCells = old_rows[1].getAttribute("z").match(/^([^$]+)\$([^$]*)\$([^$]*)\$([^$]*)$/i);
	var newRow = document.createElement('TR');
	var newCells = [];
	var binId = dataInCells[4];
	for (var n = 0; n <= 3; n++) {
		newCells[n] = document.createElement('TD');
		if (n == 3) {
			var link = [];
			if (!newCells[1].innerHTML.match(/^\.\d+$/)) {
				// line that doesn't contain item number
				newCells[n].innerHTML = "";
				if (dataInCells[3+1].match(/^.*class=Y$/)) {
					newCells[2].innerHTML = "";
					newCells[n].className = 'Y';
					binId = binId.replace("class=Y","");
				} else if (hrefData = dataInCells[3+1].match(/^.+\.htm[l]?$/)) {
					newCells[2].innerHTML = "";
					link[dataInCells[0+1]] = hrefData[0];
					binId = "";
				}

				for (var c=0; c < ttNode.childNodes.length - 1;) {
					if (ttNode.childNodes[0].nodeName.match(/^a$/i) && ttNode.childNodes[0].getAttribute("name")) {
						c = 2;
						for (;(! ttNode.childNodes[c].nodeName.match(/^br$/i)) && (c < ttNode.childNodes.length - 1);c++) {
							var newNode = ttNode.childNodes[c].cloneNode(true);
							try {
								if (newNode.childNodes.length>1 && newNode.childNodes[1].nodeName.match(/^a$/i) && newNode.childNodes[1].getAttribute("href") && link[dataInCells[0+1]]) {
									newNode.childNodes[1].setAttribute("href",link[dataInCells[0+1]]);
								}
								newCells[n].appendChild(newNode);
							} catch (e) {
								// IE ..... 
								if (ttNode.childNodes[c].nodeType == 3) {
									// text node
									var tmp = document.createTextNode(ttNode.childNodes[c].nodeValue);
								} else if (ttNode.childNodes[c].nodeType == 1) {
									var tmp = document.createElement(ttNode.childNodes[c].nodeName);
									if (ttNode.childNodes[c].getAttribute("class"))
										tmp.className = ttNode.childNodes[c].getAttribute("class");
										
									var innerV = document.createTextNode(ttNode.childNodes[c].childNodes[0].nodeValue);
									tmp.appendChild(innerV);
										
									if (ttNode.childNodes[c].childNodes.length>1 && ttNode.childNodes[c].childNodes[1].nodeName.match(/^a$/i) && ttNode.childNodes[c].childNodes[1].getAttribute("href")) {
										var innerA = document.createElement("a");
										innerA.setAttribute("href",ttNode.childNodes[c].childNodes[1].getAttribute("href") );
										innerA.innerHTML = ttNode.childNodes[c].childNodes[1].childNodes[0].nodeValue;
										tmp.appendChild(innerA);
										if (ttNode.childNodes[c].childNodes.length>2) {
											var innerV = document.createTextNode(ttNode.childNodes[c].childNodes[2].nodeValue);
											tmp.appendChild(innerV);
										}
									}
								}
								newCells[n].appendChild(tmp);
							}
						}
						ttNode.removeChild(ttNode.childNodes[0]);
						break;
					}
					ttNode.removeChild(ttNode.childNodes[0]);
				}
			} else {
				newCells[n].innerHTML = "";
			}
		} else {
			newCells[n].innerHTML = dataInCells[n+1];
		}
		newRow.appendChild(newCells[n]);
	}
		table.tBodies[0].removeChild(old_rows[1]);
	table.tBodies[0].appendChild(newRow);
	
	var tmp = document.createElement('A');
	tmp.name = newRow.cells[0].innerHTML;
	newRow.cells[0].appendChild(tmp);
	newRow.cells[0].className = 'srcLine';
	newRow.cells[1].className = 'srcStmt';

	newRow.cells[3].innerHTML = newRow.cells[3].innerHTML.replace(/%s%/g,"&nbsp;");
	newRow.cells[3].innerHTML = newRow.cells[3].innerHTML.replace(/%t%/g,"&nbsp;&nbsp;&nbsp;&nbsp;");
	
	if (newRow.cells[2].innerHTML.match(/^\d+$/)) {
		if (newRow.cells[2].innerHTML > 0) {
			newRow.cells[2].className = 'covGreen';
			newRow.className = 'covered';
			if(newRow.cells[1].innerHTML.match(/^\.\d+$/)) {
				newRow.cells[3].innerHTML = "&nbsp;";
				newRow.cells[3].className = 'srcNorm';
			} else /*if(newRow.cells[1].innerHTML == "&nbsp;")*/ {
				newRow.cells[1].innerHTML = "&nbsp;";
				newRow.cells[3].className = 'srcGreen';
			}
			
			/* after coloring the cell, check if we have test data or not, if we do, then add a link to the pertest.htm file */
			var testHitDataScopeId; /* define here in case it is not defined globaly in the stmt details html page */
			if ( testHitDataScopeId != undefined ) {
				if ( binId != "" ) {
					var popupWidth; /* define here in case it is not defined globaly in the stmt details html page */
					var popupHight; /* define here in case it is not defined globaly in the stmt details html page */
					if ( (popupWidth == undefined) || (popupHight == undefined) ) {
						/* set to a default value */
						popupWidth = 200;
						popupHight = 200;
					}
					newRow.cells[2].innerHTML = "<a class=\"stmt_testdata\" href = \"pertest.htm?bin=" + binId + "&scope=" + testHitDataScopeId + "\" rel=\"popup " + popupWidth + " " + popupHight + "\">" + newRow.cells[2].innerHTML + "</a>";
				}
			}
		} else if (newRow.cells[2].innerHTML == '0') {
			newRow.cells[2].className = 'covRed';
			newRow.className = 'missing';
			if(newRow.cells[1].innerHTML.match(/^\.\d+$/)) {
				newRow.cells[3].className = 'srcNorm';
				newRow.cells[3].innerHTML = "&nbsp;";
			} else /*if(newRow.cells[1].innerHTML == "&nbsp;")*/ {
				newRow.cells[1].innerHTML = "&nbsp;";
				newRow.cells[3].className = 'srcRed';
			}
		}
	} else if (newRow.cells[2].innerHTML.match(/^E-.+$/)) {
		show_excl_button = 1;
		newRow.cells[2].className = 'covExcluded';
		newRow.className = 'excluded';
		if(newRow.cells[1].innerHTML.match(/^\.\d+$/)) {
			newRow.cells[3].className = 'srcNorm';
			newRow.cells[3].innerHTML = "&nbsp;";
		} else /*if(newRow.cells[1].innerHTML == "&nbsp;")*/ {
			newRow.cells[1].innerHTML = "&nbsp;";
			newRow.cells[3].className = 'srcExcluded';
		}
	} else {
		newRow.cells[1].innerHTML = "&nbsp;";
		newRow.cells[2].innerHTML = "&nbsp;";
		newRow.cells[2].className = 'covNorm';
			if (i>1) {
			// so that prevRow has a value
			if (prevRow.className == 'neutral') {
				newRow.className = 'neutral';
				newRow.cells[3].className = 'srcNorm';
			} else if (newRow.cells[3].className == 'Y') {
				newRow.cells[3].className = 'srcYellow';
			} else if (prevRow.className == 'covered' && prevRow.cells[1].innerHTML.match(/^\.\d+$/)) {
				newRow.className = 'covered';
				newRow.cells[3].className = 'srcGreen';
			} else if (prevRow.className == 'missing' && prevRow.cells[1].innerHTML.match(/^\.\d+$/)) {
				newRow.className = 'missing';
				newRow.cells[3].className = 'srcRed';
			} else if (prevRow.className == 'excluded' && prevRow.cells[1].innerHTML.match(/^\.\d+$/)) {
				newRow.className = 'excluded';
				newRow.cells[3].className = 'srcExcluded';
			} else {
				newRow.className = 'neutral';
				newRow.cells[3].className = 'srcNorm';
			}
		} else {
			newRow.className = 'neutral';
			newRow.cells[3].className = 'srcNorm';
		}
	}
	prevRow = newRow;
}

if (show_excl_button == 1) {
		if (buttonsTable) {
		newCell = document.createElement('TD');
		newCell.id = "showExcl";
		newCell.width = 106;
		newCell.setAttribute("onclick", "showExcl()");
		newCell.className = "button_off";
		newCell.title = "Display only excluded scopes and bins.";
		newCell.innerHTML = "Show Excluded";
			buttonsTable.rows[0].appendChild(newCell);
		}
	}
}


