var g_cellClass      = ["odd",   "even"];
var g_cellClassRight = ["odd_r", "even_r"];



//////////////////////////////////////////////////////////////////////////////////////////
function d_createCell(row, type, classt, span, txt, lnk, relAttribute, c_align, styleColor) {
	var newCell = document.createElement(type);
	newCell.className = classt;
	if (span > 1) {
		newCell.colSpan = span;
	}
	if (c_align) {
		newCell.align = c_align;
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
	if (styleColor) {
		newCell.style.color = styleColor;
	}
	
	row.appendChild(newCell);
	return;
};


//////////////////////////////////////////////////////////////////////////////////////////
function buildDirTable(divId) {
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
	
		table.cellspacing = "2";
		table.cellpadding = "2";
		
		var newRow = table.rows[0];
		
		d_createCell(newRow, 'TH', 'even', 0, 'Cover Directive', 0, 0, 'left', 0);
		d_createCell(newRow, 'TH', 'even', 0, 'Hits', 0, 0, 0, 0);
		d_createCell(newRow, 'TH', 'even', 0, 'Status', 0, 0, 0, 0);
	
		var lastRowOdd = 0;	
		// loop on the rest of the rows	
		for (var r = 1; r < table.rows.length; r++) {
			var excluded = 0;
			var classtype = 0;
			var lnktxt = 0;
			var tmp = 0;
			var celltxt = 0;
			
			newRow = table.rows[r];
	
			// row class if existing
			tmp = newRow.getAttribute('cr');
			switch (tmp) {
				case 'c':
					newRow.className = 'covered'; break;
				case 'm':
					newRow.className = 'missing'; break;
				case 'n':
					newRow.className = 'neutral'; break;
				case 'e': //excluded
					excluded = 1; newRow.className = 'excluded'; show_excl_button = 1; break;	
				default:
					newRow.className = ''; break;
			}
			
			lnktxt = newRow.getAttribute('lnk');
			name = newRow.getAttribute('z');
			if (name) {
				if (name.match(/^<.*>$/)) {
					celltxt = name.replace(">","&gt;").replace("<","&lt;");				
				} else {
					celltxt = name;
				}
			}
			d_createCell(newRow, 'TD', g_cellClass[lastRowOdd], 0, celltxt, lnktxt, 0, 0, 0);
			
			tmp = newRow.getAttribute('h');
			if (tmp) {
				var styleTxt = 0;
				var relAtt = 0;
				var alignTxt = 0;
				var hrefLnk = newRow.getAttribute('k');
				if (hrefLnk) {
					lnktxt = "pertest.htm?bin=d" + hrefLnk + "&scope=" + testHitDataScopeId;
					relAtt = 'popup 200 200';
				} else {
					lnktxt = relAtt = 0;
				}
				celltxt = tmp;
				d_createCell(newRow, 'TD', g_cellClassRight[lastRowOdd], 0, celltxt, lnktxt, relAtt, 0, excluded ? "dimGrey" : 0);
	
				if (excluded == 0) {
					tmp = newRow.getAttribute('c');
					switch (tmp) {
						case 'r':
							classtype = 'red';   celltxt = "ZERO"; break;
						case 'g':
							classtype = 'green'; celltxt = "Covered"; break;
						default:
							classtype = ''; break;
					}
				} else {
					classtype = 'grey'; celltxt = 'Excluded';
				}
				alignTxt = styleTxt = 0;
			} else {
				d_createCell(newRow, 'TD', g_cellClass[lastRowOdd], 0, "--", 0, 0, "center", excluded ? "dimGrey" : 0);
	
				classtype = g_cellClass[lastRowOdd];
				alignTxt = "center";
				celltxt = "--";
				if (excluded) {
					styleTxt = "dimGrey";
				} else {
					styleTxt = 0;
				}
			}
			d_createCell(newRow, 'TD', classtype, 0, celltxt, 0, 0, alignTxt, styleTxt);
			lastRowOdd = lastRowOdd ? 0 : 1;
		}
	}
	if (show_excl_button == 1) {
		if (buttonsTable.className.match('buttons')) {
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

