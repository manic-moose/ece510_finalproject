
//////////////////////////////////////////////////////////////////////////////////////////
function ec_createCell(row, type, classt, cspan, rspan, txt, preTxtVal, lnk, relAttribute, c_align, wid) {
	var newCell = document.createElement(type);
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
	if (wid) {
		newCell.width = wid;
	}
	if (lnk) {
		if (preTxtVal) {
			newCell.innerHTML = preTxtVal;
		}
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
function buildExprCondTables(divId)
{
	var show_excl_button = 0;
	var buttonsTable = 0;
	var t = 0;
	var divObj = document.getElementById(divId);
	
	for (; t < divObj.childNodes.length ; t++ ) {
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
		
		var excluded_row = 0;
		var celltxt = 0;
		var preTxt = 0;
		var classtype = 0;
		var lnktxt = 0;
		var relAtt = 0;
		var hrefLnk = 0;
		var lastClassOdd = 0;
		var exFec = 0;
		var isDeepFec = 0;
		var tmp;
		
		table.cellspacing = "2";
		table.cellpadding = "2";
		
		var newRow = table.rows[0];
		
		tmp = newRow.getAttribute('x'); // x for text
		switch (tmp) {
			case 'FC':
				celltxt = 'FEC Condition:&nbsp;';  break;
			case 'FE':
				celltxt = 'FEC Expression:&nbsp;'; break;
			case 'UC':
				celltxt = 'UDP Condition:&nbsp;';  break;
			case 'UE':
				celltxt = 'UDP Expression:&nbsp;'; break;
			default:
				celltxt = '[Oops...]:&nbsp;';      break;
		}

		tmp = newRow.getAttribute('lnk');
		if (tmp) {
			lnktxt = tmp;
			preTxt = celltxt;
			name = newRow.getAttribute('z');
			if (name) {
				if (name.match(/^<.*>$/)) {
					celltxt = name.replace(">","&gt;").replace("<","&lt;");				
				} else {
					celltxt = name;
				}
			}
		} else {
			preTxt = 0;
			celltxt = celltxt + newRow.getAttribute('z');
		}

		var tmp2 = newRow.getAttribute('u');
		if (tmp2)
			celltxt = celltxt + "<br> Canonical Expression:&nbsp; " + tmp2;

		ec_createCell(newRow, 'TH', 0, newRow.getAttribute('s'), 0, celltxt, preTxt, lnktxt, 0, 'left', 0);
		
		tmp = newRow.getAttribute('c');
		switch (tmp) {
			case 'R':
				classtype = 'bgRed'; break;
			case 'Y':
				classtype = 'bgYellow'; break;
			case 'G':
				classtype = 'bgGreen'; break;
			case 'e':
				classtype = 'grey'; excluded_row = 1 ; show_excl_button = 1; break;
			default:
				classtype = ''; break;
		}
		if (!excluded_row) {
			celltxt = newRow.getAttribute('p') + "%";
		} else {
			celltxt = "Excluded";
			newRow.cells[0].className = 'grey';
		}
		ec_createCell(newRow, 'TD', classtype, 0, 0, celltxt, 0, 0, 0, 0, 0);

		tmp = newRow.getAttribute('d');
		isDeepFec = tmp;

		tmp = newRow.getAttribute('F'); // F is FEC 
		exFec = tmp;
		if (tmp) {
			/**************************************************************************/
			newRow = table.rows[1];

			ec_createCell(newRow, 'TH', 'even', tmp, 0,             "Input Term", 0, 0, 0, 0, 0);
			ec_createCell(newRow, 'TH', 'even', tmp, 0,                "Covered", 0, 0, 0, 0, 0);
			ec_createCell(newRow, 'TH', 'even',   0, 0, "Reason For No Coverage", 0, 0, 0, 0, 0);
			ec_createCell(newRow, 'TH', 'even',   0, 0,                   "Hint", 0, 0, 0, 0, 0);
			
			var r = 2;
			for (; r < table.rows.length; r++) {
				var excluded = 0;
				newRow = table.rows[r];
				tmp = newRow.getAttribute('z');
				if (!tmp) {
					break;
				}
				ec_createCell(newRow, 'TD', 'even', exFec, 0, tmp, 0, 0, 0, 'center', 0);
				
				tmp = newRow.getAttribute('c');
				switch (tmp) {
					case 'g':
						classtype = 'green'; celltxt = 'Yes'; break;
					case 'r':
						classtype = 'red'; celltxt = 'No'; break;
					case 'e':
						classtype = 'grey'; excluded = 1; show_excl_button = 1; celltxt = 'Excluded'; newRow.cells[0].className = 'evenGrey'; break;
					default:
						classtype = ''; break;
				}
				ec_createCell(newRow, 'TD', classtype, exFec, 0, celltxt, 0, 0, 0, 'center', 0);
				
				if (!excluded) {
					celltxt = newRow.getAttribute('r'); // r is reason
				}
				ec_createCell(newRow, 'TD', 'even', 0, 0, celltxt, 0, 0, 0, 'center', 0);
				
				if (!excluded) {
					celltxt = newRow.getAttribute('i'); // i is hint
				}
				ec_createCell(newRow, 'TD', 'even', 0, 0, celltxt, 0, 0, 0, 'center', 0);
			}
			newRow = table.rows[r];
			if (exFec == 2) {
				/* extended fec */
				ec_createCell(newRow, 'TH', 'even', 0, 0, "Rows", 0, 0, 0, 0, 0);
				ec_createCell(newRow, 'TH', 'even', 0, 0, "FEC Target", 0, 0, 0, 0, 0);
				ec_createCell(newRow, 'TH', 'even', 0, 0, "Hits (->0)", 0, 0, 0, 0, 0);
				ec_createCell(newRow, 'TH', 'even', 0, 0, "Hits (->1)", 0, 0, 0, 0, 0);
				if (isDeepFec == 1) {
					ec_createCell(newRow, 'TH', 'even', 0, 0, "Matching Input Patterns (->0)", 0, 0, 0, 0, 0);
					ec_createCell(newRow, 'TH', 'even', 0, 0, "Matching Input Patterns (->1)", 0, 0, 0, 0, 0);
				} else {
					ec_createCell(newRow, 'TH', 'even', 2, 0, "Non-Masking Condition(s)", 0, 0, 0, 0, 0);
				}
				/***************************   end of table head  ***************************************/
				r++;
				for (; r < table.rows.length; r++) {
					var excluded = 0;
					newRow = table.rows[r];

					ec_createCell(newRow, 'TD', 'even', 0, 0, "Row&nbsp;" + newRow.getAttribute('n'), 0, 0, 0, "center", 0);
					ec_createCell(newRow, 'TD', 'even', 0, 0, newRow.getAttribute('z'), 0, 0, 0, "center", 0);
					
					tmp = newRow.getAttribute('h1');
					classtype = 'even';
					if (tmp) {
						hrefLnk = newRow.getAttribute('k1');
						if (hrefLnk) {
							lnktxt = "pertest.htm?bin=" + newRow.getAttribute('t') + hrefLnk + "&scope=" + testHitDataScopeId;
							relAtt = 'popup 200 200';
						} else {
							relAtt = lnktxt = 0;
							if ((tmp == "E-Hit") || (tmp == "E-Miss")) {
								// excluded row
								excluded = 1;
								newRow.cells[0].className = 'evenGrey';
								newRow.cells[1].className = 'evenGrey';
								classtype = 'evenGrey';
							}
						}
						celltxt = tmp;
					} else {
						relAtt = lnktxt = 0;
						celltxt = "&nbsp;-&nbsp;";
					}
					ec_createCell(newRow, 'TD', classtype, 0, 0, celltxt, 0, lnktxt, relAtt, "center", 0);
					
					classtype = 'even';
					tmp = newRow.getAttribute('h2');
					if (tmp) {
						hrefLnk = newRow.getAttribute('k2');
						if (hrefLnk) {
							lnktxt = "pertest.htm?bin=" + newRow.getAttribute('t') + hrefLnk + "&scope=" + testHitDataScopeId;
							relAtt = 'popup 200 200';
						} else {
							lnktxt = relAtt = 0;
							if ((tmp == "E-Hit") || (tmp == "E-Miss")) {
								// excluded row
								excluded = 1;
								newRow.cells[0].className = 'evenGrey';
								newRow.cells[1].className = 'evenGrey';
								classtype = 'evenGrey';
							}
						}
						celltxt = tmp;
					} else {
						lnktxt = relAtt = 0;
						celltxt = "&nbsp;-&nbsp;";
					}
					ec_createCell(newRow, 'TD', classtype, 0, 0, celltxt, 0, lnktxt, relAtt, "center", 0);
					
					if (!excluded) {
						classtype = 'even';
					} else {
						classtype = 'evenGrey';
					}
					ec_createCell(newRow, 'TD', classtype, (isDeepFec == 1) ? 0 : 2, 0, "&nbsp;" + newRow.getAttribute('c1') + "&nbsp;", 0, 0, 0, "center", 0);
					
					if (isDeepFec == 1) {
						if (!excluded) {
							classtype = 'even';
						} else {
							classtype = 'evenGrey';
						}
						ec_createCell(newRow, 'TD', classtype, 0, 0, "&nbsp;" + newRow.getAttribute('c2') + "&nbsp;", 0, 0, 0, "center", 0);
					}
				}
			} else {
				/* fec */
				ec_createCell(newRow, 'TH', 'even', 0, 0,                    "Rows", 0, 0, 0, 0, 0);
				ec_createCell(newRow, 'TH', 'even', 0, 0,              "FEC Target", 0, 0, 0, 0, 0);
				ec_createCell(newRow, 'TH', 'even', 0, 0,                    "Hits", 0, 0, 0, 0, 0);
				if (isDeepFec == 1)
					ec_createCell(newRow, 'TH', 'even', 0, 0, "Matching Input Patterns", 0, 0, 0, 0, 0);
				else
					ec_createCell(newRow, 'TH', 'even', 0, 0, "Non-Masking Condition(s)", 0, 0, 0, 0, 0);
				/***************************   end of table head  ***************************************/
				r++;
				for (; r < table.rows.length; r++) {
					var excluded = 0;
					
					newRow = table.rows[r];

					ec_createCell(newRow, 'TD', 'even', 0, 0, "Row&nbsp;" + newRow.getAttribute('n'), 0, 0, 0, "center", 0);
					ec_createCell(newRow, 'TD', 'even', 0, 0,               newRow.getAttribute('z'), 0, 0, 0, "center", 0);
					
					classtype = 'even';
					tmp = newRow.getAttribute('h1');
					if (tmp) {
						hrefLnk = newRow.getAttribute('k1')
						if (hrefLnk) {
							lnktxt = "pertest.htm?bin=" + newRow.getAttribute('t') + hrefLnk + "&scope=" + testHitDataScopeId;
							relAtt = 'popup 200 200';
						} else {
							relAtt = lnktxt = 0;
							if ((tmp == "E-Hit") || (tmp == "E-Miss")) {
								// excluded row
								excluded = 1;
								newRow.cells[0].className = 'evenGrey';
								newRow.cells[1].className = 'evenGrey';
								classtype = 'evenGrey';
							}
						}
						celltxt = tmp;
					} else {
						relAtt = lnktxt = 0;
						celltxt = "&nbsp;-&nbsp;";
					}
					ec_createCell(newRow, 'TD', classtype, 0, 0, celltxt, 0, lnktxt, relAtt, "center", 0);
					
					if (!excluded) {
						classtype = 'even';
					} else {
						classtype = 'evenGrey';
					}
					ec_createCell(newRow, 'TD', classtype, 0, 0, "&nbsp;" + newRow.getAttribute('c1') + "&nbsp;", 0, 0, 0, "center", 0);
				}
			}
		} else {
			var r = 1;
			lastClassOdd = true; // is true to start the series with 'even'
			for (; r < (table.rows.length) - 1; r++) { // I added the '-1' because the last row is processed outside the loop
				newRow = table.rows[r];
				tmp = newRow.getAttribute('r'); // r is rowspan
				if (!tmp) {
					break;
				}

				if (lastClassOdd)
					classtype = 'even';
				else
					classtype = 'odd';
				
				// commented this line to use the same class for both cells
				//lastClassOdd = !lastClassOdd;
				ec_createCell(newRow, 'TD', classtype, 0, tmp, "&nbsp;", 0, 0, 0, 0, 0);
				
				if (lastClassOdd)
					classtype = 'odd'; // the inverse in intended
				else
					classtype = 'even';
					
				lastClassOdd = !lastClassOdd;
				ec_createCell(newRow, 'TD', classtype, newRow.getAttribute('s'), 0, newRow.getAttribute('z'), 0, 0, 0, 0);
			}
			newRow = table.rows[r];

			ec_createCell(newRow, 'TD', lastClassOdd ? 'even' : 'odd' , 0, '1',   "&nbsp;", 0, 0, 0, 0, 0);
			ec_createCell(newRow, 'TH', lastClassOdd ? 'even' : 'odd' , 0,  0,      "Hits", 0, 0, 0, 0, 0);
			ec_createCell(newRow, 'TH', lastClassOdd ? 'even' : 'odd' , 0,  0,    "Status", 0, 0, 0, 0, 0);
			/***************************   end of table head  ***************************************/
			r++;
			for (; r < table.rows.length; r++) {
				var excluded = 0;
				var alignTxt = 0;
				
				lastClassOdd = true; // is true to start the series with 'even'
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
					case 'e':
						newRow.className = 'grey'; excluded = 1; show_excl_button = 1; break;
					default:
						newRow.className = ''; break;
				}

				tmp = newRow.getAttribute('U'); // u is Unknown
				if (tmp) {
					ec_createCell(newRow, 'TD', 'odd', newRow.getAttribute('s'),  0, tmp, 0, 0, 0, 'center', '20');
				} else {
					lastClassOdd = !lastClassOdd;
					ec_createCell(newRow, 'TD', lastClassOdd ? 'even' : 'odd' , 0,  0, "Row&nbsp;" + newRow.getAttribute('n'), 0, 0, 0, 'center', '20');
					
					tmp = newRow.getAttribute('o'); // o is loop
					if (tmp) {
						tmp = newRow.getAttribute('z');
						for(i = 0; i < tmp.length; i++) {
							lastClassOdd = !lastClassOdd;
							ec_createCell(newRow, 'TD', lastClassOdd ? 'even' : 'odd' , 0,  0, tmp.charAt(i), 0, 0, 0, 'center', '20');
						}
					} else {
						lastClassOdd = !lastClassOdd;
						ec_createCell(newRow, 'TD', lastClassOdd ? 'even' : 'odd' , 0,  0, newRow.getAttribute('z'), 0, 0, 0, 'center', '20');
					}
				}

				tmp = newRow.getAttribute('cc');
				switch (tmp) {
					case 'o':
						classtype = 'odd_r'; break;
					case 'e':
						classtype = 'even_r'; break;
					default:
						classtype = ''; break;
				}
				tmp = newRow.getAttribute('k1');
				if (tmp) {
					lnktxt = "pertest.htm?bin=" + newRow.getAttribute('t') + tmp + "&scope=" + testHitDataScopeId;
					relAtt = 'popup 200 200';
				} else {
					relAtt = lnktxt = 0;
				}
				ec_createCell(newRow, 'TD', classtype, 0,  0, newRow.getAttribute('h1'), 0, lnktxt, relAtt, 0, 0);
				
				if (!excluded) {
					tmp = newRow.getAttribute('c');
					switch (tmp) {
						case 'g':
							classtype = 'green'; celltxt = 'Covered'; break;
						case 'r':
							classtype = 'red'; celltxt = 'ZERO'; break;
						default:
							alignTxt = 'center'; celltxt = '--'; break;
					}
				} else {
					classtype = 'grey'; celltxt = 'Excluded';
				}
				ec_createCell(newRow, 'TD', classtype, 0,  0, celltxt, 0, 0, 0, alignTxt, 0);
			}
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
};
