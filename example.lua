DBC_Lib = require("dbc_lib")
local items = DBC_Lib:new("../data/dbc/Item.dbc") -- Change for the path of our Item.dbc

-- Search by "hand"
 for _, item in pairs( items.data ) do
   print(item:GetClass())
end

-- "GetBy" method
local item = items:GetByID(17)
print(item:GetClass())

-- Fluent search "Where"
local query_result = items:Query():WhereClass(1):WhereSubClass(0)()
for _, query_item in pairs(query_result) do
   print(query_item:GetClass()) 
end