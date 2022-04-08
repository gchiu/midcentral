Rebol []

comment {

ASurname, Basil Phillip (Mr) 

BORN16-Aug-1925 (96y)GENDER Male  

NHIABC1234

 
 
      

Address  29 Somewhere League, Middleton, NEW ZEALAND, 4999  

Home  071234567 
}

whitespace: charset [" " "^/" "^/M]
alpha: charset [#"A" - #"Z" #"a" - #"z"]
digit: charset [#"0" - #"9"]
nhi-rule: [3 alphaa 4 digit]

extract-demographics: func [][
				demo: ask ["Paste in demographics from CP" text!]
				parse demo [some whitespace copy fname to space #"," some space copy firstnames to "(" "(" copy title to ")" thru "BORN" copy dob to space
				thru "(" copy age to ")" thru "GENDER" some space copy gender some alpha thru "NHI" copy nhi nhi-rule]
				dump fname
				dump firstnames
				dump dob
				dump gender
				dump nhi
]
