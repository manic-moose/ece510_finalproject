
var g_cellClass      = ["odd",   "even"];
var g_cellClassRight = ["odd_r", "even_r"];
var g_cellClassGrey = ["oddGrey", "evenGrey"];


//////////////////////////////////////////////////////////////////////////////////////////
function t_createCell(row, type, classt, rspan, cspan, txt, lnk, relAttribute, c_align, styleColor, titleText, preTxtVal, exTxt) {
	var newCell = document.createElement(type);
	var newElement;
	if (classt) {
		newCell.className = classt;
	}
	if (cspan > 1) {
		newCell.colSpan = cspan;
	}
	if (rspan > 1) {
		newCell.rowSpan = rspan;
	}
	if (c_align) {
		newCell.align = c_align;
	}
	if (styleColor) {
		newCell.style.color = styleColor;
	}
	if (titleText) {
		newCell.setAttribute("title", titleText);
	}
	if (lnk) {
		newElement = document.createElement('a');
		newElement.setAttribute("href", lnk);
		if (relAttribute) {
			newElement.setAttribute("rel", relAttribute);
		}
		if (titleText) {
			newElement.setAttribute("title", titleText);
		}
		newElement.innerHTML = txt;
		newCell.appendChild(newElement);
	} else {
		newCell.innerHTML = txt;
	}
	if (preTxtVal) {
		newCell.innerHTML = newCell.innerHTML + preTxtVal;
	}
	if (exTxt) {
		newCell.innerHTML = newCell.innerHTML + '&nbsp;' + exTxt;
	}
	row.appendChild(newCell);
	return;
};
function createToggleCell(row, type, toggleCount, h_count, exComment, sTxt, excluded, lastRowIsOdd) {
	var tmp = row.getAttribute(toggleCount);
	var alignTxt = styleTxt = 0;
	var classOfTheCell;
	var lnktxt;
	var relAtt;
	var celltxt;
	var exCommentTxt = 0;
	var preTxt = 0;
	if (tmp) {
		classOfTheCell = g_cellClassRight[lastRowIsOdd];
		lnktxt = "pertest.htm?bin=t" + tmp + "&scope=" + testHitDataScopeId;
		relAtt = 'popup 200 200';
		celltxt = row.getAttribute('h1');
	} else {
		var bin_excluded = 0;
		lnktxt = relAtt = 0;
		tmp = row.getAttribute(h_count);
		if (tmp) {
			classOfTheCell = g_cellClassRight[lastRowIsOdd];
			celltxt = tmp;
			if (tmp.charAt(0) == 'E') {
				bin_excluded = 1;
			}
		} else {
			classOfTheCell = g_cellClass[lastRowIsOdd];
			alignTxt = 'center';
			celltxt = '--';
		}
		if (excluded || bin_excluded) {
			styleTxt = "dimGrey";
			exCommentTxt = row.getAttribute(exComment);
			if (exCommentTxt) {
				preTxt = "&nbsp;+";
			}
		}
	}
	t_createCell(row, type, classOfTheCell, 0, 0, celltxt, lnktxt, relAtt, alignTxt, styleTxt, exCommentTxt, preTxt, sTxt);
	return;
};
//////////////////////////////////////////////////////////////////////////////////////////

function buildToggleTable (divId) {
	var show_excl_button = 0;
	var divObj = document.getElementById(divId);
	
	var table = 0;
	var buttonsTable = 0;
	var t=0;
	for (; t < divObj.childNodes.length ; t++) {
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
	
		table = divObj.childNodes[t];
		
		// adjust the table attributes
		table.cellspacing = "2";
		table.cellpadding = "2";
	
		/****************************** Start of row 0 ***********************************/
		// create the table header cells and append them
		t_createCell(table.rows[0], 'TH', 'odd', '2', '2', 'Signal / Value', 0, 0, 0, 0, 0, 0, 0);
		t_createCell(table.rows[0], 'TH', 'odd',   0, '6',           'Hits', 0, 0, 0, 0, 0, 0, 0);
		t_createCell(table.rows[0], 'TH', 'odd', '2',   0,        'ExtMode', 0, 0, 0, 0, 0, 0, 0);
		t_createCell(table.rows[0], 'TH', 'odd', '2',   0,         'Status', 0, 0, 0, 0, 0, 0, 0);
		/****************************** End of row 0 ***********************************/
		t_createCell(table.rows[1], 'TH', 'even',  0,   0,         '0L->1H', 0, 0, 0, 0, 0, 0, 0);
		t_createCell(table.rows[1], 'TH', 'even',  0,   0,         '1H->0L', 0, 0, 0, 0, 0, 0, 0);
		t_createCell(table.rows[1], 'TH', 'even',  0,   0,          '0L->Z', 0, 0, 0, 0, 0, 0, 0);
		t_createCell(table.rows[1], 'TH', 'even',  0,   0,          'Z->1H', 0, 0, 0, 0, 0, 0, 0);
		t_createCell(table.rows[1], 'TH', 'even',  0,   0,          '1H->Z', 0, 0, 0, 0, 0, 0, 0);
		t_createCell(table.rows[1], 'TH', 'even',  0,   0,          'Z->0L', 0, 0, 0, 0, 0, 0, 0);
		/****************************** End of row 1 ***********************************/
		
		var lastRowOdd = 0;
		// Loop on the rows of the table
		for (var r = 2; r < table.rows.length; r++) {
			var tmp;
			var excluded = 0;
			var columnSpan;
			var classtype;
			var celltxt;
			var newRow = table.rows[r];
			
			tmp = newRow.getAttribute('s');
			if (tmp)
				columnSpan = tmp;
			else 
				columnSpan = 0;
			
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
	
			tmp = newRow.getAttribute('st');
			if (tmp) {
				/* colSpan is 1 */
				/* simple toggle */
				t_createCell(newRow, 'TD', 'invisible', 0, columnSpan, '&nbsp;', 0, 0, 0, 0, 0, 0, 0);
				
				t_createCell(newRow, 'TD', (excluded == 1)? g_cellClassGrey[lastRowOdd] : g_cellClass[lastRowOdd], 0, 0, newRow.getAttribute('z'), 0, 0, 0, 0, 0, 0, 0);
			} else {
				var preTxt;
				var titleTxt;
				var lnktxt;
				
				classtype = g_cellClass[lastRowOdd];
				tmp = newRow.getAttribute('lnk');
				if (tmp) {
					lnktxt = tmp;
					tmp = newRow.getAttribute('t');
					celltxt = newRow.getAttribute('z');
					if (tmp) {
						// in case there is a text in the cell i.e  [alias]
						titleTxt = tmp;
						preTxt = '&nbsp;[alias]';
					} else {
						preTxt = titleTxt = 0;
					}
				} else {
					preTxt = lnktxt = 0;
					tmp = newRow.getAttribute('t');
					if (tmp) {
						// in case there is a text in the cell i.e  [alias]
						celltxt = newRow.getAttribute('z') + '&nbsp;[alias]';
						titleTxt = tmp;
					} else {
						celltxt = newRow.getAttribute('z');
						titleTxt = 0;
					}		
				}
				if (excluded == 1) {
					classtype = g_cellClassGrey[lastRowOdd];
					tmp = newRow.getAttribute('ec');
					if (tmp) {
						if (preTxt) {
 							preTxt = preTxt + "&nbsp;+";
						} else {
							preTxt = "&nbsp;+";
						}
						if (titleTxt) {
							titleTxt = "Canonical Name: " + titleTxt + " \nExclusion Comment: \n" + tmp;
						} else {
							titleTxt = tmp;
						}
					}
				}
				t_createCell(newRow, 'TD', classtype, 0, columnSpan, celltxt, lnktxt, 0, 0, 0, titleTxt, preTxt, 0);
			}
		/////////////////////////////////////////////////////////////////////////////////////////////////		
			if (columnSpan != 9) { /* i.e. columnSpan == 2 or 1 */
				createToggleCell(newRow, 'TD', 'LH', 'h1', 'ec1', 0, excluded, lastRowOdd);
				createToggleCell(newRow, 'TD', 'HL', 'h2', 'ec2', 0, excluded, lastRowOdd);
				createToggleCell(newRow, 'TD', 'LZ', 'h3', 'ec3', newRow.getAttribute('s1'), excluded, lastRowOdd);
				createToggleCell(newRow, 'TD', 'ZH', 'h4', 'ec4', newRow.getAttribute('s2'), excluded, lastRowOdd);
				createToggleCell(newRow, 'TD', 'HZ', 'h5', 'ec5', newRow.getAttribute('s3'), excluded, lastRowOdd);
				createToggleCell(newRow, 'TD', 'ZL', 'h6', 'ec6', newRow.getAttribute('s4'), excluded, lastRowOdd);
	
				tmp = newRow.getAttribute('em'); // External Mode
				if (tmp) {
					celltxt = tmp;
				} else {
					celltxt = '--';
				}
				if (!newRow.getAttribute('st')) {
					classtype = g_cellClassRight[lastRowOdd];
				} else {
					classtype = g_cellClass[lastRowOdd];
				}
				t_createCell(newRow, 'TD', classtype, 0, 0, celltxt, 0, 0, 0, excluded ? "dimGrey" : 0, 0, 0, 0);
			}
			
			if (excluded == 0) {
				tmp = newRow.getAttribute('c');
				switch (tmp) {
					case 'R':
						classtype = 'bgRed';    celltxt = newRow.getAttribute('p') + "%"; break;
					case 'Y':
						classtype = 'bgYellow'; celltxt = newRow.getAttribute('p') + "%"; break;
					case 'G':
						classtype = 'bgGreen';  celltxt = newRow.getAttribute('p') + "%"; break;
					case 'g':
						classtype = 'green';    celltxt = 'Covered'; 						break;
					case 'r':
						classtype = 'red';      celltxt = 'ZERO'; 						break;
					default:
						classtype = ''; break;
				}
			} else {
				classtype = 'grey'; celltxt = 'Excluded';
			}
			t_createCell(newRow, 'TD', classtype, 0, 0, celltxt, 0, 0, 0, 0, 0, 0, 0);
			/* end of Row */
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

