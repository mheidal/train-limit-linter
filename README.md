## Train Limit Linter

This is a mod for the game [Factorio](https://factorio.com/). It is published on [the Factorio mod portal](https://mods.factorio.com/mod/train-limit-linter) in .zip format.

The mod provides an interface which allows a player to easily assess whether they have the proper number of trains with each schedule and deploy new trains quickly.

This uses the concept of the [Fundamental Theorem of Train Limits](https://old.reddit.com/r/factorio/comments/skqzc5/a_fundamental_theorem_of_train_limits/), as posted on Reddit by /u/GBUS_TO_MTV. According to that theorem, in a many-to-many train network, where each station on that network has a train limit set, the number of trains should be equal to the sum of the train limits on all the stations, minus one, i.e. P + R - 1.

### Display
Train Limit Linter provides a GUI, which is opened by default using `CONTROL + O` (the letter oh). That GUI provides the following functionalities:

- It displays all train schedules, how many trains have each schedule, and the sum of the train limits for all the stations on each schedule.

- In games with trains on multiple surfaces (for example, with the Space Exploration mod), train schedule groups are divided according to what surface their trains are on. The player can either display trains on all surfaces or on the player's current surface.

- Train schedules are color-coded according to whether their train count conforms to P + R - 1.

- If any train stop has no limit set or has a limit set dynamically using the circuit network, schedules which include that train stop will display a warning. Schedules with either of these conditions can be hidden.

- It displays what action would be necessary for each schedule to conform to P + R - 1. For example, it will say "Add 1 train" or "Remove 2 trains".

- Each schedule has a button which places a blueprint containing a copy of a train in the schedule into your cursor. This allows the user to quickly stamp down new trains. Certain aspects of the blueprints this generates can be modified in the Settings tab.

- It can show whether any train schedule groups have trains that are set to manual mode, and provides a button which pings all trains with that schedule in manual mode on the map.

### Keywords
Train Limit Linter allows the creation of lists of keywords which can be excluded or hidden. These keywords affect certain elements of the schedule display table in the Display tab, specifically how train limits are calculated and whether schedules are displayed. Keyword lists can be converted into exchange strings which can be shared between players or save files.

#### Keyword exclusion
Train Limit Linter allows some customization of how train limit sums are calculated. It is possible through the `Exclude` tab to add excluded keywords. Train stations with excluded keywords in their name will not be counted when calculating train limit sums. For example, if a train schedule has the stops `Iron Ore Load`, `Iron Ore Byproduct Load`, and `Iron Ore Unload`, only one of each of those stops exists, and all stops have a train limit of 2, and the keyword `Byproduct` has been added, then the train limit sum displayed will be 4. If the keyword `Byproduct` has not been added or has been added and is disabled, the train limit sum displayed will be 6.

#### Keyword hiding
Train Limit Linter allows some customization of which schedules are displayed. It is possible through the `Hide` tab to add hidden keywords. If any station in a schedule contains a hidden keyword, that schedule will not be displayed in the `Display` tab.

### Settings
Train Limit Linter allows customization of the blueprints containing new trains that it creates, including the orientation of new trains, adding blueprint snapping, and adding fuel to locomotives. One can customize what fuels are added to locomotives, both fuel type and fuel amount. This can handle other mods, allowing one to select different fuels for each fuel category that any kind of locomotive consumes.

### Contact
For bug reports or feature suggestions, please make an issue on [the Github page](https://github.com/mheidal/train-limit-linter/). If you would like to contribute, please make a pull request. I would recommend that you contact me first to see if I already have anything in the works matching your idea.

I would welcome help with localization.

You can contact me on Discord `@notnot`. To message me you need to share a server with me. I expect that I will be in [the Factorio discord server](https://discord.com/invite/factorio) for the foreseeable future.

### License
Train Limit Linter is licensed under MIT.

Train Limit Linter has some elements which are taken from or based on the [Factory Planner](https://github.com/ClaudeMetz/FactoryPlanner) mod by Therenas and the [Recipe Book](https://mods.factorio.com/mod/RecipeBook) and [flib](https://mods.factorio.com/mod/flib) mods by raiguard.

Train Limit Linter uses "Duster Icon #5827" from https://icon-library.com.
The icon can be found at https://icon-library.com/icon/duster-icon-8.html >Duster Icon # 5827
