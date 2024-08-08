function Initialize()
    lyrics = {}
    oldLyrics = ''
    oldState = 2
    startTime = nil
    startPosition = 0
end

function Update()
    local lyricsString = SELF:GetOption('SyncedLyrics', '')
    local position = SELF:GetNumberOption('Position', 0)
    local state = SELF:GetNumberOption('PlayingState', 1)
    if oldState == 2 and state == 1 or not startTime then
        startTime = os.clock()
        startPosition = position
    elseif state == 2 then
        return "Paused (test)"
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
    end
    local currentLyrics = GetCurrentLyrics((os.clock() - startTime) + startPosition)
    return currentLyrics
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
            return lyrics[i].text
        end
    end
    if #lyrics == 0 then
        return "♫♪♫ Lyrics not found ♫♪♫"
    end
    return "♪♪♫♪♪♪"
end
