## Train Limit Linter

This mod provides an interface which allows a player to easily assess whether they have the proper number of trains with each schedule. This uses the concept of the [Fundamental Theorem of Train Limits](https://old.reddit.com/r/factorio/comments/skqzc5/a_fundamental_theorem_of_train_limits/), as posted on Reddit by /u/GBUS_TO_MTV. According to that theorem, in a many-to-many train network, where each station on that network has a train limit set, the number of trains should be equal to the sum of the train limits on all the stations, minus one. 

### Display
Train Limit Linter provides a GUI which displays all train schedules, how many trains have each schedule, and the sum of the train limits for all the stations on each schedule. It color-codes train schedules according to whether their train count conforms to the sum of the schedule's train limits. It displays what action would be necessary for a schedule to conform to the sum of its train limits. It provides a button which places a blueprint containing a copy of a train in each schedule into your cursor to allow you to quickly stamp down new trains.

### Keyword exclusion
Train Limit Linter also allows some customization of how train limit sums are calculated. It is possible through the `Exclude` tab to add excluded keywords. Train stations with excluded keywords in their name will not be counted when calculating train limit sums. For example, if a train schedule has the stops `Iron Ore Load`, `Iron Ore Byproduct Load`, and `Iron Ore Unload`, only one of each of those stops exists, and all stops have a train limit of 2, and the keyword `Byproduct` has been added, then the train limit sum displayed will be 4. If the keyword `Byproduct` has not been added, the train limit sum displayed will be 6.

### Keyword hiding
Train Limit Linter also allows some customization of which schedules are displayed. It is possible through the `Hide` tab to add hidden keywords. If any station in a schedule contains a hidden keyword, that schedule will not be displayed in the `Display` tab.

### Train fueling
Train Limit Linter also allows customization of the blueprints containing new trains that it creates. At the moment, one can choose to add fuel to new trains. In the future, more customization is planned.