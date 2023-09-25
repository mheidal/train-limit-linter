Open an interface. That interface has: 
1. Button: Give a list of station sets which currently don't have a sufficient number of trains (calc. using FTTL)
2. Button: Create a blueprint book with blueprints containing one train each which fills the station sets with insufficient trains.
3. Textfield: String which is excluded when considering station set train limits

This requires:
1. Identification of station sets
    a. Organize all trains into groups according to their schedules
    b. Get lists of train stations from schedules
        i. Optionally exclude stations with a particular string in their name? For "byproduct"?
2. Identification of FTTL variables
    a. Sum of train station train limits
    a. Number of trains belonging to each station set
3. Creation of station