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
Train Limit Linter allows the creation of lists of keywords which can be excluded or hidden. These keywords affect certain elements of the schedule display table in the Display tab, specifically how train limits are calculated and whether schedules are displayed. Keyword lists can be converted into exchange strings which can be shared between players or save files. Keywords can be enabled or disabled to allow you to quickly toggle their changes to the schedule display table without having to delete them and type them back in. Also, keywords can be toggled between requiring a train station to exactly match the keyword or requiring the keyword to be a substring of the train station to affect the schedule display table.

#### Keyword exclusion
Train Limit Linter allows some customization of how train limit sums are calculated. It is possible through the `Exclude` tab to add excluded keywords. Train stations with names matching excluded keywords will not be counted when calculating train limit sums or when determining which trains are part of the same group, and will not cause various warnings to appear, such as warnings for if a train station has no limit set, has a limit set dynamically, or does not exist at the moment.

Excluding keywords is meant to be useful when there may be stops on a train's schedule which are not "really" part of the schedule; for example, other mods may inject stops on a train's schedule where they can resupply with fuel, or a train may have a stop acting as a waypoint which it must travel through but at which the train is not required to stop.

For example, if a train schedule has the stops `Iron Ore Load`, `Fuel Resupply`, and `Iron Ore Unload`, only one of each of those stops exists, and all stops have a train limit of 2, and the keyword `Fuel Resupply` has been added to the excluded keyword list, then the train limit sum displayed will be 4. If the keyword `Fuel Resupply` has not been added to the excluded keyword list or has been added and is disabled, the train limit sum displayed will be 6.

Another example: In a situation with the same train stops (`Iron Ore Load`, `Fuel Resupply`, and `Iron Ore Unload`), if one train has a schedule which visits `Iron Ore Load` and `Iron Ore Unload` (and does not visit `Fuel Resupply`), and another train has a schedule which visits `Iron Ore Load`, `Fuel Resupply`, and `Iron Ore Unload`, and the keyword `Fuel Resupply` has been added to the excluded keyword list and is not disabled, the two trains will be considered to be part of the same group, since their schedules match except for the excluded stop.

Temporary stops are always considered to be excluded.

#### Keyword hiding
Train Limit Linter allows some customization of which schedules are displayed. It is possible through the `Hide` tab to add hidden keywords. If any station in a schedule matches a hidden keyword, that schedule will not be displayed in the `Display` tab.

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

#### Mods which inject stations into schedules temporarily
This includes [Train Control Signals by Klonan](https://mods.factorio.com/mod/Train_Control_Signals) and [Automatic Train Fuel Stop by magu5026](https://mods.factorio.com/mod/FuelTrainStop), and possibly others.

Train Control Signals adds virtual signals which can be added to train stop names to mark them as skippable depending on a couple of conditions. To let Train Limit Linter know that those train stops are not "really" part of a train's schedule, add the virtual signals to the excluded keyword list.

Automatic Train Fuel Stop can temporarily inject refuel train stops into a train's schedule. To let Train Limit Linter know that these train stops are not "really" part of a train's schedule, add the name of the refuel train stops to the excluded keyword list.

Other mods which inject train stops into a train's schedule can be handled in a similar fashion.

#### LTN and Cybersyn 
Train Limit Linter is not designed to use train networks in the same way as [LTN - Logistic Train Network by Optera](https://mods.factorio.com/mod/LogisticTrainNetwork) and [Project Cybersyn by lesbian_mami](https://mods.factorio.com/mod/cybersyn), which constantly modify train schedules so that the rule of conforming to P + R - 1 is not necessary. Therefore, Train Limit Linter does not display trains which are controlled by LTN or Cybersyn. Train Limit Linter can be used alongside those mods, if some trains are controlled by either LTN or Cybersyn and some trains are not.

A train is considered to be controlled by LTN if any station that it visits is an LTN station (or shares a name with an LTN station.)

A train is considered to be controlled by Project Cybersyn if it visits any station which is controlled by a cybernetic combinator.

### Contact
For bug reports or feature suggestions, please [make an issue on the Github page](https://github.com/mheidal/train-limit-linter/issues/new). 

If you would like to contribute new features or localizations, please [make a pull request on the Github page](https://github.com/mheidal/train-limit-linter/pulls). I would recommend that you contact me first to see if I already have anything in the works matching your idea.

You can contact me on Discord `@notnot`. To message me you need to share a server with me. I expect that I will be in [the Factorio discord server](https://discord.com/invite/factorio) for the foreseeable future.

### License
Train Limit Linter is licensed under MIT.

Train Limit Linter has some elements which are taken from or based on the [Factory Planner](https://github.com/ClaudeMetz/FactoryPlanner) mod by Therenas, the [Recipe Book](https://mods.factorio.com/mod/RecipeBook) and [flib](https://mods.factorio.com/mod/flib) mods by raiguard, and the [Krastorio2](https://mods.factorio.com/mod/Krastorio2) mod by raiguard, Krastor, and Linver.

Train Limit Linter uses "Duster Icon #5827" from https://icon-library.com.
The icon can be found at https://icon-library.com/icon/duster-icon-8.html >Duster Icon # 5827
