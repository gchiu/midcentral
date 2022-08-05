rebol [
    date: 16-April-2022
    filename: %p.reb
    type: module
    exports: [data]
]

[
    "p" "pfizer" [
        [
            {Rx: Cominarty Covid-19 vaccine for immunosuppressed^/Sig: 1 IM stat^/Mitte: 0.3ml}
            {Rx: Pfizer/BioNTech Covid-19 Vaccine 4th dose for Immunosuppressed^/Sig: 1 IM stat^/Mitte: 0.3ml}
        ]
    ]
    "pan" "Paracetamol" [
        [
            {Rx: Paracetamol 500 mg^/Sig: 2 PO QD prn^/Mitte: 3/12}
            {Rx: Paracetamol 500 mg^/Sig: 2 PO QID prn^/Mitte: 3/12}
        ]

    ]
    "pax" "Paxlovid" [
        [
            {Rx: PAXLOVID (nirmatrelvir 300 mg/ritonavir 100 mg) ^/for Immunosuppressed eGFR=^/Sig: take 3 tablets in each cell BID^/Mitte: 5 days^/Use Eclair to check latest eGFR and other drugs for possible interactions}
            {Rx: PAXLOVID (nirmatrelvir 300 mg/ritonavir 100 mg) ^/for Immunosuppressed & reduced renal function eGFR=^/Sig: take 1 tablets of each in a cell BID^/Mitte: 5 days^/Use Eclair to check latest eGFR and other drugs for possible interactions}
            {Rx: PAXLOVID (nirmatrelvir 300 mg/ritonavir 100 mg) ^/for Immunosuppressed. Back Pocket.^/Sig: take 3 tablets in each cell BID^/Mitte: 5 days^/Use Eclair to check latest eGFR and other drugs for possible interactions}
            {Rx: PAXLOVID (nirmatrelvir 300 mg/ritonavir 100 mg) ^/for Immunosuppressed & reduced renal function, Back Pocket.^/Sig: take 1 tablets of each in a cell BID^/Mitte: 5 days^/Use Eclair to check latest eGFR and other drugs for possible interactions}
            {Stop all arthritis medications except prednisone.^/Restart them at least a week or more after recovering from Covid}
        ]
    ]
    "pred" "prednisone" "prednisolone" [
        [
            {Rx: Prednisone 1 mg^/Sig: 4 PO mane.  Taper 1 mg a month^/Mitte: 3/12}
            {Rx: Prednisone 2.5 mg^/Sig: 3 PO mane^/Mitte: 3/12}
            {Rx: Prednisone 5 mg^/Sig: 1 PO mane^/Mitte: 3/12}
            {Rx: Prednisone 5 mg^/Sig: 2 PO mane^/Mitte: 3/12}
            {Rx: Prednisone 20 mg^/Sig: 2 PO mane 1 PO nocte^/Mitte: 3/12}
        ]
    ]
    "prob" "probenecid" [
        [
            {Rx: probenecid 500 mg^/Sig: 1 PO QD^/Mitte: 3/12}
            {Rx: probenecid 500 mg^/Sig: 1 PO BID^/Mitte: 3/12}
            {Rx: probenecid 500 mg^/Sig: 2 PO BID^/Mitte: 3/12}
        ]
    ]
]
