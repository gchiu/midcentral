rebol [
  filename: %m.reb
  type: module
  exports: [drugdata]
]

drugdata: func [name
	<local> result
][
	name: form name
	result: switch name [
     		"mtx" "methotrexate" [
	  		[	{Rx: Methotrexate 10 mg^/Sig: 2 tabs PO QW^/Mitte: 3/12}
				{Rx: Methotrexate 10 mg^/Sig: 1 tab PO QW^/Mitte: 3/12}		
        {Rx: Methotrexate 2.5 mg^/Sig: 6 tabs PO QW^/Mitte: 3/12}
			]
	  	]
	]
	if 1 < len: length-of result [
		print newline
		for i len [print form i print result.:i print newline] 
		choose-drug result
	]
]
