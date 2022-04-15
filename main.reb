Rebol [
	type: module
	exports: [
		add-form ; puts JS form into DOM
		add-content ; adds content to the form
		choose-drug ; pick drug from a selection
		clear-form ; clears the script
		cdata ; the JS that will be executed
		expand-latin ; turns abbrevs into english
		parse-demographics ; extracts demographics from clinical portal details
		rx ; starts the process of getting a drug schedule
		rxs ; block of rx
		write-rx ; sends to docx
		; firstnames surname dob title nhi rx1 rx2 rx3 rx4
		street town city
	]
]

import @popupdemo
root: https://github.com/gchiu/midcentral/blob/main/drugs/
; rx-template: https://github.com/gchiu/midcentral/raw/main/rx-template-docx.docx ; can't use due to CORS
rx-template: https://metaeducation.s3.amazonaws.com/rx-template-docx.docx
rxs: []
firstnames: surname: dob: title: nhi: rx1: rx2: rx3: rx4: street: town: city: _

for-each site [
  https://cdnjs.cloudflare.com/ajax/libs/docxtemplater/3.29.0/docxtemplater.js
  https://unpkg.com/pizzip@3.1.1/dist/pizzip.js
  ; https://cdnjs.cloudflare.com/ajax/libs/jszip/2.6.1/jszip.js
  https://cdnjs.cloudflare.com/ajax/libs/FileSaver.js/1.3.8/FileSaver.js
  https://unpkg.com/pizzip@3.1.1/dist/pizzip-utils.js
  ; https://cdnjs.cloudflare.com/ajax/libs/jszip-utils/0.0.2/jszip-utils.js
][
  js-do site
]

js-do {window.loadFile = function(url,callback){
        PizZipUtils.getBinaryContent(url,callback);
    };
}

cdata: {window.generate = function() {
        loadFile("https://metaeducation.s3.amazonaws.com/rx-template-docx.docx",
	function(error,content){
            if (error) { throw error };
            var zip = new PizZip(content);
            // var doc=new window.docxtemplater().loadZip(zip)
	    var doc = new window.docxtemplater(zip, {
                        paragraphLoop: true,
                        linebreaks: true,
                    });
            try {
                // render the document (replace all occurences of {first_name} by John, {last_name} by Doe, ...)
                doc.render({
                	surname: '$surname',
			firstnames: '$firstnames',
			rx1: `$rx1`,
			rx2: `$rx2`,
            	});
            }
            catch (error) {
                var e = {
                    message: error.message,
                    name: error.name,
                    stack: error.stack,
                    properties: error.properties,
                }
                console.log(JSON.stringify({error: e}));
                // The error thrown here contains additional information when logged with JSON.stringify (it contains a property object).
                throw error;
            }    
            var out=doc.getZip().generate({
                type:"blob",
                mimeType: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            }) //Output the document using Data-URI
            saveAs(out,"$prescription.docx")
        })
    };
    generate()
}

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

add-form: does [
	show-dialog/size {<div id="board" style="width: 400px"><textarea id="script" cols="80" rows="80"></textarea></div>} 480x480
]

clear-form: does [
	js-do {document.getElementById('script').innerHTML = ''}
]


add-content: func [txt [text!]
][
	txt: append append copy txt newline newline
	js-do [{document.getElementById('script').innerHTML +=} spell @txt]
]

choose-drug: func [scheds [block!]
	<local> num choice output
][
	num: length-of scheds
	choice: ask ["Which schedule to use?" integer!]
	if choice = 0 [return]
	if choice <= num [
		print output: expand-latin pick scheds choice 
		add-content output
		append rxs output
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

parse-demographics: func [
	<local> data
][
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
	clear-form
	data: unspaced [ surname "," firstnames space "(" title ")" space "DOB:" space dob space "NHI:" space nhi newline street newline town newline city newline newline] 
	cdata: reword cdata reduce ['firstnames firstnames 'surname surname 'title title]
	probe cdata
	add-content data
	return cdata
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

write-rx: does [
;	cdata: reword cdata reduce [
;		'surname surname
;		'firstnames firstnames
;	]
	;for i 4 [
	;	if something? rxs.:i [
	;		cdata: reword cdata compose ['(to word! join "rx" i) rxs.:i]
	;	]
	;]
	cdata: reword cdata reduce ['rx1 rxs.1 'rx2 rxs.2 'rx3 rxs.3 'rx4 rxs.4]
	probe cdata

	js-do cdata
]
