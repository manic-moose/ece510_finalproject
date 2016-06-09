
var g_cellClass      = ["odd",   "even"];
var g_cellClassRight = ["odd_r", "even_r"];
var g_cellClassGrey = ["oddGrey", "evenGrey"];
var g_cellClassRGrey = ["odd_rGrey", "even_rGrey"];

function buildStmtTableNoSource(divId) {
	var newlook = 0;
	var show_excl_button = 0;
	var divObj = document.getElementById(divId);
	
	var table = 0;
	var buttonsTable = 0;
	var t = 0;
	for ( ; t < divObj.childNodes.length ; t++) {
		if (typeof divObj.childNodes[t].tagName === "undefined") {
			continue; /* This is not an HTML dom element */
		}
		if (divObj.childNodes[t].tagName.match("TABLE") == null) {
			continue; /* not a table element */
		}
		if (divObj.childNodes[t].className.match("buttons") ) { /* mnabil : notice that this assumes that buttons table must come first */
			buttonsTable = divObj.childNodes[t];
			continue;
		}
		table = divObj.childNodes[t];
		
		try {
			if (undefined != $) {
				newlook = 1;
			}
		} catch (err) {;}
	
		var newRow;
		var newCell;
	
		table.cellspacing = "2";
		table.cellpadding = "2";
		
		newRow = table.rows[0];
		
		newCell = document.createElement('TH');
		newCell.className = newlook ? 'even' : 'odd';
		newCell.innerHTML = 'Statement';
		newRow.appendChild(newCell);
		
		newCell = document.createElement('TH');
		newCell.className = 'even';
		newCell.innerHTML = 'Hits';
		newRow.appendChild(newCell);
		
		newCell = document.createElement('TH');
		newCell.className = newlook ? 'even' : 'odd';
		newCell.innerHTML = 'Coverage';
		newRow.appendChild(newCell);
		
		var lastRowOdd = 0;
		if (newlook) {
			lastRowOdd = 0;
		}
		for (var r = 1; r < table.rows.length; r++) {
			var tmp;
			var excluded = 0;
			
			newRow = table.rows[r];
			newCell = document.createElement('TD');	
			// row class if existing
			tmp = newRow.getAttribute('cr');
			switch (tmp) {
				case 'c':
					newRow.className = 'covered'; break;
				case 'm':
					newRow.className = 'missing'; break;
				case 'e':
					newRow.className = 'excluded'; excluded = 1; show_excl_button = 1; break;	
				default:
					newRow.className = ''; break;
			}
			
			if (!excluded) {
				if (newlook) {
					newCell.className = g_cellClass[lastRowOdd];
				} else {
					newCell.className = "odd";
				}
			} else {
				if (newlook) {
					newCell.className = g_cellClassGrey[lastRowOdd];
				} else {
					newCell.className = "oddGrey";
				}
			}
			
			newCell.innerHTML = newRow.getAttribute('z');
	
			newRow.appendChild(newCell);
			
			newCell = document.createElement('TD');
			tmp = newRow.getAttribute('h');
			if (tmp) {
				if (!excluded) {
					if (newlook) {
						newCell.className = g_cellClassRight[lastRowOdd];
					} else {
						newCell.className = "even_r";
					}
				} else{
					if (newlook) {
						newCell.className = g_cellClassRGrey[lastRowOdd];
					} else {
						newCell.className = "even_rGrey";
					}
				}
				
				var hrefLnk = newRow.getAttribute('k');
				if (hrefLnk) {
					var lnktxt = "pertest.htm?bin=s" + hrefLnk + "&scope=" + testHitDataScopeId;
					var newElement = document.createElement('a');
					newElement.setAttribute('href', lnktxt);
					newElement.setAttribute('rel', 'popup 200 200');
					newElement.innerHTML = tmp;
					newCell.appendChild(newElement);
				} else {
					newCell.innerHTML = tmp;
				}
	
			} else {
				if (!excluded) {
					if (newlook) {
						newCell.className = g_cellClass[lastRowOdd];
					} else {
						newCell.className = "even";
					}
				} else {
					if (newlook) {
						newCell.className = g_cellClassGrey[lastRowOdd];
					} else {
						newCell.className = "evenGrey";
					}
				}
	
				newCell.align = "center";
				newCell.innerHTML = "--";
			}
			newRow.appendChild(newCell);
			
			newCell = document.createElement('TD');
			if (!excluded) {
				tmp = newRow.getAttribute('c');
				switch (tmp) {
					case 'g':
						newCell.className = 'green'; newCell.innerHTML = 'Covered'; break;
					case 'r':
						newCell.className = 'red'; newCell.innerHTML = 'ZERO'; break;
					default:
						newCell.className = ''; break;
				}
			} else {
				newCell.className = "grey"; newCell.innerHTML = 'Excluded';
			}
			newRow.appendChild(newCell);
			lastRowOdd = lastRowOdd ? 0 : 1;
		}
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

