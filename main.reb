Rebol [
	type: module
	exports: [parse-demographics rx]
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

rx: func [ drug [text!]][
	; search for drug in database, get the first char
	c: form first drug
	data: read unspaced [root "/" c %.reb]
]
	
	
]
