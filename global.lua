local playerNameWhite = "White"
local playerNamePurple = "Purple"
local playerNameYellow = "Yellow"
local playerNameRed = "Red"

local scores = {}
scores[playerNameWhite] = 0
scores[playerNamePurple] = 0
scores[playerNameYellow] = 0
scores[playerNameRed] = 0

local zones = {}

local ingredientDeckPos
local ingredientDeckRot
local ingredientDeckZone
local ingredientDiscardZone
local ingredientZones = {}
local ingredientZonePositions = {
    {-6.00, 1.03, 9.00},
    {-2.00, 1.03, 9.00},
    {2.00, 1.03, 9.00},
    {6.00, 1.03, 9.00},
    {10.00, 1.03, 9.00}
}
local ingredientZoneRotation = {0, 180, 0}

local spellDeck
local spellDeckZone
local spellZones = {}
local spellZonePositions = {
    {-6.00, 1.03, -3.00},
    {-2.00, 1.03, -3.00},
    {2.00, 1.03, -3.00},
    {6.00, 1.03, -3.00},
    {10.00, 1.03, -3.00}
}
local spellZoneRotation = {0, 180, 0}

local previousPlayer
local currentPlayer

--[[
Scoring Functions
]]

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

--[[
Deck Functions
]]

function hasEnoughCards(zoneArray)
    if not zoneArray then return nil end
    local count = 0
    for i, zone in ipairs(zoneArray) do
        objects = zone.getObjects()
        if objects then
            count = count + #objects
        end
    end
    return count == 5
end

function recreateIngredientDeck()
    log("Recreating ingredient deck...")
    local discarded = ingredientDiscardZone.getObjects()
    if not discarded or #discarded == 0 then return end
    local newIngredientDeck
    if #discarded > 1 then
        newIngredientDeck = group(discarded)
    else
        --[[
        Grouping a single object seems to return a list of the single object
        rather than a new object. So we needed to handle this exception.
        ]]
        newIngredientDeck = discarded[1]
    end
    if not newIngredientDeck then return end
    newIngredientDeck.setPosition(ingredientDeckPos)
    newIngredientDeck.setRotation(ingredientDeckRot)
    newIngredientDeck.shuffle()
    return newIngredientDeck
end

function dealToZones(deckZone, zones, zonePositions, zoneRotation,
                     recreateDeckFun)

    if not deckZone then return end
    if not zones then return end
    if not zonePositions then return end
    if not zoneRotation then return end

    if hasEnoughCards(zones) then return end

    --[[
    Find each card zone which is missing an item and move an object over to its
    location.
    ]]
    for i, zone in ipairs(zones) do
        local objects = zone.getObjects()
        if not objects or #objects == 0 then
            --[[
            We need to be dealing these cards out with some wait time in
            between. This is so that they are no longer in the deck zone after
            having been delt.
            ]]
            local frameSleep = 30
            Wait.frames(function()
                -- Recreate the deck if there are no objects at all.
                local zoneObjects = deckZone.getObjects()
                if not zoneObjects or #zoneObjects == 0 then
                    if recreateDeckFun then
                        recreateDeckFun()
                    else
                        return
                    end
                end
            end, frameSleep * i - (frameSleep / 2))

            Wait.frames(function()
                local zoneObjects = deckZone.getObjects()
                if not zoneObjects or #zoneObjects == 0 then
                    return
                end

                --[[
                Check whether the object inside the zone is a deck or a single card.
                We cannot reach this bit of code unless one of them exists.
                ]]
                local zoneObject = zoneObjects[1]
                if zoneObject.tag == "Deck" then
                    -- The object had subobjects so assume it was a deck.
                    card = zoneObject.takeObject({
                        position = zonePositions[i],
                        rotation = zoneRotation,
                        flip = true
                    })
                elseif zoneObject.tag == "Card" then
                    -- Object was actually just a single card so just move it.
                    zoneObject.setPosition(zonePositions[i])
                    zoneObject.setRotation(zoneRotation)
                end
            end, frameSleep * i)
        end
    end
end

function setupSpellDeck()
    timestopCard = getObjectFromGUID('c24215')
    if not timestopCard then return end

    spellDeck = getObjectFromGUID('77019a')
    if not spellDeck then return end

    spellDeckPos = spellDeck.getPosition()
    spellDeckRot = spellDeck.getRotation()

    newTimestopPos = {spellDeckPos.x, spellDeckPos.y, spellDeckPos.z}
    newTimestopRot = {0, 180, 180}
    spellDeckPos['y'] = spellDeckPos['y'] + 5

    spellDeck.setPosition(spellDeckPos)
    timestopCard.setRotation(newTimestopRot)
    timestopCard.setPosition(newTimestopPos)
end

--[[
Button Callback Functions
]]

function startGame()
    setupSpellDeck()
end

function displayScores()
    for k, v in pairs(zones) do
        scores[k] = calculateCurrentZonePoints(v)
    end
    for _, v in pairs(Player.getPlayers()) do
        broadcastToAll(scoreString(v.color), v.color)
    end
end

--[[
Init Functions
]]

function initIngredients()
    log("Initialising ingredients...")
    ingredientDeck = getObjectFromGUID('d0fba2')
    ingredientDeckZone = getObjectFromGUID('ba7c2a')
    idp = ingredientDeck.getPosition()
    idr = ingredientDeck.getRotation()
    --[[
    Justing making sure its not a reference to the actual ingredient decks pos
    and rot.
    ]]
    ingredientDeckPos = {idp.x, idp.y, idp.z}
    ingredientDeckRot = {idr.x, idr.y, idr.z}

    ingredientDiscardZone = getObjectFromGUID('4fa607')

    ingredientZones = {
        getObjectFromGUID('633924'),
        getObjectFromGUID('6b541e'),
        getObjectFromGUID('c72828'),
        getObjectFromGUID('a8c9ee'),
        getObjectFromGUID('f0e529')
    }
end

function initSpells()
    log("Initialising spells...")
    spellDeck = getObjectFromGUID('77019a')
    spellDeckZone = getObjectFromGUID('c16232')
    spellZones = {
        getObjectFromGUID('b643b9'),
        getObjectFromGUID('d83bc7'),
        getObjectFromGUID('5fb2c2'),
        getObjectFromGUID('2edf9a'),
        getObjectFromGUID('012e1e')
    }
end

function initButtons()
    log("Initialising buttons...")
    startGameButtonObj = getObjectFromGUID('e851cd')
    startGameButtonPos = {-12.00, 0.5, 16.50}
    startGameButtonRot = {0, 180, 0}
    startGameButtonObj.setPosition(startGameButtonPos)
    startGameButtonObj.setRotation(startGameButtonRot)
    scoreButton = startGameButtonObj.createButton({
        click_function = "startGame",
        function_owner = self,
        label          = "Start Game",
        position       = vector(0, 2, 0),
        rotation       = vector(0, 0, 0),
        width          = 10000,
        height         = 2000,
        font_size      = 1000,
        tooltip        = "Start the game",
    })

    shuffleButtonObj = getObjectFromGUID('c7f24d')
    shuffleButtonPos = {-12.00, 0.5, 15.00}
    shuffleButtonRot = {0, 180, 0}
    shuffleButtonObj.setPosition(shuffleButtonPos)
    shuffleButtonObj.setRotation(shuffleButtonRot)
    shuffleButton = shuffleButtonObj.createButton({
        click_function = "recreateIngredientDeck",
        function_owner = self,
        label          = "Create Ingredient Deck",
        position       = vector(0, 2, 0),
        rotation       = vector(0, 0, 0),
        width          = 10000,
        height         = 2000,
        font_size      = 1000,
        tooltip        = "Creates a new ingredient deck from the discard pile",
    })

    scoreButtonObj = getObjectFromGUID('827282')
    scoreButtonPos = {-12.00, 0.5, 13.50}
    scoreButtonRot = {0, 180, 0}
    scoreButtonObj.setPosition(scoreButtonPos)
    scoreButtonObj.setRotation(scoreButtonRot)
    scoreButton = scoreButtonObj.createButton({
        click_function = "displayScores",
        function_owner = self,
        label          = "Display Scores",
        position       = vector(0, 2, 0),
        rotation       = vector(0, 0, 0),
        width          = 10000,
        height         = 2000,
        font_size      = 1000,
        tooltip        = "Display the current user scores",
    })


end

function initZones()
    log("Initialising zones...")
    whiteScriptZone = getObjectFromGUID('22d480')
    purpleScriptZone = getObjectFromGUID('53bc04')
    yellowScriptZone = getObjectFromGUID('9a3ebd')
    redScriptZone = getObjectFromGUID('3d9156')

    zones[playerNameWhite] = whiteScriptZone
    zones[playerNamePurple] = purpleScriptZone
    zones[playerNameYellow] = yellowScriptZone
    zones[playerNameRed] = redScriptZone

    for k, v in pairs(zones) do
        if not v then
            log("Error: Unable to initialize zone", k)
        else
            v.setName(k)
        end
    end
end

--[[
TTS API Event Handlers
]]

function onPlayerTurnEnd(endColor, nextColor)
    --[[
    This check is required in case the game is played in hotseat mode. Currently
    there seems to be a bug whereby this function is called multiple times when
    the end turn button is pressed
    ]]
    if endColor == previousPlayer and nextColor == currentPlayer then
        return
    end
    previousPlayer = endColor
    currentPlayer = nextColor

    dealToZones(ingredientDeckZone,
                ingredientZones,
                ingredientZonePositions, ingredientZoneRotation,
                function() recreateIngredientDeck() end)
    dealToZones(spellDeckZone,
                spellZones,
                spellZonePositions, spellZoneRotation,
                nil)
end

function onLoad()
    initButtons()
    initZones()
    initIngredients()
    initSpells()

    log("Finished Loading")
end
