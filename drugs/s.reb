rebol [
  filename: %s.reb
  type: module
  exports: [drugdata]
]

drugdata: func [name][
	name: form name
  switch name [
      "ssz" "salazopyrin" [
	  		{Rx: Salazopyrin EN 500 mg^/Sig: 2 tabs PO PC BID^/Mitte: 3/12}
	  ]
	  
  ]
]
