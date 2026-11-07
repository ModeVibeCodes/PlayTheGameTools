local _,addon=...
local C={limit=262144,nodes=20000,depth=20}
addon.ProfileCodec=C
local function Plain(v) return not (issecretvalue and issecretvalue(v)) end
local function Number(v) return Plain(v) and type(v)=="number" and v==v and math.abs(v)<math.huge end
C.Number=Number
-- Bounded primitive tree: no metatables, references, code or runtime objects.
function C.Copy(value)
    local seen,count={},0
    local function Copy(v,depth)
        count=count+1;assert(count<=C.nodes and depth<=C.depth,"Profile is too large or deeply nested.")
        assert(Plain(v),"Restricted profile value.")
        local kind=type(v)
        if kind=="boolean" then return v end
        if kind=="number" then assert(Number(v),"Invalid profile number.");return v end
        if kind=="string" then assert(#v<=4096,"Profile string too long.");return v end
        assert(kind=="table" and getmetatable(v)==nil and not seen[v],"Profile must contain plain settings only.")
        assert(not (issecrettable and issecrettable(v)) and (not canaccesstable or canaccesstable(v)),"Restricted profile table.")
        seen[v]=true;local result={}
        for k,item in pairs(v) do
            count=count+1;assert(count<=C.nodes,"Profile is too large.") -- keys count in the decoder too
            assert((type(k)=="string" and #k<=200) or (Number(k) and k==math.floor(k)),"Invalid profile key.")
            result[k]=Copy(item,depth+1)
        end
        seen[v]=nil;return result
    end
    return Copy(value,0)
end
function C.Encode(value)
    value=C.Copy(value)
    local function Encode(v)
        local kind=type(v)
        if kind=="boolean" then return v and "b1;" or "b0;" end
        if kind=="number" then return "n"..string.format("%.17g",v)..";" end
        if kind=="string" then return "s"..v:gsub(".",function(c) return string.format("%02x",c:byte()) end)..";" end
        local keys={};for k in pairs(v) do keys[#keys+1]=k end
        table.sort(keys,function(a,b) if type(a)~=type(b) then return type(a)<type(b) end;return a<b end)
        local out={"t"..#keys..";"}
        for _,key in ipairs(keys) do out[#out+1]=Encode(key);out[#out+1]=Encode(v[key]) end
        return table.concat(out)
    end
    local text="!MT1!"..Encode(value);assert(#text<=C.limit,"Profile export exceeds 256 KiB.");return text
end
function C.Decode(text)
    assert(Plain(text) and type(text)=="string" and #text<=C.limit,"Invalid or oversized profile string.")
    text=text:match("^%s*(.-)%s*$");assert(text:sub(1,5)=="!MT1!","Unsupported Play The Game Tools profile format.")
    local cursor,count=6,0
    local function Parse(depth)
        count=count+1;assert(count<=C.nodes and depth<=C.depth,"Profile is too large or deeply nested.")
        local kind=text:sub(cursor,cursor);local finish=text:find(";",cursor+1,true)
        assert(finish,"Truncated profile.");local token=text:sub(cursor+1,finish-1);cursor=finish+1
        if kind=="b" then assert(token=="0" or token=="1","Invalid boolean.");return token=="1" end
        if kind=="n" then local number=tonumber(token);assert(Number(number),"Invalid number.");return number end
        if kind=="s" then
            assert(#token<=8192 and #token%2==0 and not token:find("[^%da-f]"),"Invalid string.")
            return (token:gsub("..",function(hex) return string.char(tonumber(hex,16)) end))
        end
        assert(kind=="t" and token:match("^%d+$"),"Invalid data tag.")
        local size=tonumber(token);assert(size<=C.nodes,"Oversized table.");local result={}
        for _=1,size do
            local key=Parse(depth+1)
            assert((type(key)=="string" and #key<=200) or (Number(key) and key==math.floor(key)),"Invalid table key.")
            assert(result[key]==nil,"Duplicate profile key.");result[key]=Parse(depth+1)
        end
        return result
    end
    local value=Parse(0);assert(cursor==#text+1,"Trailing profile data.");return C.Copy(value)
end
