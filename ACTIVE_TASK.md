# Current Task: Restoring Lab Boundaries (Safe Container Wrap)

## Objective
Reintroduce the 1px solid black border around each Lab's desk blocks without disrupting the perfect horizontal Aisle synchronization.

## Steps
1. **The Wrapper:** Wrap the desk grid (and internal aisles) of each lab inside a `Container` with `border: Border.all(color: Colors.black, width: 1)`.
2. **Uniform Padding:** Apply a strict, uniform padding to EVERY Lab Container (e.g., `padding: EdgeInsets.all(12.0)`). 
   * *Why:* If L1 and L3 have the exact same padding, their top blocks will remain perfectly level.
3. **External Labels:** Keep the `Text('Lab X')` widgets OUTSIDE and ABOVE the bordered containers. Do not put them back inside.
4. **The Anchor Check:** Ensure the distance between the Lab 3 container and the Lab 4 container is mathematically calculated so that `L4_T01` remains perfectly level with `L1_T33`.