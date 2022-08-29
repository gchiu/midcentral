# midcentral
Rx writing using ren-c JS console

A test repo to see if we can create a prescription from the clinical portal
Using the ren-c JS console
Your prescribing credentials are secured by your browser credentials (eg. gmail account).

# Use
http://hostilefork.com/media/shared/replpad-js/?import=rx

## First Use
Follow the prompts to add your name and prescriber ID number (Medical Council, or, Nursing Council)

## Enter Patient

* Either paste in demographics from Clinical Portal starting from surname to after home phone number
* Or, add them manually following the prompts

In both cases the data is saved to your browser cache to be used again when prescribing for this patient.
In that latter case you only need the NHI number

## Start Prescribing

### Find a Drug

* type `Rx ` followed by an apostrophe, and then the first character of the drug name, and then a * eg `'f*` which shows all the drugs in the system beginning with an `F`
  eg. `rx 'f*`
* A list of the drugs available will then be printed to the screen
* Select one to use, and then the available doses will be shown
* 0 means to cancel the prescription of this drug, and 1 more than the possible choice means use a manually entered dose.
To be contd
* -1 means reload the cache for this character
