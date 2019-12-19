# socialism
Socialism simulator, can be deployed as website.

## Deploy
[![Run on Repl.it](https://repl.it/badge/github/gxm11/socialism)](https://repl.it/github/gxm11/socialism)

## Design
### Village
1. City Level, `Lc`, init = 1
2. Farm Level, `Lf`, init = 1
3. Food Storage, `F`, init = 0
4. Population, `P`, init = 5

### Farmer
1. Farmerd have their own food, `f`.
2. The daily food cost is `Lc`.
3. The work power is `a`, init = [rand, rand, rand]
4. Each time the work power has probability `1/Lc` to increase `1 - a / Lc`, but cost 1 more daily food.
5. Who the food becomes negative doesn't do anything but apply for relief food. If the Alms is less than the lack of food, the farmer is lost.

### Actions
Three base actions, also player can mix them into different action.

1. Plant, gain food `f += a * sqrt(Lf) * p`
  - p is the penalty factor, p = tanh(Pp / Lf - 1) / (Pp / Lf - 1)
  - Pp is number of people who choose plant as action.
2. Reclaim, increase farm level `Lf += a / Lf`
3. Research, increase city level `Lc += a / Lc / Lc`, cost `Lc` times daily food. Max city level is `Lc + 1`.

If a mixed action is like `[x, y, z]`, it will:

1. Gain food: `x * a * sqrt(Lf) * p`
  - Pp = sum(x)
2. Increase farm: `y * a / Lf`
3. Increase city: `z * a / Lc / Lc`
4. Base cost is `Lc + z * Lc * Lc`
5. Has probability `1/Lc` to increase the `max(x, y, z)` work power for `1 - a / Lc`
6. If 5 happends, cost another `Lc` food.

### Policies
**Population**

name|food cost|description
-|-|-
new citizen|`Lc`|move in a new citizen
kick citizen|`Lc`|banish a citizen, confiscate his food.
upgrade city|`P * Lc`|+1 city level. `Lc` must reached its upper limit.

**Action**
There're 3 base actions and some self-defined actions.

The number of extra actions is limited to the city level `Lc`.

**Economic**
1. Awards for each action.
2. Alms for hungry people.
3. Welfare for every one.

- Economic policies is free to apply.
