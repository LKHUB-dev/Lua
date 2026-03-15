local function setOdus(path)
    local url = string.format("https://raw.githubusercontent.com/LKHUB-dev/Lua/refs/heads/main/%s",
        path                   -- 4
    )
    local response = request({Url = url; Method = "GET";})

    if response.Success then
        return response.Body
    else
        --error("Failed to fetch script from: " .. url .. " | Error: " .. response.StatusCode)
    end
end

local function tableSupportedGames()
    local luaContent = setOdus("games.lua")
    return loadstring(luaContent)()
end

local placeId = tostring(game.PlaceId)
local gameId = tostring(game.GameId)

local GameScripts = tableSupportedGames()

local function runScript()
    local gameData = nil

    if GameScripts[gameId] then
        gameData = GameScripts[gameId]
    end

    -- If not found by gameId, search through placeIds
    if not gameData then
        for gId, data in pairs(GameScripts) do
            if data.placeIds then
                for _, pId in ipairs(data.placeIds) do
                    if tostring(pId) == placeId then
                        gameData = data
                        break
                    end
                end
            end
            if gameData then break end
        end
    end

    if gameData and gameData.scriptUrl then
        local success, err = pcall(function()
            loadstring(
                request({
                    Url = gameData.scriptUrl;
                    Method = "GET";
                }).Body
            )()
        end)
    end
end

runScript()
