Rebol [
	type: module
	exports: [parse-demographics rx choose-drug]
]

root: https://github.com/gchiu/midcentral/blob/main/drugs/

choose-drug: func [scheds [block!]
	<local> num
][
	num: length-of scheds
	choice: ask ["Which schedule to use?" integer!]
	if choice = 0 [return]
	if choice <= num [print pick scheds choice return]
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
		thru "Home" while whitespace 
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
		if null? result: switch drug data ; data comes from import link [
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

