Rebol [
	type: module
	exports: [
		add-form ; puts JS form into 
		add-content ; adds content to the form
		choose-drug ; pick drug from a selection
		expand-latin ; turns abbrevs into english
		parse-demographics ; extracts demographics from clinical portal details
		rx ; starts the process of getting a drug schedule
	]
]

import @popupdemo
root: https://github.com/gchiu/midcentral/blob/main/drugs/

expand-latin: func [sig [text!]
	<local> data
][
	data: [
		"QD" "once daily"
		"QW" "once weekly"
		"BID" "twice daily"
		"TDS" "three times daily"
		"mane" "in the morning"
		"nocte" "at night"
		"PC" "with food"
		"AC" "before food"
	]
	for-each [abbrev expansion] data [
		replace sig unspaced [space abbrev space] unspaced [space expansion space]
		replace sig unspaced [space abbrev newline] unspaced [space expansion newline]
	]
	return sig
]

choose-drug: func [scheds [block!]
	<local> num output
][
	num: length-of scheds
	choice: ask ["Which schedule to use?" integer!]
	if choice = 0 [return]
	if choice <= num [
		print output: expand-latin pick scheds choice 
		add-content output
		return
	]
	print "invalid choice"
]

comment {

ASurname, Basil Phillip (Mr) 

BORN16-Aug-1925 (96y)GENDER Male  

NHIABC1234

 
 
      

Address  29 Somewhere League, Middleton, NEW ZEALAND, 4999  

Home  071234567 
}

whitespace: charset [#" " #"^/" #"^M" #"^J"]
alpha: charset [#"A" - #"Z" #"a" - #"z"]
digit: charset [#"0" - #"9"]
nhi-rule: [3 alpha 4 digit]

parse-demographics: func [][
	demo: ask ["Paste in demographics from CP" text!]
	parse demo [while whitespace copy surname to "," thru space while space copy firstnames to "(" (trim/head/tail firstnames) 
		thru "(" copy title to ")" thru "BORN" copy dob to space
		thru "(" copy age to ")" thru "GENDER" while space copy gender some alpha thru "NHI" copy nhi nhi-rule
		thru "Address" while whitespace copy street to "," thru "," while whitespace copy town to "," thru "," 
		while whitespace copy city to ","
		[thru "Home" | thru "Mobile" ] while whitespace 
		copy phone some digit 
		to end
	]
	dump surname
	dump firstnames
	dump title
	dump dob
	dump gender
	dump nhi
	dump street
	dump town
	dump city
	dump phone
]

rx: func [ drug [text! word!]
	<local> link result c err
][
	drug: form drug
	; search for drug in database, get the first char
	c: form first drug
	link: to url! unspaced [root c %.reb]
	dump link
	if error? err: trap [import link] [
		print spaced ["This page" link "isn't available, or, has a syntax error"]
	] else [
		if null? result: switch drug data [; data comes from import link 
			print spaced ["Drug" drug "not found in database. Edit link to add it."]		
		] else [	
			if 1 < len: length-of result [
				print newline
				for i len [print form i print result.:i print newline] 
				choose-drug result
			]
		]
	]
]

add-form: does [
replpad-write/html
{<div id=form>
<script language="JavaScript">
function openWin(){<!--from w ww .  j  a  va  2 s  .co  m-->
var myBars = 'directories=no,location=no,menubar=no,status=no';

myBars += ',titlebar=no,toolbar=no';
var myOptions = 'scrollbars=no,width=400,height=200,resizeable=no';
var myFeatures = myBars + ',' + myOptions;
var myReadme = 'This is a test.'

var newWin = open('', 'myDoc', myFeatures);

newWin.document.writeln('<form>');
newWin.document.writeln('<table>');
newWin.document.writeln('<tr valign=TOP><td>');
newWin.document.writeln('<textarea cols=45 rows=7 wrap=SOFT>');
newWin.document.writeln(myReadme + '</textarea>');
newWin.document.writeln('</td></tr>');
newWin.document.writeln('<tr><td>');
newWin.document.writeln('<input type=BUTTON value="Close"');
newWin.document.writeln(' onClick="window.close()">');
newWin.document.writeln('</td></tr>');
newWin.document.writeln('</table></form>');
newWin.document.close();
newWin.focus();
}
</script>
</div>
}
]

add-form: does [
	show-dialog/size {<div id="board" style="width: 400px"><textarea id="script" cols="80" rows="80"></textarea></div>} 480x480
]

add-content: func [txt [text!]
	<local> foo
][
	string: {document.getElementById('script').innerHTML += "$a"}
	reword foo: string compose [a (txt)]
	js-do foo
]
