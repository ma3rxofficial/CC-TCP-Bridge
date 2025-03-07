local server_url = "http://localhost:8080"

function deserializeJSON(json)
    local function parseValue(str)
        str = str:match("^%s*(.-)%s*$")
        
        if str:sub(1, 1) == '"' then
            return str:match('^"(.-)"'), str:match('^".-"(.*)')
        end
       
        local num = str:match("^-?%d+%.?%d*")
        if num then
            return tonumber(num), str:sub(#num + 1)
        end

        if str:sub(1, 4) == "true" then
            return true, str:sub(5)
        elseif str:sub(1, 5) == "false" then
            return false, str:sub(6)
        end

        if str:sub(1, 4) == "null" then
            return nil, str:sub(5)
        end

        if str:sub(1, 1) == "[" then
            local arr = {}
            str = str:sub(2)
            while str:sub(1, 1) ~= "]" do
                local value
                value, str = parseValue(str)
                table.insert(arr, value)
                str = str:match("^%s*,%s*(.-)$") or str
            end
            return arr, str:sub(2)
        end

        if str:sub(1, 1) == "{" then
            local obj = {}
            str = str:sub(2)
            while str:sub(1, 1) ~= "}" do
                local key
                key, str = parseValue(str)
                str = str:match("^%s*:%s*(.-)$")
                local value
                value, str = parseValue(str)
                obj[key] = value
                str = str:match("^%s*,%s*(.-)$") or str
            end
            return obj, str:sub(2)
        end

        return nil, str
    end

    local result, remaining = parseValue(json)
    if remaining:match("%S") then
        return nil, "Error parsing JSON: wrong format"
    end
    return result
end

function sendMessage(msg)
    local url = server_url .. "/send_msg?msg=" .. textutils.urlEncode(msg)
    local response = http.get(url)
    if response then
        response.close()
    end
end

function drawChat(messages)
    term.clear()
    term.setCursorPos(1, 1)

    local w, h = term.getSize()
    local max_messages = h - 3

    print("Messages:")
    for i = math.max(1, #messages - max_messages + 1), #messages do
        print("- " .. messages[i])
    end

    term.setCursorPos(1, h - 2)
    print(string.rep("-", w))

    term.setCursorPos(1, h - 1)
    io.write("> ")
end

function updateMessages()
    while true do
        local response = http.get(server_url .. "/get_msgs")
        if response then
            local body = response.readAll()
            response.close()
            local messages = deserializeJSON(body)
            if messages then
                drawChat(messages)
            end
        end
        sleep(1)
    end
end

function userInput()
    local _, h = term.getSize()
    while true do
        term.setCursorPos(3, h - 1)
        local input = read()
        if input and input ~= "" then
            sendMessage(input)
        end
    end
end

parallel.waitForAny(updateMessages, userInput)
