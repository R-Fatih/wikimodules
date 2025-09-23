local p = {}
function p.matchPlaces(frame)
    local team = frame.args[1]
    local league = frame.args[2]
    local count = frame.args[3]
    local countMatch = 0
    local results = {}
    local templateName = "Şablon:" .. league .. " maçları/maçlar"
    local templatePage = mw.title.new(templateName)
    local content = templatePage:getContent()
    local pattern =
        "|(...)%-(...)%s*=%s*\n{{Kapanabilir basketbol maçı kutusu\n|tarih%s*=%s*([^\n]*)\n|saat%s*=%s*([^\n]*)\n|tur%s*=%s*(%d+)\n|takım1%s*=%s*([^\n]*)\n|takım1sayısı%s*=%s*([^\n]*)\n|takım2%s*=%s*([^\n]*)\n|takım2sayısı%s*=%s*([^\n]*)"
    for team1, team2, date, time, round, team1full, result1, team2full, result2 in mw.ustring.gmatch(content, pattern) do
        if team == team1 or team == team2 then
            countMatch = countMatch + 1

            local result

            if team1 == team then
                result = "E"
            elseif team2 == team then
                result = "D"
            end

            table.insert(results, result)
            if countMatch ~= tonumber(count) then
                table.insert(results, "/ ")
            end
        end

    end
    if countMatch ~= tonumber(count) then
        for i = 0, tonumber(count) - 2 do
            table.insert(results, "/ ")
        end
    end

    return table.concat(results, " ")

end
function p.getTeamResults(frame)
    local team = frame.args[1]
    local league = frame.args[2]
    local count = frame.args[3]
    local results = {}
    local countMatch = 0
    local templateName = "Şablon:" .. league .. " maçları/maçlar"

    local templatePage = mw.title.new(templateName)
    local content = templatePage:getContent()

    local pattern =
        "|(...)%-(...)%s*=%s*\n{{Kapanabilir basketbol maçı kutusu\n|tarih%s*=%s*([^\n]*)\n|saat%s*=%s*([^\n]*)\n|tur%s*=%s*(%d+)\n|takım1%s*=%s*([^\n]*)\n|takım1sayısı%s*=%s*([^\n]*)\n|takım2%s*=%s*([^\n]*)\n|takım2sayısı%s*=%s*([^\n]*)"
    for team1, team2, date, time, round, team1full, result1, team2full, result2 in mw.ustring.gmatch(content, pattern) do
        if team == team1 or team == team2 then
            countMatch = countMatch + 1

            local result
            local score1 = tonumber(result1) or 0
            local score2 = tonumber(result2) or 0

            if team == team1 then
                result = (score1 > score2 and "G") or (score1 < score2 and "M") or " "
            elseif team == team2 then
                result = (score1 > score2 and "M") or (score1 < score2 and "G") or " "
            end
            table.insert(results, result)
            if countMatch ~= tonumber(count) then
                table.insert(results, "/ ")
            end

        end

    end
    return table.concat(results, " ")
end
function p.getMatchResults(frame)
    local team = frame.args[1]
    local league = frame.args[2]
    local delPoints = frame.args[3] or 0
    local pageId = frame.args['pageId'] or ' '
    local results = {}
    local hw, hl, hgf, hga, aw, al, agf, aga = 0, 0, 0, 0, 0, 0, 0, 0
    local templateName = "Şablon:" .. league .. " maçları/maçlar"
    local lastMatchDate = ''
    local templatePage = mw.title.new(templateName)
    local content = templatePage:getContent()

    local pattern =
        "|(...)%-(...)%s*=%s*\n{{Kapanabilir basketbol maçı kutusu\n|tarih%s*=%s*([^\n]*)\n|saat%s*=%s*([^\n]*)\n|tur%s*=%s*(%d+)\n|takım1%s*=%s*([^\n]*)\n|takım1sayısı%s*=%s*([^\n]*)\n|takım2%s*=%s*([^\n]*)\n|takım2sayısı%s*=%s*([^\n]*)"
    for team1, team2, date, time, round, team1full, result1, team2full, result2 in mw.ustring.gmatch(content, pattern) do

        if team == team1 or team == team2 then
            local score1 = tonumber(result1) or 0
            local score2 = tonumber(result2) or 0
            lastMatchDate = date
            if team == team1 then
                if score1 > score2 then
                    hw = hw + 1
                elseif score1 < score2 then
                    hl = hl + 1

                end
                hgf = hgf + score1
                hga = hga + score2

            elseif team == team2 then
                if score1 > score2 then
                    al = al + 1
                elseif score1 < score2 then
                    aw = aw + 1

                end
                aga = aga + score1
                agf = agf + score2
            end

        end

    end
    table.insert(results,
        "{{Bs rs |hw=" .. hw .. " |hl=" .. hl .. " |hpf=" .. hgf .. " |hpa=" .. hga .. " |aw=" .. aw .. " |al=" .. al ..
            " |apf=" .. agf .. " |apa=" .. aga .. " |sp=" .. delPoints .. "}}")
    table.insert(results, "\n{{Bs rs footer |u= " .. lastMatchDate ..
        " |s=[http://www.bsl.org.tr/tbl/maclar/puan Basketbol Süper Ligi] }}")
    return mw.text.trim(frame:preprocess(table.concat(results)))
end
function p.matches(frame)
    local team = frame.args[1]
    local league = frame.args[2]
    local count = frame.args[3]
    local countMatch = 0
    local results = {}
    local templateName = "Şablon:" .. league .. " maçları/maçlar"
    local templatePage = mw.title.new(templateName)
    local content = templatePage:getContent()

    local pattern =
        "|(...)%-(...)%s*=%s*\n{{Kapanabilir basketbol maçı kutusu\n|tarih%s*=%s*([^\n]*)\n|saat%s*=%s*([^\n]*)\n|tur%s*=%s*(%d+)\n|takım1%s*=%s*([^\n]*)\n|takım1sayısı%s*=%s*([^\n]*)\n|takım2%s*=%s*([^\n]*)\n|takım2sayısı%s*=%s*([^\n]*)"
    for team1, team2, date, time, round, team1full, result1, team2full, result2 in mw.ustring.gmatch(content, pattern) do
        if team == team1 or team == team2 then
            countMatch = countMatch + 1
            local result = ""

            if countMatch == 1 then
                table.insert(results, frame:preprocess("=== İlk devre ==="))
            end

            if result1 == '' or result2 == '' then
                result = " "
            elseif string.find(result1, "ERT") or string.find(result2, "ERT") then
                result = "P"
            else
                local score1 = tonumber(result1) or 0
                local score2 = tonumber(result2) or 0

                if team == team1 then
                    result = (score1 > score2 and "G") or (score1 < score2 and "M") or "B"
                elseif team == team2 then
                    result = (score1 > score2 and "M") or (score1 < score2 and "G") or "B"
                end
            end

            if result ~= "İ" then
                table.insert(results, "{{" .. league .. " maçları|" .. team1 .. "-" .. team2 .. "|" .. result .. "}}")
            end

            if countMatch == tonumber(count) / 2 then
                table.insert(results, frame:preprocess("=== İkinci devre ==="))
            end
        end
    end

    return mw.text.trim(frame:preprocess(table.concat(results, "\n")))
end

return p
