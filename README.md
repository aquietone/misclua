# misclua

Random lua scripts

# atenslience

Run on all characters.  
Will run non-MA characters to the door when green circle silence happens if the MA is targeted.
Will run targeted character to the  door when green circle silence happens if targeted character is not the MA.
Beeps meanly at you if no MA is set.
Ends when Aten Ha Ra dies.

# sheiroot

Run on cleric or shaman only.
Will set CWTN plugin BYOS on and for shaman also memcureall on.
Mems blood of mayong in gem 6 for shaman and shackle in gem 13 for both cleric and shaman.
Casts shackle on any red alien spawns.
Casts cures on any targeted character in the group. Curing is handled by the script since the plugin won't cure other peoples characters.

# eval

Like the macro expression evaluator, but for displaying lua parse values. I don't recommend running this code as its got deprecated, insecure calls being used, like `loadstring`.

![](images/eval.png)

# find

Like the find item window from live, but for emu since it doesn't have one. It will error if you put funny characters in the filter that are also string pattern characters like `[`. It only shows items in bags, inventory slots, bank and shared bank. It doesn't show augs in items.

![](images/find.png)

# uisample

A very simplistic UI script to just create a single empty ImGui window.

