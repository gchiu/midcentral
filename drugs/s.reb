rebol [
  filename: %s.reb
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
     		"ssz" "salazopyrin" [
	  		[	{Rx: Salazopyrin EN 500 mg^/Sig: 2 tabs PO PC BID^/Mitte: 3/12}
				{Rx: Salazopyrin EN 500 mg^/Sig: 1 tab PO PC nocte 1/52, then 1 tab PO PC BID 1/52, then 1 tab PO PC mane, 2 tabs PO PC nocte 1/52, then 2 tabs PO PC BID thereafter^/Mitte: 3/12}		
			]
	  	]
	]
	if 1 < len: length-of result [
		print newline
		for i len [print form i print result/:i print newline] 
		choose-drug result
	]
]
