rebol [
  filename: %f.reb
  type: module
  exports: [drugdata]
]

choose-drug: func [scheds [block!]
	<local> num
][
	num: length-of scheds
	choice: ask ["Which schedule to use?" integer!]
	if choice = 0 [return]
	if choice <= num [print pick scheds choice return]
	print "invalid choice"
]

drugdata: func [name
	<local> result
][
	name: form name
	result: switch name [
     		"f" "folic" [
	  		[	  {Rx: Folic Acid 5 mg^/Sig: 1 tab PO QW^/Mitte: 3/12}
				  {Rx: Folic Acid 0.8 mg^/Sig: 1 tab PO QD^/Mitte: 3/12}		
			  ]
	  	]
	]
	if 1 < len: length-of result [
		print newline
		for i len [print form i print result.:i print newline] 
		choose-drug result
	]
]
