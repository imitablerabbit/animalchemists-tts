playerNameWhite = "White"
playerNamePurple = "Purple"
playerNameYellow = "Yellow"
playerNameRed = "Red"

scores = {}
scores[playerNameWhite] = 0
scores[playerNamePurple] = 0
scores[playerNameYellow] = 0
scores[playerNameRed] = 0

zones = {}

function getCardPoints(c)
    if not c then return 0 end
    desc = c.getDescription()
    points = string.match(desc, "Points: ([0-9]+)")
    if not points then return 0 end
    return points
end

function calculateObjectsPoints(objs)
    if not objs then return 0 end
    score = 0
    for _, v in pairs(objs) do
        score = score + getCardPoints(v)
    end
    return score
end

function calculateCurrentZonePoints(zone)
    if not zone then return 0 end
    --[[
    We are going to have to recalculate scores each time an object enters
    as there is no way that we can handle when an object has exited the zone.
    ]]
    objs = zone.getObjects()
    if not objs then return 0 end
    return calculateObjectsPoints(objs)
end

function onObjectEnterScriptingZone(zone, obj)
    if not zone then return end
    if not obj then return end
    c = zone.getName()
    s = calculateCurrentZonePoints(zone)
    --[[
    We have to account for the object that is currently entering the zone when
    using this method to udate the score.
    ]]
    scores[c] = s + getCardPoints(obj)
end

function scoreString(playerName)
    if not playerName then return "" end
    if Player[playerName].seated == 0 then return "" end
    score = scores[playerName]
    return Player[playerName].steam_name .. ": " .. tostring(score)
end

function displayScores()
    for k, v in pairs(zones) do
        scores[k] = calculateCurrentZonePoints(v)
    end
    for _, v in pairs(Player.getPlayers()) do
        broadcastToAll(scoreString(v.color), v.color)
    end
end

function onLoad()
    whiteScriptZone = getObjectFromGUID('22d480')
    purpleScriptZone = getObjectFromGUID('53bc04')
    yellowScriptZone = getObjectFromGUID('9a3ebd')
    redScriptZone = getObjectFromGUID('3d9156')

    zones[playerNameWhite] = whiteScriptZone
    zones[playerNamePurple] = purpleScriptZone
    zones[playerNameYellow] = yellowScriptZone
    zones[playerNameRed] = redScriptZone

    buttonObj = getObjectFromGUID('827282')
    scoreButton = buttonObj.createButton({
        click_function = "displayScores",
        function_owner = self,
        label          = "Display Scores",
        position       = vector(0, 1, 0),
        rotation       = vector(0, 180, 0),
        width          = 10000,
        height         = 2000,
        font_size      = 1000,
        tooltip        = "Display the current user scores",
    })

    for k, v in pairs(zones) do
        print("Initialising Zone: ", k)
        if not v then
            print("Error: Unable to initialize zone", k)
        else
            v.setName(k)
        end
    end

    print("Finished Loading")
end
