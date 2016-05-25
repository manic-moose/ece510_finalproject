var g_cellClass      = ["odd",   "even"];
var g_cellClassRight = ["odd_r", "even_r"];
var g_cellClassRGrey = ["odd_rGrey", "even_rGrey"];

function AssertionsPageSharedVariables()
{
	/* I have created this object to get rid of all global variables in assertions
	 * javascript file.
	 * I have to do so while merging all coverage types in a single file.
	 * 
	 * We need to rewrite this code in a better way.
	 * */
	this.lnktxt = 0;
	this.celltxt = 0;
	this.relAtt = 0;
}
	
/////////////////////////////////////////////////////////////////////////////////////
/* creats cell and add it to row.*/
function a_createCell(row, type, classt, span, txt, lnk, relAttribute, filterLabel, c_align) {
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
	if (filterLabel) {
		newCell.innerHTML = newCell.innerHTML + '&nbsp;';
		var newElement = document.createElement('font');
		newElement.color = "#006699";
		newElement.innerHTML = "(Filtering Active)";
		newCell.appendChild(newElement);
	}
	
	row.appendChild(newCell);
	return;
};

function createAssertCell(row, tableCellType, countType, type, h_number, isexcluded, sharedVarObj, lastRowIsOdd) {
	var tmp;
	var classtype;
	
	tmp = row.getAttribute(countType);
	if (tmp) {
		switch (tmp) {
			case 'Gr':
				classtype = 'bgGreen_r'; break;
			case 'Rr':
				classtype = 'bgRed_r'; break;
			case 'er':
				classtype = g_cellClassRight[lastRowIsOdd];
				break;
			case 'or':
				classtype = g_cellClassRight[lastRowIsOdd];
				break;
			default:
				classtype = ''; break;
		}
		tmp = row.getAttribute(type);
		if (tmp) {
			sharedVarObj.lnktxt = "pertest.htm?bin=a" + tmp + "&scope=" + testHitDataScopeId;
			sharedVarObj.relAtt = 'popup 200 200';
		} else {
			sharedVarObj.lnktxt = 0;
			sharedVarObj.relAtt = 0;
		}
		sharedVarObj.celltxt = row.getAttribute('h' + h_number);
	} else {
		classtype = g_cellClassRight[lastRowIsOdd];
		sharedVarObj.celltxt = '-';
	}
	if (isexcluded) {
		// if excluded override the class name
		classtype = g_cellClassRGrey[lastRowIsOdd];
	}
	a_createCell(row, tableCellType, classtype, 0, sharedVarObj.celltxt, sharedVarObj.lnktxt, sharedVarObj.relAtt, 0, 0);	
};

function createNormalAssertCell(row, tableCellType, countType, h_number, isexcluded, sharedVarObj, lastRowIsOdd) {
	var classtype = g_cellClassRight[lastRowIsOdd];

	var tmp2 = row.getAttribute('h' + h_number);
	if (tmp2) {
		var tmp;
		tmp = row.getAttribute(countType);
		if (tmp) {
			var hrefLnk = tmp.match(/^([^$]*)\$([^$]*)$/i);
			if (hrefLnk && hrefLnk.length == 3) {
				sharedVarObj.lnktxt = "pertest.htm?bin=a" + hrefLnk[1] + "&scope=" + hrefLnk[2];
			} else {
				sharedVarObj.lnktxt = tmp;
			}
			sharedVarObj.relAtt = 'popup 200 200';
		} else {
			sharedVarObj.lnktxt = 0;
			sharedVarObj.relAtt = 0;
		}
		sharedVarObj.celltxt = tmp2;
	} else {
		sharedVarObj.celltxt = '-';
	}
	if (isexcluded) {
		// if excluded override the class name
		classtype = g_cellClassRGrey[lastRowIsOdd];
	}
	a_createCell(row, tableCellType, classtype, 0, sharedVarObj.celltxt, sharedVarObj.lnktxt, sharedVarObj.relAtt, 0, 0);
};
/////////////////////////////////////////////////////////////////////////////////////

function buildAssertionsTables(divId) {
	var divObj = document.getElementById(divId);
	var show_excl_button = 0;
	var aVarObj = new AssertionsPageSharedVariables();
	
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
		
		table = divObj.childNodes[t];
		table.cellspacing = "2";
		table.cellpadding = "2";
		
		var newRow = table.rows[0];
		
		a_createCell(newRow, "TH", 'even', 0,   'Assertions', 0, 0, 0, 0);
		a_createCell(newRow, "TH", 'even', 0,        'Failure Count', 0, 0, 0, 0);
		a_createCell(newRow, "TH", 'even', 0,        'Pass Count', 0, 0, 0, 0);
		a_createCell(newRow, "TH", 'even', 0,    'Attempt Count', 0, 0, 0, 0);
		a_createCell(newRow, "TH", 'even', 0,     'Vacuous Count', 0, 0, 0, 0);
		a_createCell(newRow, "TH", 'even', 0,    'Disable Count', 0, 0, 0, 0);
		a_createCell(newRow, "TH", 'even', 0,      'Active Count', 0, 0, 0, 0);
		a_createCell(newRow, "TH", 'even', 0, 'Peak Active Count', 0, 0, 0, 0);
		a_createCell(newRow, "TH", 'even', 0,      'Status', 0, 0, 0, 0);

		var lastRowOdd = 0;
		
		// loop on the rest of the rows	
		for (var r = 1; r < table.rows.length; r++) {
			var tmp;
			var excluded = 0;
			
			newRow = table.rows[r];

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
			
			classtype = g_cellClass[lastRowOdd];
			aVarObj.lnktxt = newRow.getAttribute('lnk'); 
			
			name = newRow.getAttribute('z');
			if (name) {
				if (name.match(/^<.*>$/)) {
					aVarObj.celltxt = name.replace(">","&gt;").replace("<","&lt;");				
				} else {
					aVarObj.celltxt = name;
				}
			}
			a_createCell(newRow, "TD", classtype, 0, aVarObj.celltxt, aVarObj.lnktxt, 0, 0, 0);
			
			createAssertCell(newRow, "TD", 'fc', 'F', 1, excluded, aVarObj, lastRowOdd);
			createAssertCell(newRow, "TD", 'pc', 'P', 2, excluded, aVarObj, lastRowOdd);		

			createNormalAssertCell(newRow, "TD", 'At', 3, excluded, aVarObj, lastRowOdd);
			createNormalAssertCell(newRow, "TD",  'V', 4, excluded, aVarObj, lastRowOdd);
			createNormalAssertCell(newRow, "TD",  'D', 5, excluded, aVarObj, lastRowOdd);
			createNormalAssertCell(newRow, "TD",  'A', 6, excluded, aVarObj, lastRowOdd);
			createNormalAssertCell(newRow, "TD", 'PA', 7, excluded, aVarObj, lastRowOdd);
			
			if (excluded == 0) {
				tmp = newRow.getAttribute('c');
				switch (tmp) {
					case 'F':
						classtype = 'red';   aVarObj.celltxt = "Failed"; break;
					case 'Z':
						classtype = 'red';   aVarObj.celltxt = "ZERO"; break;
					case 'g':
						classtype = 'green'; aVarObj.celltxt = "Covered"; break;
					default:
						classtype = ''; break;
				}
			} else {
				classtype = 'grey'; aVarObj.celltxt = "Excluded";
			}
			a_createCell(newRow, "TD", classtype, 0, aVarObj.celltxt, 0, 0, 0, 0);

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

