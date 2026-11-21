-- v14 source registry structural check; no gameplay API calls.
local D={}
assert(loadfile("KordRotationDevTools/V14Registry.lua"))("KordRotationDevTools",D)
assert(#D.V14Registry==101)
local mapped,unknown=0,0
for i,item in ipairs(D.V14Registry) do
 assert(item.id==i,"wrong matrix row "..i)
 if item.method then
  assert(type(item.method)=="string" and item.method:match("^[A-Za-z_][A-Za-z0-9_.]*$"))
  mapped=mapped+1
 else unknown=unknown+1 end
end
assert(mapped==79 and unknown==22,"source matrix probe mapping changed")
print("PASS DevTools v14 registry: 101 rows, 79 presence-only, 22 UNKNOWN")
