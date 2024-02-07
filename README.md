# LuaDBC 🚀
Welcome to LuaDBC, your go-to library for reading World of Warcraft DBC files effortlessly! 🌍⚙️

## Table of Contents 📑
- [Introduction](https://github.com/vaiocti/lua_dbc_lib/tree/main?tab=readme-ov-file#introduction-)
- [Getting Started](https://github.com/vaiocti/lua_dbc_lib/tree/main?tab=readme-ov-file#getting-started-)
- [Usage](https://github.com/vaiocti/lua_dbc_lib/tree/main?tab=readme-ov-file#usage-)
- [Todo](https://github.com/vaiocti/lua_dbc_lib/tree/main?tab=readme-ov-file#todo-)
- [Dependencies](https://github.com/vaiocti/lua_dbc_lib/tree/main?tab=readme-ov-file#dependencies-)
- [Contributing](https://github.com/vaiocti/lua_dbc_lib/tree/main?tab=readme-ov-file#contributing-)

## Introduction 🌟
LuaDBC is a Lua library designed to simplify the reading of World of Warcraft DBC files. It utilizes the power of LuaRocks with two essential modules - `lanes` and `struct`. 🛠️

# Getting Started 🚀
To start using LuaDBC in your project, follow these simple steps:

- Install LuaRocks: [LuaRocks Installation Guide](https://github.com/luarocks/luarocks/wiki/Download)
- Install required modules:
```
luarocks install lanes
luarocks install struct
```
- Include LuaDBC in your project.

## Usage 📦
```lua
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
```

# Todo 📝
- Write to DBC: Implement the ability to write data to the end of a DBC file.
- Delete Rows: Allow for the deletion of specific rows within a DBC file.
- Auto-generate DBC: Explore the option of auto-generating a DBC file based on a database.
- Update Data: Provide functionality to update existing data within DBC files.
- Multiple Loc Columns: Enhance compatibility to read DBCs with multiple Loc columns (Loc[1-x]).

## Dependencies 🌐
- [LuaRocks](https://github.com/luarocks/luarocks)
- [Lanes](https://luarocks.org/modules/benoitgermain/lanes)
- [Struct](https://luarocks.org/modules/luarocks/struct)

Make sure to install these dependencies using LuaRocks before integrating LuaDBC into your project.

## Contributing 🤝
Contributions are welcome! If you have any improvements or bug fixes, feel free to submit a pull request.
