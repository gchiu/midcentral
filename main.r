Rebol [
    type: module
    author: "Graham Chiu"
    version: 1.0.54

    description: --[
        This is a module for managing prescriptions and laboratory requests.
        It allows you to create, edit, and manage drug schedules, patient
        demographics, and generate prescription documents in DOCX format.

        It is designed to run in the Ren-C web console, where it can use
        JavaScript libraries for document generation and manipulation.
    ]--

    sample-data: --[  ; use w/"Paste Patient Demographics from Clinical Portal"
        ASurname, Basil Phillip (Mr)

        BORN16-Aug-1925 (96y)GENDER Male

        NHIABC1234

        

            

        Address  29 Somewhere League, Middleton, NEW ZEALAND, 4999

        Home  071234567
    ]--

    exports: [  ; `help-rx` prints the help strings of functions in this list
        add-form
        add-content
        choose-drug
        clear-cache
        clear-form
        clear-rx
        expand-latin
        grab-creds
        manual-entry
        new-rx
        parse-demographics
        rx
        set-doc
        set-location
        write-rx
        write-ix
        clrdata
        parse-referral
        clinical
        bio
        sero
        oth
        haemo
        mic
        help-rx

        ; exported variables (how to encode help on these?)
        rxs
        street town city
        docname doccode
        docregistration
        biochem serology other haem micro
        cdata
    ]
]


=== LIBRARIES ===

import @popupdemo

for-each 'site [
    https://cdnjs.cloudflare.com/ajax/libs/docxtemplater/3.29.0/docxtemplater.js
    https://unpkg.com/pizzip@3.1.1/dist/pizzip.js
    ; https://cdnjs.cloudflare.com/ajax/libs/jszip/2.6.1/jszip.js
    https://cdnjs.cloudflare.com/ajax/libs/FileSaver.js/1.3.8/FileSaver.js
    https://unpkg.com/pizzip@3.1.1/dist/pizzip-utils.js
    ; https://cdnjs.cloudflare.com/ajax/libs/jszip-utils/0.0.2/jszip-utils.js
][
    js-do site
]


=== FILENAMES AND URLS ===

; The Ren-C web console treats requests to read and write FILE! as applying
; to browser-local storage associated with the ReplPad domain.  This space is
; used to store doctor information, patient demographics, and caches of the
; drug lists.
;
; Drug lists are located on GitHub, and the DOCX templates are stored on S3.

druglist-url-for-char: lambda [c [char?]] [
    compose https://raw.githubusercontent.com/gchiu/midcentral/main/drugs/(c)-drugs.r
]

druglist-cachefile-for-char: lambda [c [char?]] [
    compose %/(c)-drugs.r
]

localstorage-file-for-nhi: lambda [nhi [text!]] [
    compose %/(nhi).r
]

rx-template: https://metaeducation.s3.amazonaws.com/rx-6template-docx.docx
ix-template: sys.util/adjust-url-for-raw https://github.com/gchiu/midcentral/blob/main/templates/Medlab-form-ver1.docx
; https://metaeducation.s3.amazonaws.com/Medlab-form-ver1.docx


=== GLOBAL DEFINITIONS ===

doccode: "GCHIRC DCGHW DGCHI"

slotno: 6  ; !!! only use was commented out

rxs: []
rx1: rx2: rx3: rx4: rx5: rx6: null

nhi: null
firstnames: surname: title: dob: age: gender: null
street: town: city: null
phone: mobile: email: null

docname: docregistration: null

wtemplate: itemplate: null

old_patient: null

eol: charset [#"^/" #","] ; used to parse out the address line

medical: biochem: serology: other: micro: haem: null
; doccode: null

dgh: --[This Prescription meets the requirement of the Director-General of Health’s waiver of October 2022 for prescriptions not signed personally by a prescriber with their usual signature]--


=== JAVASCRIPT INTERFACE ===

js-do --[
    window.loadFile = function(url,callback) {
        PizZipUtils.getBinaryContent(url,callback)
    }
]--

cdata: --[
  window.generate = function() {
    loadFile("$docxtemplate", function(error,content) {
        if (error) { throw error }
        var zip = new PizZip(content);
        /* var doc=new window.docxtemplater().loadZip(zip) */
        var doc = new window.docxtemplater(zip, {
            paragraphLoop: true,
            linebreaks: true,
        })
        try {
            // render the document
            // (replace all occurences of {first_name} by John,
            // {last_name} by Doe, ...)
            doc.render({
                $template
            });
        }
        catch (error) {
            var e = {
                message: error.message,
                name: error.name,
                stack: error.stack,
                properties: error.properties,
            }
            console.log(JSON.stringify({error: e}))
            // The error thrown here contains additional information
            // when logged with JSON.stringify (it contains a property object).
            throw error
        }
        var out=doc.getZip().generate({
            type: "blob",
            mimeType: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        }) // Output the document using Data-URI
        saveAs(out,"$prescription.docx")
    })
  };
  generate()
]--

js-button: --[
    <input type="button"
        id="copy NHI"
        value="Copy NHI"
        onclick='reb.Elide("write clipboard:// -[$a]-")'
    />
]--


=== MAIN SCRIPT ===

ask-confirm: func [
    return: [logic?]
][
    let response: ask ["okay?" text!]
    return did find "yY" first response
]

set-location: func [
    "sets up the url to be used for the prescription"
    return: []
    <with> rx-template
][
    let config: if exists? %/configuration.r [
        load %/configuration.r
    ] else [
        save %/configuration.r load https://raw.githubusercontent.com/gchiu/midcentral/main/templates/sample-config.r
        ; load %/configuration.r
    ]
    print "Current locations"
    let i: 1
    for-each [name url] config [
        print [i name]
        i: me + 1
    ]
    let choice: ask ["select location (use 0 to add more locations):" integer!]
    choice: choice * 2 - 1
    dump choice
    choice: pick config choice
    dump choice
    ?? choice
    dump config
    print form lift type of choice
    if any [url? choice text? choice] [
        rx-template: select config choice
        save %current.r reduce [choice rx-template]
        return ~
    ]
    cycle [
        ; Note: This is how ASK currently works.  Review.
        ;
        let loc: ask ["Enter consulting location name:" text!]
        if null? loc [break]  ; ESCAPE hit
        if empty? trim loc [break]  ; ENTER with all whitespace

        let url: ask ["Enter URL for the prescription template:" url!]
        rescue [read url] then err -> [
            print "This location is not available"
            continue
        ] else [
            if ask-confirm [
                append config spread [loc url]
            ]
        ]
    ]
    save %/configuration.r config
]

set-doc: func [
    "fills the wtemplate with current doc"
    return: []
][
    wtemplate: copy template
    wtemplate: reword wtemplate reduce [
        'docname docname
        'docregistration docregistration
        'signature docname
        'date now:date
    ]
    itemplate: copy labplate
    itemplate: reword itemplate reduce [
        'docname docname
        'doccode doccode
        'date now:date
        'cc "copy to General Practitioner"
    ]
    ; probe wtemplate
]

grab-creds: func [
    "gets credentials"
    return: []
][
    let docnames
    let docregistrations
    cycle [
        docnames: ask ["Enter your name as appears on a prescription:" text!]
        docregistrations: ask ["Enter your prescriber ID number:" integer!]
        if ask-confirm [
            set $docname docnames
            set $docregistration docregistrations
            break
        ]
    ]
    set-doc
    ; probe wtemplate
    write %/credentials.r mold reduce [docname docregistration]
]

expand-latin: func [
    "turns abbreviations into english"
    return: "Updated sig" [text!]
    sig [text!]
][
    let data: [
        "QD" "once daily"
        "QW" "once weekly"
        "BID" "twice daily"
        "TDS" "three times daily"
        "mane" "in the morning"
        "nocte" "at night"
        "PC" "with food"
        "AC" "before food"
        "SQ" "subcutaneous"
    ]
    for-each [abbrev expansion] data [
        replace sig unspaced [space abbrev space] unspaced [space expansion space]
        replace sig unspaced [space abbrev newline] unspaced [space expansion newline]
    ]
    return sig
]

add-form: func [
    "puts JS form into DOM"
    return: []
][
    show-dialog:size --[
        <div id="board" style="width: 400px">
            <textarea id="script" cols="80" rows="80"></textarea>
        </div>
    ]-- 480x480
]

clear-form: func [
    "clears the script"
    return: []
][
    js-do --[document.getElementById('script').innerHTML = '']--
    set-doc
]

add-content: func [
    "adds content to the form"
    return: []
    txt [text!]
][
    txt: append append copy txt newline newline
    js-do [--[document.getElementById('script').innerHTML +=]-- spell @txt]
]

choose-drug: func [
    "pick drug from a selection"
    return: []
    scheds [block!]
    filename
    <with> rxs
][
    let num: length-of scheds
    let choice: ask ["Which schedule to use?" integer!]
    if choice = 0 [return ~]
    if choice = -1 [delete filename, print "Cache deleted, try again" return ~]
    if choice <= num [
        let output: expand-latin pick scheds choice
        print output
        add-content output
        append rxs output
        return ~
    ]
    ; out of bounds
    let output: pick scheds 1
    let drugname: null
    ; first off, get any drugs that start with a digit eg. 6-Mercaptopurine
    parse output [drugname: across some digit, output: across to <end>]
    if not drugname [
        ; not a drug that starts with a digit
        drugname: copy ""
    ] ; otherwise drugname = "6" etc
    ; now get the rest of the drugname
    let drug
    parse output [drug: across to digit, to <end> (append drugname drug)]
    ; so we now have the drugname
    ; so let's ask for the new dose
    let dose
    let sig
    let mitte
    cycle [
        dose: ask compose [(spaced ["New Dose for" drugname]) text!]
        sig: ask ["Sig:" text!]
        mitte: ask ["Mitte:" text!]
        if ask-confirm [break]
    ]
    output: expand-latin spaced [drugname dose "^/Sig:" sig "^/Mitte:" mitte]
    add-content output
    append rxs output
    return ~
]

whitespace-char: charset [#" " #"^/" #"^M" #"^J"]
whitespace: [some whitespace-char]
alpha: charset [#"A" - #"Z" #"a" - #"z"]
digit: charset [#"0" - #"9"]
nhi-rule: [repeat 3 alpha, repeat 4 digit]
digits: [some digit]

template: --[
    surname: `$surname`,
    firstnames: `$firstnames`,
    title: `$title`,
    dob: `$dob`,
    street: `$street`,
    town: `$town`,
    city: `$city`,
    nhi: `$nhi`,
    phone: `$phone`,
    rx1: `$rx1`,
    rx2: `$rx2`,
    rx3: `$rx3`,
    rx4: `$rx4`,
    rx5: `$rx5`,
    rx6: `$rx6`,
    signature: `$signature`,
    date: `$date`,
    docname: `$docname`,
    docregistration: `$docregistration`,
    dgh: `$dgh`,
]--

labplate: --[
    surname: `$surname`,
    firstnames: `$firstnames`,
    title: `$title`,
    dob: `$dob`,
    address: `$address`,
    gender: `$gender`,
    nhi: `$nhi`,
    date: `$date`,
    docname: `$docname`,
    doccode: `$doccode`,
    medical: `$medical`,
    biochem: `$biochem`,
    haem: `$haem`,
    serology: `$serology`,
    other: `$other`,
    micro: `$micro`,
    cc: `$cc`,
]--

parse-demographics: func [
    "extracts demographics from clinical portal details"
    return: []
    <with>
        surname firstnames title dob age gender nhi street town city
        phone mobile email
        wtemplate itemplate old_patient
][
    let demo: ask ["Paste in demographics from CP" text!]

    ; see https://rebol.metaeducation.com/t/gather-and-emit/1531/9

    phone: mobile: email: null
    parse demo [
        [opt whitespace]
        surname: across to ","
        thru space [opt whitespace]
        [firstnames: across to "("] (trim:head:tail firstnames)
        thru "(" title: across to ")"  ; `title: between "(" ")"`
        thru "BORN" dob: across to space
        thru "(" age: across to ")"    ; `age: into between "(" ")" integer!`
        thru "GENDER" [opt whitespace] gender: across some alpha
        thru "NHI" nhi: across nhi-rule
        thru "Address" [opt whitespace] street: across to eol (?? street ?? 1)
        thru some eol [opt whitespace] town: across to eol (?? 2 ?? town)
        thru some eol [opt whitespace] city: across to eol (?? 3 ?? city)
        [thru "Home" (?? 4)
            | thru "Mobile" (?? 5)
            | thru "EMAIL" (?? 50) [opt whitespace] email: across to space accept (okay)
            | thru "Contact – No Known Contact Information" (?? 6) to <end> (print "Incomplete Demographics") accept (okay)
        ] [opt whitespace]
        phone: across some digit (?? 51 ?? phone)
        try [
            thru some eol thru "Mobile" [opt whitespace] mobile: across some digit (?? 6 ?? mobile)
            thru some eol try [thru "Email" [opt whitespace] email: across to space (?? 7 ?? email)]
        ]
        to <end>
    ] except [
        print "Could not parse demographic data"
        return ~
    ]
    if nhi = old_patient [
        let response: lowercase ask compose [
            (spaced ["Do you want to use this patient" surname "again?"]) text!
        ]
        if response.1 <> #"y" [
            return ~
        ]
    ]

  ;comment [
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
  ;]

    clear-form
    let data: unspaced [
        surname "," firstnames space "(" opt title ")" space "DOB:" space dob space "NHI:" space nhi newline
        street newline town newline city newline newline
        "phone:" space opt phone newline
        "mobile:" space opt mobile newline
        "email:" space opt email
    ]
    phone: default [blank]
    mobile: default [blank]
    email: default [blank]
    wtemplate: reword wtemplate reduce [
        'firstnames firstnames
        'surname surname
        'title title
        'street street
        'town town
        'city city
        'phone phone
        'dob dob
        'nhi nhi
        'prescription nhi
    ]
    itemplate: reword itemplate reduce compose [
        'firstnames firstnames
        'surname (join surname ",")
        'address (spaced [opt street opt town opt city])
        'phone phone
        'dob dob
        'nhi nhi
        'gender "M F O"
        'title title
    ]
    probe itemplate
    old_patient: copy nhi
    ; probe wtemplate
    write (localstorage-file-for-nhi nhi) mold compose [
        nhi: (nhi)
        title: (title)
        surname: (surname)
        firstnames: (firstnames)
        dob: (dob)
        street: (street)
        town: (town)
        city: (city)
        phone: (phone)
        gender: (gender)
    ]

    add-content data
    let js: copy js-button
    replace js "$a" nhi
    replpad-write:html js
    print unspaced ["saved " "%/" nhi %.r ]
]

manual-entry: func [
    "asks for patient demographics"
    return: []
    <with>
        nhi
        title surname firstnames dob street town city phone gender
        wtemplate itemplate
][
    print "Enter the following details:"
    nhi: uppercase ask ["NHI:" text!]
    let filename: localstorage-file-for-nhi nhi
    if word? opt exists? filename [
        let filedata: load filename
        filedata: filedata.1
        title: filedata.title
        surname: filedata.surname
        firstnames: filedata.firstnames
        dob: filedata.dob
        street: filedata.street
        town: filedata.town
        city: filedata.city
        phone: filedata.phone
        gender: filedata.gender

        ; dump filedata
    ] else [
        cycle [
            title: uppercase ask ["Title:" text!]
            surname: ask ["Surname:" text!]
            firstnames: ask ["First names:" text!]
            dob: ask ["Date of birth:" date!]
            street: ask ["Street Address:" text!]
            town: ask ["Town:" text!]
            city: ask ["City:" text!]
            phone: ask ["Phone:" text!]
            gender: ask ["Gender:" text!]
            let response: lowercase ask ["OK?" text!]

            if response.1 = #y [break]
        ]
    ]

  comment [
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

    let data: unspaced [
        surname "," firstnames space "(" title ")" space "DOB:" space dob space "NHI:" space nhi newline street newline town newline city newline newline
    ]
    wtemplate: reword wtemplate reduce [
        'firstnames firstnames
        'surname surname
        'title title
        'street street
        'town town
        'city city
        'phone phone
        'dob dob
        'nhi nhi
        'prescription nhi
    ]
    ; update the investigation template in both manual and pasted versions
    itemplate: reword itemplate reduce compose [
        'firstnames firstnames
        'surname (join surname ",")
        'address (spaced [opt street opt town opt city])
        'phone phone
        'dob dob
        'nhi nhi
        'gender "M F O"
        'title title
    ]

    ; probe wtemplate
    write (localstorage-file-for-nhi nhi) mold compose [
        nhi: (nhi)
        title: (title)
        surname: (surname)
        firstnames: (firstnames)
        dob: (dob)
        street: (street)
        town: (town)
        city: (city)
        phone: (phone)
        gender: (gender)
    ]

    add-content data
    let js: copy js-button
    replace js "$a" nhi
    replpad-write:html js
    print unspaced ["saved " "%/" nhi %.r ]
]

rx: func [
    "starts the process of getting a drug schedule"
    return: []
    drug [text! word!]
][
    let local?: null
    drug: form drug

    ; search for drug in database, get the first char

    let c: first drug
    let filename: druglist-cachefile-for-char c
    let link: druglist-url-for-char c
    let data
    if exists? filename [
        data: first load filename
        print "loaded off local storage"
        local?: okay
        ; dump data
    ] else [
        ;dump filename
        ;dump link
        rescue [
            data: load link
            save filename data
            data: data.1
            ; dump data
            prin "Datafile loading ... "
        ] then err -> [
            print spaced ["This page" link "isn't available, or, has a syntax error"]
            ; probe err
            return ~
        ] else [
            print "and cached"
        ]
    ]
    if drug.2 = #"*" [
        ; asking for what drugs are available
        let counter: 0
        let line: copy []
        let drugs: copy []
        let lastitem
        for-each 'item data [
            if text? item [append line item]
            if block? item [
                counter: me + 1
                insert head of line form counter
                print line
                clear head of line
                append drugs lastitem
            ]
            lastitem: copy item
        ]
        let response: ask compose [(join "0-" counter) integer!]
        case [
            all [response > 0 response <= counter][drug: pick drugs response]
            response = 0 [return ~]
            response = -1 [delete filename rx drug] ; deletes cache and reloads it
            <else> [
                let rxname
                let sig
                let mitte
                cycle [
                    rxname: ask ["Rx:" text!]
                    sig: ask ["Sig:" text!]
                    mitte: ask ["Mitte:" text!]
                    if ask-confirm [break]
                ]
                let output: expand-latin spaced ["Rx:" rxname "^/Sig:" sig "^/Mitte:" mitte]
                add-content output
                append rxs output
                return ~
            ]
        ]
    ]
    ; dump drug
    ; dump data
    let result: switch drug data  ; data comes from import link
    if not result [
        print spaced ["Drug" drug "not found in database."]
        if local? [ ; means we used the cache, so let's fetch the original file
            rescue [
                data: load link
                save filename data
                data: data.1
                ; dump data
                prin "Datafile loading ... "
                if find data drug [rx drug, return ~]
            ] then err -> [
                print "And there's no file online"
            ]
        ]
        print ["You can submit a PR to add them here." https://github.com/gchiu/midcentral/tree/main/drugs ]
    ] else [
        let len: length of result
        if len <> 0 [
            print newline
            for 'i len [print form i print result.(i) print newline]
            choose-drug result filename
        ]
    ]
    return ~
]

clear-rx: func [
    "clears the drugs but leaves patient"
    return: []
    <with>
    wtemplate
    surname firstnames title dob nhi street town city phone
][
    clear-form
    ; probe wtemplate
    ; ?? nhi
    ; ?? firstnames
    let data: unspaced [
        surname "," firstnames space "(" title ")" space "DOB:" space dob space "NHI:" space nhi newline street newline town newline city newline newline
    ]
    wtemplate: reword wtemplate reduce [
        'firstnames firstnames
        'surname surname
        'title title
        'street street
        'town town
        'city city
        'phone phone
        'dob dob
        'nhi nhi
        'prescription nhi
    ]
    ; probe wtemplate
    add-content data
    ; add-content unspaced [ surname "," firstnames space "(" title ")" space "DOB:" space dob space "NHI:" space nhi newline street newline town newline city newline newline]
    clear rxs
    print "Ready for another Rx"
]

write-rx: func [
    "sends to docx"
    return: []
    <with>
    rx-template wtemplate
    slotno  ; !!! only use and commented out, still relevant?
][
    ; append:dup rxs space slotno
    let codedata: copy cdata
    replace codedata "$template" wtemplate
    replace codedata "$docxtemplate" rx-template
    ?? nhi
    let date: now:date
    ?? date
    replace codedata "$prescription" unspaced [nhi "_" now:date]
    codedata: reword codedata reduce [
        'rx1 rxs.1
        'rx2 any [try rxs.2 space]
        'rx3 any [try rxs.3 space]
        'rx4 any [try rxs.4 space]
        'rx5 any [try rxs.5 space]
        'rx6 any [try rxs.6 space]
    ]
    codedata: reword codedata reduce compose ['date (spaced [now:date now:time])]
    let response: lowercase ask ["For email?" text!]
    codedata: reword codedata reduce compose [
        'dgh (if response.1 = #"y" [dgh] else [" "])
    ]
    ;probe copy:part codedata 200
    ;dump rx-template
    js-do codedata
]

write-ix: func [
    return: []
][
    ?? biochem
    ?? medical
    ?? serology
    ?? haem
    ?? other
    let codedata: copy cdata ; the JS template
    replace codedata "$template" itemplate ; put the JS definitions into the JS template
    replace codedata "$docxtemplate" ix-template ; link to the docx used for the laboratory request form
    replace codedata "$prescription" unspaced [nhi "_" "labrequest" "_" now:date] ; specify the name used to save it as
    codedata: reword codedata reduce [
        'biochem reify biochem
        'medical reify medical
        'serology reify serology
        'micro reify micro
        'haem reify haem
        'other reify other
    ]
    probe copy:part codedata 500
    write clipboard:// codedata
    ;dump rx-template
    js-do codedata
]

new-rx: func [
    "start a new prescription"
    return: []
    <with> rxs
][
    if not docname [
        grab-creds
    ]
    rxs: copy []
    set-doc
    add-form
    let response: lowercase ask [
        "Paste in Patient Demographics from Clinical Portal? (y/n)" text!
    ]
    if response.1 = #y [
        parse-demographics
    ] else [
        cls ; clears the screen for the Cypress testing
        manual-entry
    ]
    print --["Use Rx" to add a drug to prescription]--
]

clear-cache: func [
    "remove the drug caches"
    return: []
][
    let alphabet: "abcdefghijklmnopqrstuvwxyz"
    for 'i 26 [
        attempt [
            let file: druglist-cachefile-for-char alphabet.(i)
            delete file
            print ["Deleted" file]
        ]
    ]
]


=== OTHER PARSE TOOLS ===

parse-referral: func [  ; !!! does not seem to be used
    "extracts demographics from Specialist Referral PDF"
    return: []
    <local>
    fname sname nhi dob gender email mobile street suburb city zip
][
    let data: ask ["Paste in Specialist Referral Demographics" text!]
    fname: sname: nhi: dob: gender: email: mobile: street: suburb: city: zip: null
    parse data [
        thru "Name" thru ":" [opt whitespace] fname: across to space [whitespace] sname: across to "NHI"
        (trim sname)
        thru ":" [whitespace] nhi: across nhi-rule thru eol
        thru "Date Of Birth" thru ":" [opt whitespace] dob: across to space
        thru "Gender" thru ":" [opt whitespace] gender: between <here> eol
        thru "Email" thru ":" [opt whitespace] email: between <here> eol
        thru "Mobile" thru ":" [opt whitespace] mobile: between <here> eol
        thru "Residential Address" thru ":" [opt whitespace] street: between <here> "," suburb: between <here> ","
        city: between <here> "," zip: across digits to <end>
    ]
    ?? fname
    ?? sname
    ?? nhi
    ?? dob
    ?? gender
    ?? email
    ?? mobile
    ?? street
    ?? suburb
    ?? city
    ?? zip
]


=== LAB FORM TOOLS ===

medical: biochem: serology: other: micro: haem: null  ; doccode: null

clinical: func [
    return: []
    <with> medical
][
    medical: ask ["Enter clinical details including periodicity" text!]
    print medical
    if not ask-confirm [clinical]
]

bio: func [
    return: []
    <with> biochem
][
    print --[1. Creatinine, LFTs, CRP
2. CPK
3. Serum Uric Acid
4. cryoglobulins
]--
    biochem: ask ["Enter biochemistry requests" text!]
    replace biochem "1" "Creatinine, LFTs, CRP,"
    replace biochem "2" "CPK,"
    replace biochem "3" "Serum Uric Acid"
    replace biochem "4" "cryoglobulins"
    print biochem
    if not ask-confirm [bio]
]

sero: func [
    return: []
    <with> serology
][
    print --[0. Hep B, C serology
1. ANA ENA
2. ds-DNA
3. Complement
4. Cardiolipin, Lupus Anticoagulant, B2-glycoprotein Antibodies
5. Extended scleroderma blot
6. Scl-70 by immunodiffusion
]--
    serology: ask ["Enter serology requests" text!]
    replace serology "0" "Hep B, C serology,"
    replace serology "1" "ANA ENA,"
    replace serology "2" "ds-DNA,"
    replace serology "3" "Complement,"
    replace serology "4" "Cardiolipin, Lupus Anticoagulant, B2-glycoprotein Antibodies,"
    replace serology "5" "Extended scleroderma blot,"
    replace serology "6" "Scl-70 by immunodiffusion"
    print serology
    if not ask-confirm [sero]
]

oth: func [
    return: []
    <with> other
][
    print --[1. Quantiferon TB Gold,]--
    other: ask ["Enter other requests" text!]
    replace other "1" "Quantiferon TB Gold"
    print other
    if not ask-confirm [oth]
]

haemo: func [
    return: []
    <with> haem
][
    print --[1. CBC
2. Lupus Anticoagulant
3. Coomb's test (DAGT)
4. ESR
]--
    haem: ask ["Enter haematology requests" text!]
    replace haem "1" "CBC,"
    replace haem "2" "Lupus Anticoagulant,"
    replace haem "3" "Coomb's test,"
    replace haem "4" "ESR (see clinical details)"
    print haem
    if not ask-confirm [haemo]
]

mic: func [
    return: []
    <with> micro
][
    print --[1. MSU
2. ACR
3. Urinary Casts and sediment
4. Polarized microscopy for urate crystals
]--
    micro: ask ["Enter Microbiology requests" text!]
    replace micro "1" "MSU,"
    replace micro "2" "ACR,"
    replace micro "3" "Urinary Casts and sediment,"
    replace micro "4" "Polarized microscopy for urate crystals,"
    print micro
    if not ask-confirm [mic]
]

clean-data: func [
    "removes double spaces, tabs and empty lines from data"
    return: "cleaned data" [text!]
    data [text!]
][
    replace data "^-" space
    while [find data "^/^/"] [
        replace data "^/^/" "^/"
    ]
    while [find data "  "] [
        repeat 10 [replace data "  " space]
    ]
    data: trim:head data
    return data
]

clrdata: func [
    "removes spaces, tabs from laboratory results - separate utility"
    return: []  ; !!! is this meant to return data?
][
    data: ask "Paste in your blood results"
    clean-data data
    write clipboard:// data
]


=== HELP ===

; Help is generated for functions in the [exports: [...]] list in the header.
;
; 1. The header is (currently) only available in system.script.header.exports
;    during the loading of this script, so capture it into a static variable.
;    (future approaches may persist module properties in the environment).

help-rx: func [
    return: []
] bind construct [
    exports-in-header: system.script.header.exports  ; capture during load [1]
][
    print "=== ACTION! exports:"

    let non-action-names: collect [
        for-each 'name exports-in-header [
            let ^value: get inside [] name
            if not action? opt ^value [
                keep name
                continue
            ]
            print [name opt unspaced [" - " description of ^value else [veto]]]
        ]
    ]

    print newline
    print "=== non-ACTION! exports:"

    for-each 'name non-action-names [
        print [name]
    ]

    print newline
]


=== ENTRY POINT ===

; If persistent information has been written into the browser local storage,
; retrieve it so that the user can continue where they left off.

if exists? %/credentials.r [
    let creds: load read %/credentials.r
    docname: creds.1.1
    docregistration: creds.1.2
    set-doc
    print ["Welcome" docname]
]

if exists? %/current.r [
    [current-location rx-template]: pack load %/current.r
    print ["You're practicing from" current-location]
    print ["Your prescription template is at" newline rx-template]
]

print ["Current Version:" form system.script.header.version]

; Make NEW-RX and HELP-RX more discoverable

print "help-rx for help on commands"

if find "yY" first ask ["New Script?" text!] [
    new-rx
]
