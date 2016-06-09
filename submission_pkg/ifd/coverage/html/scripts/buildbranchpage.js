var g_cellClassRight = ["odd_r", "even_r"];
var g_cellClass      = ["odd",   "even"];

function b_createCell(row, type, classt, span, txt, lnk, tooltip, relAttribute, filterLabel, c_align, styleColor) {
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
	if (tooltip) {
		var att = document.createAttribute('title');
		att.value= tooltip;
		newCell.setAttributeNode(att);
	}	
	var newElement = document.createElement('a');
	if (lnk) {
		newElement.setAttribute("href", lnk);
	}
	if (relAttribute) {
		newElement.setAttribute("rel", relAttribute);
	}
	if(txt) {
		newElement.innerHTML = txt;
	}
	newCell.appendChild(newElement);

	if (filterLabel) {
		newCell.innerHTML = newCell.innerHTML + '&nbsp;';
		newElement = document.createElement('font');
		newElement.color = "#006699";
		newElement.innerHTML = "(Filtering Active)";
		newCell.appendChild(newElement);
	}
	if (styleColor) {
		newCell.style.color = styleColor;
	}
	
	row.appendChild(newCell);
	return;
};

/////////////////////////////////////////////////////////////////////////////////////
function buildBranchTables(divId)
{
	var show_excl_button = 0;
	
	var buttonsTable = 0;
	var t = 0;
	var divObj = document.getElementById(divId);
	
	for (; t < divObj.childNodes.length; t++) {
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
		if (table == 0) {
			/* can't find a table under the found div */
			continue; /* go next div */
		}
		

		
		var celltxt = 0;
		var classtype = 0;
		var lnktxt = 0;
		var relAtt = 0;
		var alignTxt = 0;
		var styleTxt = 0;
		var srcInfo = 0;
		var lastRowOdd = 0;
		var grey = 0;
		
		table.cellspacing = "2";
		table.cellpadding = "2";
		
		var newRow = table.rows[0];
		

		if (newRow.hasAttribute('z')) {
			celltxt = newRow.getAttribute('z').replace(">","&gt;").replace("<","&lt;");
		} else {
			celltxt = 0;
		}

		if (newRow.hasAttribute('hf')) {
			lnktxt = newRow.getAttribute('hf') + "#" + newRow.getAttribute('l');
		} else {
			lnktxt = 0;
		}

		if (newRow.hasAttribute('f')) {
			srcInfo = newRow.getAttribute('f') + ":" + newRow.getAttribute('l');
		} else {
			srcInfo = 0;
		}

		b_createCell(newRow, "TD", 0, 4, celltxt, lnktxt, srcInfo, 0, 0, 0, 0);
		
		tmp = newRow.getAttribute('c');
		switch (tmp) {
			case 'R':
				classtype = 'bgRed'; 			 						break;
			case 'Y':
				classtype = 'bgYellow'; 								break;
			case 'G':
				classtype = 'bgGreen'; 		 						break;
			case 'e':
				classtype = 'grey';  grey = 1; show_excl_button = 1;  break;
			default:
				classtype = ''; 				 						break;
		}
		if (grey == 0) {
			celltxt = newRow.getAttribute('p') + "%";
		} else {
			celltxt = 'Excluded';
			newRow.className = 'excluded';
		}
		b_createCell(newRow, "TD", classtype, 0, celltxt, 0, 0, 0, 0, 0, 0);
		
		newRow = table.rows[1];
		
		b_createCell(newRow, "TH", 'even', 2, 'Branch', 0, 0, 0, 0, 0, 0);
		b_createCell(newRow, "TH", 'even', 0, 'Source', 0, 0, 0, 0, 0, 0);
		b_createCell(newRow, "TH", 'even', 0, 'Hits', 0, 0, 0, 0, 0, 0);
		b_createCell(newRow, "TH", 'even', 0, 'Status', 0, 0, 0, 0, 0, 0);
		
		for (var r = 2; r < table.rows.length; r++) {
			var excluded = 0;
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
			classtype = 'invisible';
			celltxt = '&nbsp;';
			b_createCell(newRow, "TD", classtype, 0, celltxt, 0, 0, 0, 0, 0, 0);
			
			// t is branch type
			tmp = newRow.getAttribute('t');
			switch (tmp) {
				case 'I':
					celltxt = "IF"; break;
				case 'E':
					celltxt = "ELSE"; break;
				case 'T':
					celltxt = "TRUE"; break;
				case 'F':
					celltxt = "FALSE"; break;
				case 'A':
					celltxt = "ALL FALSE"; break;
				default:
					celltxt = "&nbsp;"; break;
			}
			b_createCell(newRow, "TD", g_cellClass[lastRowOdd], 0, celltxt, 0, 0, 0, 0, 0, 0);
			
			if (newRow.hasAttribute('f')) {
				srcInfo = newRow.getAttribute('f') + ":" + newRow.getAttribute('l');
			} else {
				srcInfo = 0;
			}

			if (newRow.hasAttribute('hf')) {
				lnktxt = newRow.getAttribute('hf') + "#" + newRow.getAttribute('l');
			} else {
				lnktxt = 0;
			}

			if (newRow.hasAttribute('z')) {
				celltxt = newRow.getAttribute('z').replace(">","&gt;").replace("<","&lt;");
			} else {
				celltxt = srcInfo;
			}

			b_createCell(newRow, "TD", g_cellClass[lastRowOdd], 0, celltxt, lnktxt, srcInfo, 0, 0, 0, 0);
			
			tmp = newRow.getAttribute('h');
			if (tmp) {
				classtype = g_cellClassRight[lastRowOdd];
				hrefLnk = newRow.getAttribute('k');
				if (hrefLnk) {
					lnktxt = "pertest.htm?bin=b" + hrefLnk + "&scope=" + testHitDataScopeId;
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
			}
			if (excluded) {
				styleTxt = "dimGrey";
			}
			b_createCell(newRow, "TD", classtype, 0, celltxt, lnktxt, 0, relAtt, 0, alignTxt, styleTxt);
			
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
			b_createCell(newRow, "TD", classtype, 0, celltxt, 0, 0, 0, 0, 0, 0);
			
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

