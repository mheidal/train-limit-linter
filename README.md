## Train Limit Linter

This mod provides an interface which allows a player to easily assess whether they have the proper number of trains with each schedule. This uses the concept of the [Fundamental Theorem of Train Limits](https://old.reddit.com/r/factorio/comments/skqzc5/a_fundamental_theorem_of_train_limits/), as posted on Reddit by /u/GBUS_TO_MTV. According to that theorem, in a many-to-many train network, where each station on that network has a train limit set, the number of trains should be equal to the sum of the train limits on all the stations, minus one. 

### Display
Train Limit Linter provides a GUI which displays all train schedules, how many trains have each schedule, and the sum of the train limits for all the stations on each schedule. It color-codes train schedules according to whether their train count conforms to the sum of the schedule's train limits. It displays what action would be necessary for a schedule to conform to the sum of its train limits. It provides a button which places a blueprint containing a copy of a train in each schedule into your cursor to allow you to quickly stamp down new trains.

### Keywords
Train Limit Linter allows the creation of lists of keywords which can be excluded or hidden in the Display tab (more on that below). Keyword lists can be converted into exchange strings which can be shared between players or save files.

#### Keyword exclusion
Train Limit Linter allows some customization of how train limit sums are calculated. It is possible through the `Exclude` tab to add excluded keywords. Train stations with excluded keywords in their name will not be counted when calculating train limit sums. For example, if a train schedule has the stops `Iron Ore Load`, `Iron Ore Byproduct Load`, and `Iron Ore Unload`, only one of each of those stops exists, and all stops have a train limit of 2, and the keyword `Byproduct` has been added, then the train limit sum displayed will be 4. If the keyword `Byproduct` has not been added or has been added and is disabled, the train limit sum displayed will be 6.

#### Keyword hiding
Train Limit Linter allows some customization of which schedules are displayed. It is possible through the `Hide` tab to add hidden keywords. If any station in a schedule contains a hidden keyword, that schedule will not be displayed in the `Display` tab.

### Settings
Train Limit Linter allows customization of the blueprints containing new trains that it creates, including the orientation of new trains, adding blueprint snapping, and adding fuel to locomotives. One can customize what fuels are added to locomotives, both fuel type and fuel amount. This can handle other mods, allowing one to select different fuels for each fuel category that any kind of locomotive consumes.

### Contact
For bug reports or feature suggestions, please make an issue on [the Github page](https://github.com/mheidal/train-limit-linter/). If you would like to contribute, please make a pull request. I would recommend that you contact me first to see if I already have anything in the works matching your idea. 
You can contact me on Discord `@notnot`. To message me you need to share a server with me. I expect that I will be in [the Factorio discord server](https://discord.com/invite/factorio) for the foreseeable future.

### License
This mod is licensed under MIT. This mod has some elements which are taken from or based on the [Factory Planner](https://github.com/ClaudeMetz/FactoryPlanner) mod by Therenas and the [Recipe Book](https://mods.factorio.com/mod/RecipeBook) mod by raiguard.