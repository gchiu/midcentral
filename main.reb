Rebol [
    type: module
    author: "Graham Chiu"
    Version: 1.0.45
    exports: [
        add-form ; puts JS form into DOM
        add-content ; adds content to the form
        choose-drug ; pick drug from a selection
        clear-cache ; remove the drug caches
        clear-form ; clears the script
        clear-rx ; clears the drugs but leaves patient
        configure ; sets up the url to be used for the prescription
        cdata ; the JS that will be executed
        expand-latin ; turns abbrevs into english
        grab-creds ; gets credentials
        manual-entry ; asks for patient demographics
        new-rx ; start a new prescription
        parse-demographics ; extracts demographics from clinical portal details
        rx ; starts the process of getting a drug schedule
        rxs ; block of rx
        set-doc ; fills the wtemplate with current doc
        write-rx ; sends to docx
        street town city
        docname
        docregistration
        parse-referral
    ]
]

=== CUSTOMIZATIONS THAT SHOULD BE IN A COMMON "LIBCHIU" LIBRARY ===

; Customize FUNC to not require a RETURN--result drops out of body by default
; https://forum.rebol.info/t/1656/2
'
func: adapt :lib.func [body: compose [return (as group! body)]]
function: adapt :lib.function [body: compose [return (as group! body)]]
meth: enfix adapt :lib.meth [body: compose [return (as group! body)]]


=== LIBRARIES ===

import @popupdemo

for-each site [
    https://cdnjs.cloudflare.com/ajax/libs/docxtemplater/3.29.0/docxtemplater.js
    https://unpkg.com/pizzip@3.1.1/dist/pizzip.js
    ; https://cdnjs.cloudflare.com/ajax/libs/jszip/2.6.1/jszip.js
    https://cdnjs.cloudflare.com/ajax/libs/FileSaver.js/1.3.8/FileSaver.js
    https://unpkg.com/pizzip@3.1.1/dist/pizzip-utils.js
    ; https://cdnjs.cloudflare.com/ajax/libs/jszip-utils/0.0.2/jszip-utils.js
][
    js-do site
]


=== GLOBAL DEFINITIONS ===

root: https://github.com/gchiu/midcentral/blob/main/drugs/
raw_root: https://raw.githubusercontent.com/gchiu/midcentral/main/drugs/ ; removed html etc

slotno: 6
rx-template: https://metaeducation.s3.amazonaws.com/rx-6template-docx.docx
rxs: []
firstnames: surname: dob: title: nhi: rx1: rx2: rx3: rx4: rx5: rx6: street: town: city: docname: docregistration: _
wtemplate: _
old_patient: _
eol: charset [#"^/" #","] ; used to parse out the address line

dgh: {This Prescription meets the requirement of the Director-General of Health’s waiver of March 2020 for prescriptions not signed personally by a prescriber with their usual signature}


=== MAIN SCRIPT ===

js-do {window.loadFile = function(url,callback){
        PizZipUtils.getBinaryContent(url,callback);
    };
}

cdata: {window.generate = function() {
        loadFile("$docxtemplate",
    function(error,content){
            if (error) { throw error };
            var zip = new PizZip(content);
            // var doc=new window.docxtemplater().loadZip(zip)
        var doc = new window.docxtemplater(zip, {
                        paragraphLoop: true,
                        linebreaks: true,
                    });
            try {
                // render the document (replace all occurences of {first_name} by John, {last_name} by Doe, ...)
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
                console.log(JSON.stringify({error: e}));
                // The error thrown here contains additional information when logged with JSON.stringify (it contains a property object).
                throw error;
            }
            var out=doc.getZip().generate({
                type:"blob",
                mimeType: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            }) //Output the document using Data-URI
            saveAs(out,"$prescription.docx")
        })
    };
    generate()
}

js-button: {<input type="button" id="copy NHI" value="Copy NHI" onclick='reb.Elide("write clipboard:// {$a}")' />}

configure: func [
    return: <none>
    <local> config url loc i
][
    config: if exists? %/configuration.reb [
        load %/configuration.reb
    ] else [
        save %/configuration.reb load https://raw.githubusercontent.com/gchiu/midcentral/main/templates/sample-config.reb
        ; load %/configuration.reb
    ]
    print "Current locations"
    i: 1
    for-each [name url] config [
        print [i name]
        i: me + 1
    ]
    choice: ask ["select location (use 0 to add more locations):" integer!]
    choice: choice * 2 - 1
    dump choice
    choice: pick config choice
    dump choice
    ?? choice
    dump config
    print form type-of choice
    if any [url? choice text? choice] [
        rx-template: select config choice
        save %current.reb reduce [choice rx-template]
        return
    ]
    cycle [
        if empty? loc: ask ["Enter consulting location name:" text!][break]
        url: ask ["Enter URL for the prescription template:" url!]
        if error? trap [read url][
            print "This location is not available"
            continue
        ] else [
            if #"y" = lowercase first ok: ask ["Okay?" text!][
                append config spread [loc url]
            ]
        ]
    ]
    save %/configuration.reb config
]

set-doc: does [
    wtemplate: copy template
    wtemplate: reword wtemplate reduce ['docname docname 'docregistration docregistration 'signature docname] ; 'date now/date]
    ; probe wtemplate
]

grab-creds: func [ <local> docnames docregistrations] [
    cycle [
        docnames: ask ["Enter your name as appears on a prescription:" text!]
        docregistrations: ask ["Enter your prescriber ID number:" integer!]
        response: lowercase ask ["Okay?" text!]
        if find ["yes" "y"] response [
            set 'docname :docnames
            set 'docregistration :docregistrations
            break
        ]
    ]
    set-doc
    ; probe wtemplate
    write %/credentials.reb mold reduce [docname docregistration]
    return
]

expand-latin: func [sig [text!]
    <local> data
][
    data: [
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
        replace/all sig unspaced [space abbrev space] unspaced [space expansion space]
        replace/all sig unspaced [space abbrev newline] unspaced [space expansion newline]
    ]
    return sig
]

add-form: does [
    show-dialog/size {<div id="board" style="width: 400px"><textarea id="script" cols="80" rows="80"></textarea></div>} 480x480
]

clear-form: does [
    js-do {document.getElementById('script').innerHTML = ''}
    set-doc
]

add-content: func [txt [text!]
][
    txt: append append copy txt newline newline
    js-do [{document.getElementById('script').innerHTML +=} spell @txt]
]

choose-drug: func [scheds [block!] filename
    <local> num choice output rx sig mitte drugname drug dose
][
    num: length-of scheds
    choice: ask ["Which schedule to use?" integer!]
    if choice = 0 [return]
    if choice = -1 [delete filename, print "Cache deleted, try again" return]
    if choice <= num [
        print output: expand-latin pick scheds choice
        add-content output
        append rxs output
        return
    ]
    ; out of bounds
    output: pick scheds 1
    drugname: _
    ; first off, get any drugs that start with a digit eg. 6-Mercaptopurine
    parse output [drugname: across some digit, output: across to <end>]
    if empty? drugname [
        ; not a drug that starts with a digit
        drugname: copy ""
    ] ; otherwise drugname = "6" etc
    ; now get the rest of the drugname
    parse output [drug: across to digit, to <end> (append drugname drug)]
    ; so we now have the drugname
    ; so let's ask for the new dose
    cycle [
        dose: ask compose [(spaced ["New Dose for" drugname]) text!]
        sig: ask ["Sig:" text!]
        mitte: ask ["Mitte:" text!]
        response: copy/part lowercase ask ["Okay?" text!] 1
        if response = "y" [break]
    ]
    output: expand-latin spaced [drugname dose "^/Sig:" sig "^/Mitte:" mitte]
    add-content output
    append rxs output
    return
]

comment {
>>>>>>>> example below this line

ASurname, Basil Phillip (Mr)

BORN16-Aug-1925 (96y)GENDER Male

NHIABC1234



    

Address  29 Somewhere League, Middleton, NEW ZEALAND, 4999

Home  071234567
<<<<<<<< above this line
}

whitespace: charset [#" " #"^/" #"^M" #"^J"]
alpha: charset [#"A" - #"Z" #"a" - #"z"]
digit: charset [#"0" - #"9"]
nhi-rule: [repeat 3 alpha, repeat 4 digit]
digits: [some digit]

template: {
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
}

parse-demographics: func [
    <local> data demo js
][
    demo: ask ["Paste in demographics from CP" text!]
    parse demo [
        (home: phone: mobile: email: _)
        [maybe some whitespace]
        surname: across to ","
        thru space [maybe some space]
        [firstnames: across to "("] (trim/head/tail firstnames)
        thru "(" title: across to ")"  ; `title: between "(" ")"`
        thru "BORN" dob: across to space
        thru "(" age: across to ")"    ; `age: into between "(" ")" integer!`
        thru "GENDER" maybe some space gender: across some alpha
        thru "NHI" nhi: across nhi-rule
        thru "Address" [maybe some whitespace] opt "Address" opt space street: across to eol (?? street ?? 1)
        thru some eol [maybe some whitespace] town: across to eol (?? 2 ?? town)
        thru some eol [maybe some whitespace] city: across to eol (?? 3 ?? city)
        [thru "Home" (?? 4)
            | thru "Mobile" (?? 5)
            | thru "EMAIL" (?? 50) maybe some whitespace email: across to space return true
            | thru "Contact – No Known Contact Information" (?? 6) to <end> (print "Incomplete Demographics") return true
        ] [maybe some whitespace]
        phone: across some digit (?? 51 ?? phone)
        opt [
            thru some eol thru "Mobile" maybe some whitespace mobile: across some digit (?? 6 ?? mobile)
            thru some eol opt [thru "Email" maybe some whitespace email: across to space (?? 7 ?? email)]
        ]
        to <end>
    ] else [
        print "Could not parse demographic data"
        return
    ]
    if nhi = old_patient [
        response: lowercase ask compose [(spaced ["Do you want to use this patient" surname "again?"]) text!]
        if response.1 <> #"y" [
            return
        ]
    ]
;comment {
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
;}
    clear-form
    data: unspaced [
        surname "," firstnames space "(" maybe title ")" space "DOB:" space dob space "NHI:" space nhi newline
        street newline town newline city newline newline
        "phone:" space maybe phone newline
        "mobile:" space maybe mobile newline
        "email:" space maybe email
    ]
    phone: default [blank]
    mobile: default [blank]
    email: default [blank]
    wtemplate: reword wtemplate reduce ['firstnames firstnames 'surname surname 'title title 'street street 'town town 'city city 'phone phone
        'dob dob 'nhi nhi
        'prescription nhi
    ]
    old_patient: copy nhi
    ; probe wtemplate
    write to file! unspaced ["/" nhi %.reb] mold compose [
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
    js: copy js-button
    replace js "$a" nhi
    replpad-write/html js
    print unspaced ["saved " "%/" nhi %.reb ]
]

manual-entry: func [
    <local> filename filedata response js
][
    print "Enter the following details:"
    nhi: uppercase ask ["NHI:" text!]
    if word? exists? filename: to file! unspaced [ "/" nhi %.reb][
        filedata: load to text! read filename
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
            response: lowercase ask ["OK?" text!]

            if response.1 = #y [break]
        ]
    ]
    comment {
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
    }
    data: unspaced [ surname "," firstnames space "(" title ")" space "DOB:" space dob space "NHI:" space nhi newline street newline town newline city newline newline]
    wtemplate: reword wtemplate reduce ['firstnames firstnames 'surname surname 'title title 'street street 'town town 'city city 'phone phone
        'dob dob 'nhi nhi
        'prescription nhi
    ]
    ; probe wtemplate
    write to file! unspaced ["/" nhi %.reb] mold compose [
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
    js: copy js-button
    replace js "$a" nhi
    replpad-write/html js
    print unspaced ["saved " "%/" nhi %.reb ]
]

rx: func [ drug [text! word!]
    <local> link result c err counter line drugs filename rxname mitte sig response dose local?
][
    local?: false
    drug: form drug
    ; search for drug in database, get the first char
    c: form first drug
    filename: to file! unspaced ["/" c %.reb]
    link: to url! unspaced [raw_root c %.reb]
    ;dump link
        if exists? filename [
            data: first load filename
            print "loaded off local storage"
            local?: true
            ; dump data
        ] else [
            ;dump filename
            ;dump link
            if not null? err: trap [
                data: load link
                save/all filename data
                data: data.1
                ; dump data
                prin "Datafile loading ... "
            ][
                print spaced ["This page" link "isn't available, or, has a syntax error"]
                ; probe err
                return
            ] else [print "and cached"]
        ]
        if drug.2 = #"*" [
            ; asking for what drugs are available
            counter: 0 line: copy [] drugs: copy []
            for-each item data [
                if text? item [append line item]
                if block? item [
                    counter: me + 1
                    insert head line form counter
                    print line
                    clear head line
                    append drugs lastitem
                ]
                lastitem: copy item
            ]
            response: ask compose [(join "0-" counter) integer!]
            case [
                all [response > 0 response <= counter][drug: pick drugs response]
                response = 0 [return]
                response = -1 [delete filename rx drug] ; deletes cache and reloads it
                true [
                    cycle [
                        rxname: ask ["Rx:" text!]
                        sig: ask ["Sig:" text!]
                        mitte: ask ["Mitte:" text!]
                        response: first lowercase ask ["Okay?" text!]
                        if response = #"y" [break]
                    ]
                    output: expand-latin spaced ["Rx:" rxname "^/Sig:" sig "^/Mitte:" mitte]
                    add-content output
                    append rxs output
                    return
                ]
            ]
        ]
        ; dump drug
        ; dump data
        if null? result: switch drug data [; data comes from import link
            print spaced ["Drug" drug "not found in database."]
            if local? [ ; means we used the cache, so let's fetch the original file
                if not null? err: trap [
                    data: load link
                    save/all filename data
                    data: data.1
                    ; dump data
                    prin "Datafile loading ... "
                    if find data drug [rx drug return]
                ][ print "And there's no file online"]
            ]
            print ["You can submit a PR to add them here." https://github.com/gchiu/midcentral/tree/main/drugs ]
        ] else [
            if 0 < len: length-of result [
                print newline
                for i len [print form i print result.:i print newline]
                choose-drug result filename
            ]
        ]
    return
]

clear-rx: func [ <local> data ][
    clear-form
    ; probe wtemplate
    ; ?? nhi
    ; ?? firstnames
    data: unspaced [ surname "," firstnames space "(" title ")" space "DOB:" space dob space "NHI:" space nhi newline street newline town newline city newline newline]
    wtemplate: reword wtemplate reduce ['firstnames firstnames 'surname surname 'title title 'street street 'town town 'city city 'phone phone
        'dob dob 'nhi nhi
        'prescription nhi
    ]
    ; probe wtemplate
    add-content data
    ; add-content unspaced [ surname "," firstnames space "(" title ")" space "DOB:" space dob space "NHI:" space nhi newline street newline town newline city newline newline]
    clear rxs
    print "Ready for another Rx"
]

write-rx: func [
    <local> codedata response
] [
    ; append/dup rxs space slotno
    codedata: copy cdata
    replace codedata "$template" wtemplate
    replace codedata "$docxtemplate" rx-template
    replace codedata "$prescription" unspaced [nhi "_" now/date]
    codedata: reword codedata reduce ['rx1 rxs.1 'rx2 any [rxs.2 space] 'rx3 any [rxs.3 space] 'rx4 any [rxs.4 space] 'rx5 any [rxs.5 space] 'rx6 any [rxs.6 space]]
    codedata: reword codedata reduce compose ['date (spaced [now/date now/time])]
    response: lowercase ask ["For email?" text!]
    codedata: reword codedata reduce compose ['dgh (if response.1 = #"y" [dgh] else [" "])]
    ;probe copy/part codedata 200
    ;dump rx-template
    js-do codedata
]

new-rx: does [
    if empty? docname [
        grab-creds
    ]
    rxs: copy []
    set-doc
    add-form
    response: lowercase ask ["Paste in Patient Demographics from Clinical Portal? (y/n)" text!]
    if response.1 = #y [
        parse-demographics
    ] else [
        cls ; clears the screen for the Cypress testing
        manual-entry
    ]
    print {"Use Rx" to add a drug to prescription}
]

clear-cache: func [
    <local> alphabet file
][
    alphabet: "abcdefghijklmnopqrstuvwxyz"
    for i 26 [
        attempt [
            delete file: to file! unspaced [ "/" alphabet.:i %.reb]
            print ["Deleted" file]
        ]
    ]
]

; print "checking for %/credentials.reb"

if word? exists? %/credentials.reb [
    creds: load read %/credentials.reb
    docname: creds.1.1
    docregistration: creds.1.2
    set-doc
    print ["Welcome" docname]
]

if word? exists? %/current.reb [
    [current-location rx-template]: pack load %/current.reb
    print ["You're practicing from" current-location]
    print ["Your prescription template is at" newline rx-template]
]

print ["Current Version:" form system.script.header.Version]

;; ===== other parse tools ==================

parse-referral: func [
    <local> data fname sname nhi dob gender email mobile street suburb city zip
][
    data: ask ["Paste in Specialist Referral Demographics" text!]
    fname: sname: nhi: dob: gender: email: mobile: street: suburb: city: zip: _
    parse data [
        thru "Name" thru ":" maybe some whitespace fname: across to space some space sname: across to "NHI"
        (trim sname)
        thru ":" some space nhi: across nhi-rule thru eol
        thru "Date Of Birth" thru ":" maybe some space dob: across to space thru "Gender" thru ":" maybe some space
        gender: between <here> eol
        thru "Email" thru ":" maybe some space email: between <here> eol
        thru "Mobile" thru ":" maybe some space mobile: between <here> eol
        thru "Residential Address" thru ":" maybe some space street: between <here> "," suburb: between <here> ","
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

;; ==========lab form tools =================================================

medical: biochem: serology: other: micro: doccode: _

okay?: func [<local> response][
    return find "yY" first response: ask ["Okay?" text!]
]

clinical: func [][
    medical: ask ["Enter clinical details including periodicity" text!]
    if not yn [clinical]
]

bio: func [][
    print "1. Creatinine, LFTs, CRP"
    print "2. CPK"
    print "3. "Serum Uric Acid"
    biochem: ask ["Enter biochemistry requests" text!]
    if not okay? [bio]
    replace biochem "1" "Creatinine, LFTs, CRP,"
    replace biochem "2" "CPK"
    replace biochem "3" "Serum Uric Acid"
]

sero: func [][
    print {1. ANA ENA
2. ds-DNA
3. Complement
4. Cardiolipin, Lupus Anticoagulant, B2-glycoprotein Antibodies
5. Extended scleroderma blot
6. Scl-70 by immunodiffusion
}
    serology: ask ["Enter serology requests" text!]
    if not okay? [sero]
    replace sero "1" "ANA ENA"
    replace sero "2" "ds-DNA"
    replace sero "3" "Complement"
    replace sero "4" "Cardiolipin, Lupus Anticoagulant, B2-glycoprotein Antibodies"
    replace sero "5" "Extended scleroderma blot"
    replace sero "6" "Scl-70 by immunodiffusion"
]

oth: func [][
    other: ask ["Enter other requests" text!][
    if not okay? [oth]
]

if find "yY" first ask ["New Script?" text!][new-rx]
