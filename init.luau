print("eh")
local HttpService = game:GetService("HttpService") -- HttpService for fetching the JSON

local Config = {
    githubUsername = "LKHUB-dev",
    githubRepo = "Lua",
    githubBranch = "main",
}

getgenv().requireL = function(path)
    -- Ensure the path is a string
    assert(type(path) == "string", "invalid argument #1 to 'requireL' (string expected, got " .. type(path) .. ")", 2)

    warn("requireL used.")

    -- Construct the URL to fetch the script from GitHub
    local url = string.format("https://raw.githubusercontent.com/%s/%s/refs/heads/%s/%s",
        Config.githubUsername, -- 1
        Config.githubRepo,     -- 2
        Config.githubBranch,   -- 3
        path                   -- 4
    )

    -- Make the request to the URL
    local response = request({Url = url; Method = "GET";})
    print("Get Request on Url:", url)

    -- Check if the response is successful
    if response.Success then
        return response.Body -- Return the body of the response
    else
        error("Failed to fetch script from: " .. url .. " | Error: " .. response.StatusCode)
    end
end

getgenv().tableSupportedGames = function()
    warn("tableSupportedGames used.")
    local jsonContent = requireL("games.json") -- Use requireL to fetch the JSON content
    warn("json content:", jsonContent)
    return HttpService:JSONDecode(jsonContent) -- Parse the JSON into a Lua table
end

local placeId = tostring(game.PlaceId) -- Ensure IDs are strings for comparison
local gameId = tostring(game.GameId)

local GameScripts = tableSupportedGames()

_G.gameUrl = "" -- Initialize global variable for script URL

-- Function to load and run the correct script
local function runScript()
    -- Look for the matching PlaceId script
    if GameScripts.placeScripts[placeId] then
        _G.gameUrl = GameScripts.placeScripts[placeId]
        print("PlaceId script found for place:", placeId, "URL:", _G.gameUrl)
    end

    -- If no PlaceId script is found, check for GameId script
    if _G.gameUrl == "" and GameScripts.gameIdScripts[gameId] then
        _G.gameUrl = GameScripts.gameIdScripts[gameId]
        print("GameId script found for game:", gameId, "URL:", _G.gameUrl)
    end

    -- Load and run the script from the URL
    if _G.gameUrl ~= "" then
        print("Executing script from URL:", _G.gameUrl)
        local success, err = pcall(function()
            loadstring(game:HttpGet(_G.gameUrl))() -- Fetch and execute the script
        end)
        if not success then
            warn("Failed to execute script from URL:", _G.gameUrl, "| Error:", err)
        end
    else
        warn("No matching script found for PlaceId:", placeId, "or GameId:", gameId)
    end
end

-- Run the appropriate script
runScript()