rebol [
    date: 16-April-2022
    filename: %p.reb
    type: module
    exports: [data]
]

data: [
    "p" "pfizer" [
        [
            {Rx: Cominarty Covid-19 vaccine for immunosuppressed^/Sig: 1 IM stat^/Mitte: 0.3ml}
            {Rx: Pfizer/BioNTech Covid-19 Vaccine 4th dose for Immunosuppressed^/Sig: 1 IM stat^/Mitte: 0.3ml}
        ]
    ]
    "pax" "Paxlovid" [
        [
            {Rx: PAXLOVID (nirmatrelvir 300 mg/ritonavir 100 mg) ^/for Immunosuppressed^/Sig: take 3 tablets in each cell BID^/Mitte: 5 days}
            {Rx: PAXLOVID (nirmatrelvir 300 mg/ritonavir 100 mg) ^/for Immunosuppressed & reduced renal function^/Sig: take 1 tablets of each in a cell BID^/Mitte: 5 days}
        ]
    ]
    "pred" "prednisone" "prednisolone" [
        [
            {Rx: Prednisone 1 mg^/Sig: 4 PO mane.  Taper 1 mg a month^/Mitte: 3/12}
            {Rx: Prednisone 5 mg^/Sig: 1 PO mane^/Mitte: 3/12}
            {Rx: Prednisone 5 mg^/Sig: 2 PO mane^/Mitte: 3/12}
            {Rx: Prednisone 20 mg^/Sig: 2 PO mane 1 PO nocte^/Mitte: 3/12}
        ]
    ]
]
