local currentIndex = 0
local lastLyrics = ''
local tweenTime = 0

function Initialize()
    lyrics = {}
    oldLyrics = ''
    oldState = 2
    startTime = nil
    startPosition = 0
    lastLyrics = nil
end

function Update()
    local lyricsString = SELF:GetOption('SyncedLyrics', '')
    local position = SELF:GetNumberOption('Position', 0)
    local state = SELF:GetNumberOption('PlayingState', 1)

    if oldState == 2 and state == 1 or not startTime or math.abs((((os.clock() - startTime) + startPosition) - position)) > 1.1 then
        startTime = os.clock()
        startPosition = position
    end
    if state == 2 then
        oldState = state
        return "Paused"
    end
    oldState = state
    if lyricsString ~= oldLyrics then
        lyrics = {}
        oldLyrics = lyricsString
        startTime = os.clock()
        startPosition = position
        if lyricsString ~= '' then
            ParseLyrics(lyricsString)
        end
        lastLyrics = ""
        currentIndex = 0
    end

    local currentLyrics, isNewLyrics, nextLyricTime = GetCurrentLyrics((os.clock() - startTime) + startPosition)

    if isNewLyrics then
        currentIndex = 0
        lastLyrics = currentLyrics
        
        local timeToNext = nextLyricTime - ((os.clock() - startTime) + startPosition)
        tweenTime = math.max(0, math.min(timeToNext / 10, 1))
    end

    if lastLyrics and currentIndex < #lastLyrics then
        local increment = (#lastLyrics / (tweenTime * 1000 / SELF:GetOption("Update", 25)))
        currentIndex = math.min(#lastLyrics, currentIndex + increment)
    end
    if not lastLyrics then
        return currentLyrics
    elseif #lyrics == 0 then
        return "♫♪♫ Lyrics not found ♫♪♫", false, position + 10
    end
    return string.sub(lastLyrics, 1, math.floor(currentIndex))
end

function ParseLyrics(lyricsString)
    lyrics = {}

    for line in string.gmatch(lyricsString, '[^[]+') do
        line = "["..line
        local time, text = string.match(line, '%[(%d+:%d+%.%d+)%]%s*(.+)')
        if time and text and text ~= '"' then
            local minutes, seconds = string.match(time, '(%d+):(%d+%.%d+)')
            local totalSeconds = tonumber(minutes) * 60 + tonumber(seconds)
            table.insert(lyrics, {time = totalSeconds, text = text})
        end
    end
end

function GetCurrentLyrics(position)
    for i = #lyrics, 1, -1 do
        if position >= lyrics[i].time then
            local nextLyricTime = lyrics[i + 1] and lyrics[i + 1].time or (position + 10)
            return lyrics[i].text, lyrics[i].text ~= lastLyrics, nextLyricTime
        end
    end
    if #lyrics == 0 then
        return "♫♪♫ Lyrics not found ♫♪♫", false, position + 10
    end
    return "♪♪♫♪♪♪", false, position + 10
end