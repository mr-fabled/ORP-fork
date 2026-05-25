<strong> #TODO: </strong> N/A

<b>
For the exporter change:
</b>

<pre>
<!-- necessary b/c it goes nil if you check a truss' shape -->
local shape = if obj:IsA("Part") then obj.Shape.Name else "Block"

local data = {
  ...
  Shape = shape,
}
</pre>
