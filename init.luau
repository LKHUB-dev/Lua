local HttpService = cloneref(game:GetService("HttpService"))

local function setOdus(path)
    local url = string.format("https://raw.githubusercontent.com/LKHUB-dev/Lua/refs/heads/main/%s",
        path                   -- 4
    )
    local response = request({Url = url; Method = "GET";})

    if response.Success then
        return response.Body
    else
        error("Failed to fetch script from: " .. url .. " | Error: " .. response.StatusCode)
    end
end

local function tableSupportedGames()
    local jsonContent = setOdus("games.json")
    return HttpService:JSONDecode(jsonContent)
end

local placeId = tostring(game.PlaceId)
local gameId = tostring(game.GameId)

local GameScripts = tableSupportedGames()

local gameUrl = ""

local function runScript()
    if GameScripts.placeScripts[placeId] then
        gameUrl = GameScripts.placeScripts[placeId]
        print("PlaceId script found for place:", placeId, "URL:", gameUrl)
    end

    if gameUrl == "" and GameScripts.gameIdScripts[gameId] then
        gameUrl = GameScripts.gameIdScripts[gameId]
        print("GameId script found for game:", gameId, "URL:", gameUrl)
    end

    if gameUrl ~= "" then
        local success, err = pcall(function()
            loadstring(game:HttpGet(gameUrl))()
        end)
        if not success then
            warn("Failed to execute script from URL:", gameUrl, "| Error:", err)
        end
    else
        warn("No matching script found for PlaceId:", placeId, "or GameId:", gameId)
    end
end

runScript()