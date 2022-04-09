rebol [
  filename: %s.reb
  type: module
  exports: [drugdata]
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
		for i len [print form i print result.:i print newline] 
		choose-drug result
	]
]
