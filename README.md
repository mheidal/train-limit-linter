## Train Limit Linter

This is a mod for the game [Factorio](https://factorio.com/). It is published on [the Factorio mod portal](https://mods.factorio.com/mod/train-limit-linter) in .zip format. The source code is visible on [the Github page](https://github.com/mheidal/train-limit-linter/).
The mod provides an interface which allows a player to easily assess whether they have the proper number of trains with each schedule and deploy new trains quickly.

This uses the concept of the [Fundamental Theorem of Train Limits](https://old.reddit.com/r/factorio/comments/skqzc5/a_fundamental_theorem_of_train_limits/), as posted on Reddit by /u/GBUS_TO_MTV. According to that theorem, in a many-to-many train network, where each station on that network has a train limit set, the number of trains should be equal to the sum of the train limits on all the stations, minus one, i.e. P + R - 1.

This mod is under active development. Features may be added or removed at any time. Screenshots of the GUI and this document might not be fully accurate.

### Display
Train Limit Linter provides a GUI, which is opened by default using `CONTROL + O` (the letter oh). That GUI provides the following functionalities:

- It displays all train schedules, how many trains have each schedule, and the sum of the train limits for all the stations on each schedule.

- In games with trains on multiple surfaces (for example, with the Space Exploration mod), train schedule groups are divided according to what surface their trains are on.

- Train schedules are color-coded according to whether their train count conforms to P + R - 1. It displays what action would be necessary for each schedule to conform to P + R - 1. For example, it will say "Add 1 train" or "Remove 2 trains".

- Each schedule has a button which places a blueprint containing a copy of a train in the schedule into your cursor. This allows the user to quickly stamp down new trains. Certain aspects of the blueprints this generates can be modified in the Settings tab.

- Schedules can be hidden if they meet any of the following conditions:

    - They are not on the player's current surface
    - They conform to P + R - 1 (so no action is required)
    - They contain a train stop with no limit set
    - They contain a train stop with a limit set dynamically using the circuit network
    - They only contain one train stop

### Keywords
Train Limit Linter allows the creation of lists of keywords which can be excluded or hidden. These keywords affect certain elements of the schedule display table in the Display tab, specifically how train limits are calculated and whether schedules are displayed. Keyword lists can be converted into exchange strings which can be shared between players or save files.

#### Keyword exclusion
Train Limit Linter allows some customization of how train limit sums are calculated. It is possible through the `Exclude` tab to add excluded keywords. Train stations with excluded keywords in their name will not be counted when calculating train limit sums. For example, if a train schedule has the stops `Iron Ore Load`, `Iron Ore Byproduct Load`, and `Iron Ore Unload`, only one of each of those stops exists, and all stops have a train limit of 2, and the keyword `Byproduct` has been added, then the train limit sum displayed will be 4. If the keyword `Byproduct` has not been added or has been added and is disabled, the train limit sum displayed will be 6.

#### Keyword hiding
Train Limit Linter allows some customization of which schedules are displayed. It is possible through the `Hide` tab to add hidden keywords. If any station in a schedule contains a hidden keyword, that schedule will not be displayed in the `Display` tab.

### Settings
Train Limit Linter allows the creation of blueprints using the "Copy" button in the schedule report table in the `Display` tab. These blueprints contain a copy of a train with the given schedule. These blueprints can be customized in several ways:
- The trains can be oriented in any cardinal or half-cardinal direction by default.
- The blueprints can snap to the grid.
- The blueprints can include copies of train stops that the schedule visits, with the ability to customize what train limits these stops include.

These blueprints can contain fuels which construction robots will insert into locomotives when the train is built. One can customize what fuels are added to locomotives, both fuel type and fuel amount. This can handle other mods, allowing one to select different fuels for each fuel category that any kind of locomotive consumes.

### Compatibility
To request compatibility with another mod, please [make an issue on the Github page](https://github.com/mheidal/train-limit-linter/issues/new) or [make a new thread on the forum](https://mods.factorio.com/mod/train-limit-linter/discussion/new).

Train Limit Linter is compatible with mods that add new types of vehicle fuel and new types of locomotives or wagons.

#### [Train Groups by raiguard](https://mods.factorio.com/mod/TrainGroups)
Train Limit Linter is compatible with Train Groups. When generating a blueprint for a train, the new train will share a train group with the template train. This behavior can be  toggled. This behavior is not guaranteed to work if not all trains with a particular schedule are part of the same train group by Train Groups's definition.

### Contact
For bug reports or feature suggestions, please [make an issue on the Github page](https://github.com/mheidal/train-limit-linter/issues/new). 

If you would like to contribute new features or localizations, please [make a pull request on the Github page](https://github.com/mheidal/train-limit-linter/pulls). I would recommend that you contact me first to see if I already have anything in the works matching your idea.

You can contact me on Discord `@notnot`. To message me you need to share a server with me. I expect that I will be in [the Factorio discord server](https://discord.com/invite/factorio) for the foreseeable future.

### License
Train Limit Linter is licensed under MIT.

Train Limit Linter has some elements which are taken from or based on the [Factory Planner](https://github.com/ClaudeMetz/FactoryPlanner) mod by Therenas and the [Recipe Book](https://mods.factorio.com/mod/RecipeBook) and [flib](https://mods.factorio.com/mod/flib) mods by raiguard.

Train Limit Linter uses "Duster Icon #5827" from https://icon-library.com.
The icon can be found at https://icon-library.com/icon/duster-icon-8.html >Duster Icon # 5827
