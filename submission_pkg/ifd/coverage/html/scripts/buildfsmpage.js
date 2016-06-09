var g_cellClass      = ["odd"   , "even"];
var g_cellClassRight = ["odd_r" , "even_r"];

//////////////////////////////////////////////////////////////////////////////////////////
function f_createCell(row, type, classt, span, txt, lnk, relAttribute, c_align, styleColor) {
	var newCell = document.createElement(type);
	if (classt) {
		newCell.className = classt;
	}
	if (span > 1) {
		newCell.colSpan = span;
	}
	if (c_align) {
		newCell.align = c_align;
	}
	if (styleColor) {
		newCell.style.color = styleColor;
	}
	if (lnk) {
		var newElement = document.createElement('a');
		newElement.setAttribute("href", lnk);
		if (relAttribute) {
			newElement.setAttribute("rel", relAttribute);
		}
		newElement.innerHTML = txt;
		newCell.appendChild(newElement);
	} else {
		newCell.innerHTML = txt;
	}
	
	row.appendChild(newCell);
	return;
};
//////////////////////////////////////////////////////////////////////////////////////////
function buildFsmTables(divId) {
	var show_excl_button = 0;
	
	var buttonsTable = 0;
	var t = 0;
	var divObj = document.getElementById(divId);
	for (; t < divObj.childNodes.length ; t++) {
		var divTableHolder = 0;
		var table = 0;
		
		if (typeof divObj.childNodes[t].tagName === "undefined") {
			continue; /* This is not an HTML dom element */
		}
		if (divObj.childNodes[t].tagName.match("TABLE")) {
			if (divObj.childNodes[t].className.match("buttons") ) {
				buttonsTable = divObj.childNodes[t];
			}
			continue;
		}
		if (divObj.childNodes[t].tagName.match("DIV") == null) {
			continue; /* not a div element */
		}
		divTableHolder = divObj.childNodes[t];
		
		for (var j = 0; j < divTableHolder.childNodes.length ; j++) {
			if (typeof divTableHolder.childNodes[j].tagName === "undefined") {
				continue;
			}
			if (divTableHolder.childNodes[j].tagName.match("TABLE") == null) {
				continue;
			}
			table = divTableHolder.childNodes[j];
			break;
		}
		if (table == 0) { /* mnabil : assuming we have a single table per the div */
			/* can't find a table under the found div */
			continue; /* go next div */
		}

		var grey = 0;
		var newRow = 0;
		var classtype = 0;
		var celltxt = 0;
		var tmp = 0;
		
		table.cellspacing = "2";
		table.cellpadding = "2";
		
		newRow = table.rows[0];

		if(!pa_scope){
			celltxt = "FSM: ";
		}
		
		celltxt = newRow.getAttribute('z');
		f_createCell(newRow, 'TD', 0, "3", celltxt, newRow.getAttribute('lnk'), 0, 0, 0);

		tmp = newRow.getAttribute('c');
		switch (tmp) {
			case 'R':
				classtype = 'bgRed'; break;
			case 'Y':
				classtype = 'bgYellow'; break;
			case 'G':
				classtype = 'bgGreen'; break;
			case 'e':
				classtype = 'grey';  grey = 1; show_excl_button = 1;  break;			
			default:
				classtype = ''; break;
		}
		if (grey == 0) {
			celltxt = newRow.getAttribute('p') + "%";
		} else {
			celltxt = 'Excluded';
			newRow.className = 'excluded';
		}
		f_createCell(newRow, 'TD', classtype, 0, celltxt, 0, 0, 0, 0);
		
		newRow = table.rows[1];
		
		f_createCell(newRow, 'TH', 'even', "2", 'States / Transitions', 0, 0, 0, 0);
		f_createCell(newRow, 'TH', 'even',   0,                 'Hits', 0, 0, 0, 0);
		f_createCell(newRow, 'TH', 'even',   0,               'Status', 0, 0, 0, 0);

		var lastRowOdd = 0;
		// loop on the rest of the rows	
		for (var r = 2; r < table.rows.length; r++) {
			var excluded = 0;
			var alignTxt = 0;
			var columnSpan = 0;
			var lnktxt = 0;
			var relAtt = 0;
			
			newRow = table.rows[r];

			// row class if existing
			tmp = newRow.getAttribute('cr');
			switch (tmp) {
				case 'c':
					newRow.className = 'covered'; break;
				case 'm':
					newRow.className = 'missing'; break;
				case 'e': //excluded
					excluded = 1; newRow.className = 'excluded'; show_excl_button = 1; break;
				default:
					newRow.className = ''; break;
			}

			if (newRow.getAttribute('s')) {
				classtype = g_cellClass[lastRowOdd];
				columnSpan = "2";
				celltxt = 'State: ' + newRow.getAttribute('z');
			} else {
				f_createCell(newRow, 'TD', 'invisible', 0, '&nbsp;', 0, 0, 0, 0);
				
				classtype = g_cellClass[lastRowOdd];
				columnSpan = 0;
				celltxt = 'Trans: ' + newRow.getAttribute('z');
			}
			f_createCell(newRow, 'TD', classtype, columnSpan, celltxt, 0, 0, 0, 0);

			tmp = newRow.getAttribute('h');
			if (tmp) {
				classtype = g_cellClassRight[lastRowOdd];
				var hrefLnk = newRow.getAttribute('lnk');
				if (hrefLnk) {
					lnktxt = "pertest.htm?bin=f" + hrefLnk + "&scope=" + testHitDataScopeId;
					relAtt = 'popup 200 200';
				} else {
					lnktxt = relAtt = 0;
				}
				celltxt = tmp;
				alignTxt = 0;
			} else {
				classtype = g_cellClass[lastRowOdd];
				alignTxt = "center";
				celltxt = "--";
				lnktxt = relAtt = 0;
			}
			f_createCell(newRow, 'TD', classtype, 0, celltxt, lnktxt, relAtt, alignTxt, excluded ? "dimGrey": 0);

			if (excluded == 0) {
				tmp = newRow.getAttribute('c');
				switch (tmp) {
					case 'g':
						classtype = 'green'; celltxt = 'Covered'; break;
					case 'r':
						classtype = 'red'; celltxt = 'ZERO'; break;
					default:
						classtype = ''; break;
				}
			} else {
				classtype = 'grey'; celltxt = 'Excluded';
			}
			f_createCell(newRow, 'TD', classtype, 0, celltxt, 0, 0, 0, 0);
			lastRowOdd = lastRowOdd ? 0 : 1;
		}
	}
	if (show_excl_button == 1) {
		if (buttonsTable) {
			var newCell = document.createElement('TD');
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
