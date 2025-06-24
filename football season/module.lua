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
        "|(...)-(...)%s=%s\n{{Kapanabilir futbol maçı kutusu\n|tarih%s*=%s*([^\n]*)\n|zaman%s*=%s*([^|]*)\n|tur%s*=%s*(%d+)\n|takım1%s*=%s*([^\n]*)\n|sonuç%s*=%s*([^|]*)"

    for m1, m2, m3, m4, m5, m6, m7 in mw.ustring.gmatch(content, pattern) do
        if team == m1 or team == m2 then
            countMatch = countMatch + 1

            local result

            if string.find(m7, "Y") then
                result = " "
            elseif m1 == team then
                result = "E"
            elseif m2 == team then
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
        "|(...)-(...)%s=%s\n{{Kapanabilir futbol maçı kutusu\n|tarih%s*=%s*([^\n]*)\n|zaman%s*=%s*([^|]*)\n|tur%s*=%s*(%d+)\n|takım1%s*=%s*([^\n]*)\n|sonuç%s*=%s*([^|]*)"

    for m1, m2, m3, m4, m5, m6, m7 in mw.ustring.gmatch(content, pattern) do
        if team == m1 or team == m2 then
            countMatch = countMatch + 1

            local result
            if m7 == '' then
                result = " "
            end
            if string.find(m7, "ERT") then
                result = "P"
            end
            if string.find(m7, "Y") then
                result = "İ"
            end
            local pattern2 = "(%d+)%s*-%s*(%d+)"
            for num1, num2 in mw.ustring.gmatch(m7, pattern2) do

                if team == m1 then
                    result = (num1 > num2 and "G") or (num1 < num2 and "M") or "B"
                elseif team == m2 then
                    result = (num1 > num2 and "M") or (num1 < num2 and "G") or "B"
                end

            end
            if countMatch == 1 then
                table.insert(results, frame:preprocess("=== İlk devre ==="))
            end

            if result ~= "İ" then
                table.insert(results, "{{" .. league .. " maçları|" .. m1 .. "-" .. m2 .. "|" .. result .. "}}")
            else
                table.insert(results, "{{BAY|" .. countMatch .. "}}")
            end
            if countMatch == tonumber(count) / 2 then
                table.insert(results, frame:preprocess("=== İkinci devre ==="))
            end

        end

    end
    return mw.text.trim(frame:preprocess(table.concat(results, "\n")))
end

function p.getMatchResults(frame)
    local team = frame.args[1]
    local league = frame.args[2]
    local delPoints = frame.args[3] or 0
    local pageId = frame.args['pageId'] or ' '
    local results = {}
    local hw, hd, hl, hgf, hga, aw, ad, al, agf, aga = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    local templateName = "Şablon:" .. league .. " maçları/maçlar"
    local lastMatchDate = ''
    local templatePage = mw.title.new(templateName)
    local content = templatePage:getContent()

    table.insert(results, "{{futbol ayrıntılı lig durumu")

    local pattern =
        "|(...)-(...)%s=%s\n{{Kapanabilir futbol maçı kutusu\n|tarih%s*=%s*([^\n]*)\n|zaman%s*=%s*([^|]*)\n|tur%s*=%s*(%d+)\n|takım1%s*=%s*([^\n]*)\n|sonuç%s*=%s*([^|]*)"
    for m1, m2, m3, m4, m5, m6, m7 in mw.ustring.gmatch(content, pattern) do

        if team == m1 or team == m2 then
            local pattern2 = "(%d+)%s*-%s*(%d+)"
            for num1, num2 in mw.ustring.gmatch(m7, pattern2) do
                lastMatchDate = m3
                if team == m1 then
                    if num1 > num2 then
                        hw = hw + 1
                    elseif num1 < num2 then
                        hl = hl + 1
                    elseif num1 == num2 then
                        hd = hd + 1
                    end
                    hgf = hgf + num1
                    hga = hga + num2

                elseif team == m2 then
                    if num1 > num2 then
                        al = al + 1
                    elseif num1 < num2 then
                        aw = aw + 1
                    elseif num1 == num2 then
                        ad = ad + 1
                    end
                    aga = aga + num1
                    agf = agf + num2
                end

            end
        end

    end
    table.insert(results,
        "|eg=" .. hw .. " |eb=" .. hd .. " |em=" .. hl .. " |eag=" .. hgf .. " |eyg=" .. hga .. " |dg=" .. aw .. " |db=" ..
            ad .. " |dm=" .. al .. " |dag=" .. agf .. " |dyg=" .. aga .. " |sp=" .. delPoints .. "}}")
    table.insert(results,
        "\n{{Futbol ayrıntılı lig durumu altbilgisi |u= " .. lastMatchDate ..
            " |s=[http://www.tff.org/default.aspx?pageID=" .. pageId .. " TFF Puan durumu ve fikstür] }}")
    return mw.text.trim(frame:preprocess(table.concat(results)))
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
        "|(...)-(...)%s=%s\n{{Kapanabilir futbol maçı kutusu\n|tarih%s*=%s*([^\n]*)\n|zaman%s*=%s*([^|]*)\n|tur%s*=%s*(%d+)\n|takım1%s*=%s*([^\n]*)\n|sonuç%s*=%s*([^|]*)"

    for m1, m2, m3, m4, m5, m6, m7 in mw.ustring.gmatch(content, pattern) do
        if team == m1 or team == m2 then
            countMatch = countMatch + 1

            local result
            if string.find(m7, "ERT") or m7 == '' then
                result = " "
            end
            if string.find(m7, "Y") then
                result = "Y"
            end
            local pattern2 = "(%d+)%s*-%s*(%d+)"
            for num1, num2 in mw.ustring.gmatch(m7, pattern2) do

                if team == m1 then
                    result = (num1 > num2 and "G") or (num1 < num2 and "M") or "B"
                elseif team == m2 then
                    result = (num1 > num2 and "M") or (num1 < num2 and "G") or "B"
                end

            end
            table.insert(results, result)
            if countMatch ~= tonumber(count) then
                table.insert(results, "/ ")
            end

        end

    end
    return table.concat(results, " ")
end

function p.getTeamWeekRanks(frame)
    local targetTeam = frame.args[1]
    local league = frame.args[2]
    local count = frame.args[3]
    local matches = {}
    local teams = {}

    local countMatch = 0
    local templateName = "Şablon:" .. league .. " maçları/maçlar"

    local templatePage = mw.title.new(templateName)
    local content = templatePage:getContent()

    local pattern =
        "|(...)-(...)%s=%s\n{{Kapanabilir futbol maçı kutusu\n|tarih%s*=%s*([^\n]*)\n|zaman%s*=%s*([^|]*)\n|tur%s*=%s*(%d+)\n|takım1%s*=%s*([^\n]*)\n|sonuç%s*=%s*([^|]*)"

    for m1, m2, m3, m4, m5, m6, m7 in mw.ustring.gmatch(content, pattern) do
        local pattern2 = "(%d+)%s*-%s*(%d+)"
        for num1, num2 in mw.ustring.gmatch(m7, pattern2) do
            table.insert(matches, {
                week = tonumber(m5),
                home = m1,
                away = m2,
                homeS = tonumber(num1),
                awayS = tonumber(num2)
            })
            teams[m1] = teams[m1] or {
                points = {},
                position = {}
            }
            teams[m2] = teams[m2] or {
                points = {},
                position = {}
            }
        end
    end

    -- Maksimum hafta sayısını bul
    local maxWeek = 0
    for _, match in ipairs(matches) do
        if match.week and match.week > maxWeek then
            maxWeek = match.week
        end
    end

    mw.log("MaxWeek: " .. maxWeek)
    mw.log("Total matches: " .. #matches)

    -- Her hafta için puan durumunu hesapla
    for week = 1, maxWeek do
        -- Bu haftaya kadar olan tüm maçları işle
        local weeklyStats = {}

        -- Tüm takımları initialize et
        for teamName, _ in pairs(teams) do
            weeklyStats[teamName] = {
                points = 0,
                played = 0,
                goalsFor = 0,
                goalsAgainst = 0
            }
        end

        -- Bu haftaya kadar olan maçları topla
        for _, match in ipairs(matches) do
            if match.week and match.week <= week then
                local home = weeklyStats[match.home]
                local away = weeklyStats[match.away]

                if home and away then
                    home.played = home.played + 1
                    away.played = away.played + 1

                    home.goalsFor = home.goalsFor + match.homeS
                    home.goalsAgainst = home.goalsAgainst + match.awayS
                    away.goalsFor = away.goalsFor + match.awayS
                    away.goalsAgainst = away.goalsAgainst + match.homeS

                    if match.homeS > match.awayS then
                        home.points = home.points + 3
                    elseif match.homeS < match.awayS then
                        away.points = away.points + 3
                    else
                        home.points = home.points + 1
                        away.points = away.points + 1
                    end
                end
            end
        end

        -- Sıralama oluştur
        local standings = {}
        for teamName, stats in pairs(weeklyStats) do
            table.insert(standings, {
                name = teamName,
                points = stats.points,
                goalDiff = stats.goalsFor - stats.goalsAgainst,
                goalsFor = stats.goalsFor,
                played = stats.played
            })
        end

        -- Sırala: Puan > Averaj > Attığı gol
        table.sort(standings, function(a, b)
            if a.points ~= b.points then
                return a.points > b.points
            end
            if a.goalDiff ~= b.goalDiff then
                return a.goalDiff > b.goalDiff
            end
            if a.goalsFor ~= b.goalsFor then
                return a.goalsFor > b.goalsFor
            end
            return a.name < b.name
        end)

        -- Pozisyonları kaydet
        for pos, teamData in ipairs(standings) do
            teams[teamData.name].position[week] = pos
            teams[teamData.name].points[week] = teamData.points
        end
    end

    -- Hedef takımın haftalık sıralamasını döndür
    local targetTeamData = teams[targetTeam]
    if not targetTeamData then
        return "Takım bulunamadı: " .. targetTeam
    end

    local result = {}
    for week = 1, maxWeek do
        if targetTeamData.position[week] then
            if frame.args['pos_' .. week] ~= nil then
                table.insert(result, frame.args['pos_' .. week])
            else
                table.insert(result, tostring(targetTeamData.position[week]))
            end
            if week ~= maxWeek then
                table.insert(result, '/ ')
            end

        end
    end

    return table.concat(result, " ")
end

function p.matchesCup(frame)
    local team = frame.args[1]
    local teamNameFull = frame.args['teamNameFull'] or nil
    local league = frame.args[2]

    local countMatch = 0
    local results = {}
    local matches = {}
    local templateName = "Şablon:" .. league .. " maçları/maçlar"
    local templatePage = mw.title.new(templateName)
    local content = templatePage:getContent()
    local pattern =
        "|(...)%-(...)%s*=%s*\n{{Kapanabilir futbol maçı kutusu\n|tarih%s*=%s*([^\n]*)\n|zaman%s*=%s*([^\n]*)\n|tur%s*=%s*([^\n]*)\n|takım1%s*=%s*([^\n]*)\n|sonuç%s*=%s*([^\n]*).-|takım2%s*=%s*([^\n]*)"
    local penalty_pattern = "|penaltısonuç%s*=%s*([^\n]*)"
    -- Turları gruplamak için tablo
    local grouped_results = {}

    for m1, m2, m3, m4, m5, m6, m7, m8 in mw.ustring.gmatch(content, pattern) do
        local match_start = mw.ustring.find(content, "|" .. m1 .. "%-" .. m2)
        local next_match = mw.ustring.find(content, "|...%-...", match_start + 1)
        local match_end = next_match and (next_match - 1) or mw.ustring.len(content)
        local match_block = mw.ustring.sub(content, match_start, match_end)

        -- Bu blok içinde penaltı sonucunu ara
        local penalty_result = mw.ustring.match(match_block, penalty_pattern)
        if (team == m1 or team == m2) and (not teamNameFull or teamNameFull == m6 or teamNameFull == m8) then
            countMatch = countMatch + 1
            local result
            if m7 == '' then
                result = " "
            end
            if string.find(m7, "ERT") then
                result = "P"
            end
            if string.find(m7, "Y") then
                result = "İ"
            end
            local pattern2 = "(%d+)%s*-%s*(%d+)"
            for num1, num2 in mw.ustring.gmatch(m7, pattern2) do
                if team == m1 then
                    result = (num1 > num2 and "G") or (num1 < num2 and "M") or "B"
                elseif team == m2 then
                    result = (num1 > num2 and "M") or (num1 < num2 and "G") or "B"
                end
            end
            if result == "B" then
                if penalty_result then
                    for pnum1, pnum2 in mw.ustring.gmatch(penalty_result, pattern2) do
                        if team == m1 then
                            result = (pnum1 > pnum2 and "G") or (pnum1 < pnum2 and "M") or ""
                        elseif team == m2 then
                            result = (pnum1 > pnum2 and "M") or (pnum1 < pnum2 and "G") or ""
                        end
                    end
                end
            end

            -- Tur bazında gruplama
            local round = m5 -- m5 tur bilgisi
            if not grouped_results[round] then
                grouped_results[round] = {}
            end
            table.insert(grouped_results[round],
                "{{" .. league .. " maçları|" .. m1 .. "-" .. m2 .. "|" .. result .. "}}")
        end
    end
    -- Tur sıralama fonksiyonu
    local function getTourOrder(tour)
        local tour_lower = mw.ustring.lower(tour)

        -- Sayısal tur kontrolü
        local num = mw.ustring.match(tour, "(%d+)")
        if num then
            return tonumber(num)
        end

        -- Özel turlar için sıralama
        if mw.ustring.find(tour_lower, "eleme") or mw.ustring.find(tour_lower, "ön") then
            return 0
        elseif mw.ustring.find(tour_lower, "çeyrek") then
            return 1000
        elseif mw.ustring.find(tour_lower, "yarı") then
            return 2000
        elseif mw.ustring.find(tour_lower, "final") and not mw.ustring.find(tour_lower, "yarı") and
            not mw.ustring.find(tour_lower, "çeyrek") then
            return 3000
        else
            return 500 -- Bilinmeyen turlar ortada
        end
    end

    -- Tur anahtarlarını sıralama
    local sorted_tours = {}
    for round in pairs(grouped_results) do
        table.insert(sorted_tours, round)
    end
    table.sort(sorted_tours, function(a, b)
        return getTourOrder(a) < getTourOrder(b)
    end)
    -- Gruplanmış sonuçları results tablosuna ekleme
    for _, round in ipairs(sorted_tours) do
        table.insert(results, frame:preprocess('===' .. round .. '==='))
        for _, match in ipairs(grouped_results[round]) do
            table.insert(results, match)
        end
    end
    return mw.text.trim(frame:preprocess(table.concat(results, "\n")))
end
return p
