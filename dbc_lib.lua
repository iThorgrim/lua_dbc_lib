local struct = require("struct")
local lanes  = require("lanes")

local function ToCamelCase(str)
    return (str:gsub('_(%l)', function (x) return x:upper() end))
end

local Query = {}
function Query.__index(self, key)
    if string.sub(key, 1, 5) == "Where" then
        local targetField = string.sub(key, 6)
        return function(self, value)
            local filtered = {}
            for _, record in ipairs(self.data) do
                if record[targetField] == value then
                    table.insert(filtered, record)
                end
            end
            self.data = filtered
            return self
        end
    end
end

function Query:new(data)
    local instance = {
        data = data,
    }
    setmetatable(instance, { __index = Query.__index, __call = function(self) return self.data end })
    return instance
end

local DBC = { }
function DBC:new( data )
    local instance = { }
    
    for name, value in pairs(data) do
        instance[name] = value
        local camel_name = ToCamelCase(name:sub(1,1):upper() .. name:sub(2))
        
        local get = "Get" .. camel_name
        instance[get] = function (self)
            return self[name]
        end
    end
    
    setmetatable(instance, self)
    return instance
end

local DBC_Lib = { }
DBC_Lib.__index = DBC_Lib

local function read_header(file)
    local magic, numRecords, numFields, recordSize, stringBlockSize = struct.unpack('c4iiii', file:read(20))
    
    local header = {
        magic = magic,
        record_count = numRecords,
        field_count = numFields,
        record_size = recordSize,
        string_block_size = stringBlockSize
    }
    
    header.records_start = file:seek()
    header.string_block_start = header.records_start + header.record_size * header.record_count
    
    return header
end

function DBC_Lib:new(dbc_filepath)
    local dbc_name = dbc_filepath:match("([^/]+)%.dbc$")
    
    local structure = require("structures." .. dbc_name)
    local file = io.open(dbc_filepath, "rb")
    file:setvbuf("full", 4024)
    
    local newObj = {
        dbc_filepath = dbc_filepath,
        structure = structure,
        header = read_header(file)
    }
    
    file:close()
    self.__index = self
    setmetatable(newObj, self)
    
    for _, field in ipairs(structure) do
        local name = field.field
        local camel_name = ToCamelCase(name:sub(1,1):upper() .. name:sub(2))

        local getBy = 'GetBy' .. camel_name
        newObj[getBy] = function (self, value)
            local matched_records = {}
            for i = 1, self.header.record_count do
                if self.data[i][name] == value then
                    matched_records[#matched_records+1] = DBC:new(self.data[i])
                end
            end
            
            return #matched_records == 1 and matched_records[1] or matched_records
        end
    end
    
    newObj:Read()
    return newObj
end

local function readRowsInLane(header, structure, startRow, endRow, path)
    function ReadInt32(file)
        local str = file:read(4)
        if not str then error("Failed to read Int32") end

        local b1, b2, b3, b4 = string.byte(str, 1, 4)
        local n = b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
        return (n > 0x7fffffff) and (n - 0x100000000) or n
    end

    function ReadString(file, header, offset)
        file:seek("set", header.string_block_start + offset)
        local result = ""
        while true do
            local char = file:read(1)
            if not char or char:byte() == 0 then break end
            result = result .. char
        end
        return result
    end

    local file = io.open(path, "rb")
    
    local records = {} 

    for row = startRow, endRow do
        local pos = header.records_start + (row - 1) * header.record_size
        file:seek("set", pos)

        local record = {}
        for i, object in ipairs(structure) do
            if object.type == 'int' then
                record[object.field] = ReadInt32(file)
            elseif object.type == 'string' then
                record[object.field] = ReadString(file, header, ReadInt32(file))
            end
        end

        table.insert(records, record)
    end

    file:close()

    return records
end

function DBC_Lib:Read()
    local LanesGen = lanes.gen("*", readRowsInLane)

    local record_table = {}
    local batchSize = 1000 
    local numBatches = math.ceil(self.header.record_count / batchSize)

    for batch = 1, numBatches do
        local laneList = {}

        local startIdx = (batch - 1) * batchSize + 1
        local endIdx = math.min(batch * batchSize, self.header.record_count)

        laneList[batch] = LanesGen(self.header, self.structure, startIdx, endIdx, self.dbc_filepath)

        local records, err = laneList[batch]:join()
        if records then
            for i, record in ipairs(records) do
                local record_table_entry = {}
                for _, data in ipairs(self.structure) do
                    record_table_entry[data.field] = record[data.field]
                end
                local absoluteIndex = startIdx + i - 1
                record_table[absoluteIndex] = DBC:new(record_table_entry)
            end
        else
            print("Error with lane: "..tostring(err))
        end
    end
    
    self.data = record_table
end

function DBC_Lib:Query()
    return Query:new(self.data)
end

return DBC_Lib