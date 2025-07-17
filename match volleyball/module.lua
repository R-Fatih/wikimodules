local p = {}

function p.standings(frame)
    local args = frame.args
    local league = frame.args[1]
    local gender = ''
    local teamFinalist = frame.args['teamFinalist']

    if league then

        local leagueLower = mw.ustring.lower(league)

        if mw.ustring.find(leagueLower, "erkekler") then
            gender = "vb"
        elseif mw.ustring.find(leagueLower, "kadınlar") then
            gender = "vbk"
        end
    end

    local function getQualificationRules()
        local rules = {}
        local i = 1
        while true do
            local start = frame.args['startQ' .. i]
            local finish = frame.args['finishQ' .. i]
            local text = frame.args['textQ' .. i]
            local color = frame.args['colorQ' .. i]

            if start or finish or text then
                table.insert(rules, {
                    start = tonumber(start),
                    finish = tonumber(finish),
                    text = text or "",
                    color = color or "",
                    name = "Q" .. i
                })
                i = i + 1
            else
                break
            end
        end
        return rules
    end

    local qualificationRules = getQualificationRules()
    local results = {}
    local teams = {}
    local filterRound = frame.args['Round'] or ''
    local pattern =
        "|(..)-(...)-(...)%s*=%s*\n{{vb res %d+\n|%s*takım1%s*=%s*{{(vb[^}]*)}}%s*\n|%s*takım2%s*=%s*{{(vb[^}]*)}}%s*\n|%s*tarih%s*=%s*([^\n]*)\n|%s*zaman%s*=%s*([^\n]*)\n|%s*sonuç%s*=%s*([^\n]*)\n|%s*set1%s*=%s*([^\n]*)\n|%s*set2%s*=%s*([^\n]*)\n|%s*set3%s*=%s*([^\n]*)\n|%s*set4%s*=%s*([^\n]*)\n|%s*set5%s*=%s*([^\n]*)"
    local templateName = "Şablon:" .. league .. " maçları/maçlar"
    local templatePage = mw.title.new(templateName)
    local content = templatePage:getContent()
    local lastMatchPlayed = nil
    local function initTeam(teamCode)
        if not teams[teamCode] then
            teams[teamCode] = {
                name = teamCode,
                matches = 0,
                wins = 0,
                losses = 0,
                points = 0,
                setsWon = 0,
                setsLost = 0,
                pointsWon = 0,
                pointsLost = 0,
                s3Win = 0,
                s4Win = 0,
                s5Win = 0,
                s3Lose = 0,
                s4Lose = 0,
                s5Lose = 0,
                sr = 0,
                pr = 0
            }
        end
    end

    -- Tüm maçları işle
    for round, team1, team2, t1, t2, date, time, result, s1, s2, s3, s4, s5 in mw.ustring.gmatch(content, pattern) do
        if filterRound == '' or round == filterRound then

            initTeam(team1)
            initTeam(team2)
            if result ~= "-" then
                lastMatchPlayed = date
                teams[team1].matches = teams[team1].matches + 1
                teams[team2].matches = teams[team2].matches + 1

                local sets = {s1, s2, s3, s4, s5}
                local team1Sets = 0
                local team2Sets = 0

                -- Set skorlarını hesapla
                for _, set in ipairs(sets) do
                    if set and set ~= "" and mw.ustring.sub(set, 1, 1) ~= "|" then
                        local t1Score, t2Score = set:match("(%d+)-(%d+)")
                        if t1Score and t2Score then
                            t1Score = tonumber(t1Score)
                            t2Score = tonumber(t2Score)

                            -- Puan toplamları
                            teams[team1].pointsWon = teams[team1].pointsWon + t1Score
                            teams[team1].pointsLost = teams[team1].pointsLost + t2Score
                            teams[team2].pointsWon = teams[team2].pointsWon + t2Score
                            teams[team2].pointsLost = teams[team2].pointsLost + t1Score

                            -- Set kazananı
                            if t1Score > t2Score then
                                team1Sets = team1Sets + 1
                                teams[team1].setsWon = teams[team1].setsWon + 1
                                teams[team2].setsLost = teams[team2].setsLost + 1
                            else
                                team2Sets = team2Sets + 1
                                teams[team2].setsWon = teams[team2].setsWon + 1
                                teams[team1].setsLost = teams[team1].setsLost + 1
                            end
                        end
                    end
                end

                -- Maç sonucunu belirle ve puan ver
                if team1Sets > team2Sets then
                    teams[team1].wins = teams[team1].wins + 1
                    teams[team2].losses = teams[team2].losses + 1

                    if team1Sets == 3 and team2Sets == 0 then
                        teams[team1].s3Win = teams[team1].s3Win + 1
                        teams[team2].s3Lose = teams[team2].s3Lose + 1
                    elseif team1Sets == 3 and team2Sets == 1 then
                        teams[team1].s4Win = teams[team1].s4Win + 1
                        teams[team2].s4Lose = teams[team2].s4Lose + 1
                    elseif team1Sets == 3 and team2Sets == 2 then
                        teams[team1].s5Win = teams[team1].s5Win + 1
                        teams[team2].s5Lose = teams[team2].s5Lose + 1
                    end
                else
                    teams[team2].wins = teams[team2].wins + 1
                    teams[team1].losses = teams[team1].losses + 1

                    if team2Sets == 3 and team1Sets == 0 then
                        teams[team2].s3Win = teams[team2].s3Win + 1
                        teams[team1].s3Lose = teams[team1].s3Lose + 1
                    elseif team2Sets == 3 and team1Sets == 1 then
                        teams[team2].s4Win = teams[team2].s4Win + 1
                        teams[team1].s4Lose = teams[team1].s4Lose + 1
                    elseif team2Sets == 3 and team1Sets == 2 then
                        teams[team2].s5Win = teams[team2].s5Win + 1
                        teams[team1].s5Lose = teams[team1].s5Lose + 1
                    end
                end
            end
        end
    end
    -- Tüm maçlar işlendikten SONRA her takım için hesaplamaları yap
    for teamCode, team in pairs(teams) do
        -- Puan hesaplama: (s3Win + s4Win) * 3 + s5Win * 2 + s5Lose
        teams[teamCode].points = (team.s3Win + team.s4Win) * 3 + team.s5Win * 2 + team.s5Lose

        -- SR hesaplama: setsWon / setsLost
        if team.setsLost > 0 then
            teams[teamCode].sr = team.setsWon / team.setsLost
            teams[teamCode].sr = math.floor(teams[teamCode].sr * 1000) / 1000
        else
            teams[teamCode].sr = team.setsWon
        end
        mw.log(teamCode .. ' ' .. teams[teamCode].sr)
        -- PR hesaplama: pointsWon / pointsLost
        if team.pointsLost > 0 then
            teams[teamCode].pr = team.pointsWon / team.pointsLost
            teams[teamCode].pr = math.floor(teams[teamCode].pr * 1000) / 1000
        else
            teams[teamCode].pr = team.pointsWon
        end
    end

    -- Takımları sırala (wins, points, SR, PR sırasıyla)
    local sortedTeams = {}
    for teamCode, team in pairs(teams) do
        table.insert(sortedTeams, {
            code = teamCode,
            data = team
        })
    end

    table.sort(sortedTeams, function(a, b)
        -- Önce galibiyet sayısına göre sırala (fazla olan üstte)
        if a.data.wins ~= b.data.wins then
            return a.data.wins > b.data.wins
        end

        -- Galibiyetler eşitse, puana göre sırala (fazla olan üstte)  
        if a.data.points ~= b.data.points then
            return a.data.points > b.data.points
        end

        -- Puanlar eşitse, set oranına göre sırala (yüksek olan üstte)
        -- Set oranı karşılaştırması - setsLost = 0 olanlar MAX (üstte)
        local a_sr_is_max = (a.data.setsLost == 0)
        local b_sr_is_max = (b.data.setsLost == 0)

        -- Eğer biri MAX diğeri değilse, MAX olan üstte
        if a_sr_is_max and not b_sr_is_max then
            return true
        elseif not a_sr_is_max and b_sr_is_max then
            return false
        elseif a_sr_is_max and b_sr_is_max then
            -- İkisi de MAX ise, diğer kriterlere geç
        else
            -- İkisi de normal değer ise, büyük olan üstte
            if math.abs(a.data.sr - b.data.sr) > 0.001 then
                return a.data.sr > b.data.sr
            end
        end

        -- Set oranları eşitse, puan oranına göre sırala (yüksek olan üstte)
        if math.abs(a.data.pr - b.data.pr) > 0.001 then -- Float karşılaştırması için tolerance
            return a.data.pr > b.data.pr
        end

        -- Hepsi eşitse takım koduna göre alfabetik sırala (consistency için)
        return a.code < b.code
    end)

    local output = {}
    table.insert(output, '{{#invoke:Spor tablosu|main|style=Voleybol')
    -- Team order satırı
    local teamOrder = {}
    for _, team in ipairs(sortedTeams) do
        table.insert(teamOrder, team.code)
    end
    table.insert(output, "|team_order=" .. table.concat(teamOrder, ", "))
    table.insert(output, "")

    -- Name satırları
    for _, team in ipairs(sortedTeams) do
        local teamCode = team.code
        if teamCode == teamFinalist then
            table.insert(output,
                "|name_" .. teamCode .. "={{" .. gender .. "|" .. teamCode .. "}} |note_" .. teamCode ..
                    "=Finallere ev sahibi olarak katılmaya hak kazandı\n")
        else
            table.insert(output, "|name_" .. teamCode .. "={{" .. gender .. "|" .. teamCode .. "}}\n")
        end
        table.insert(output,
            "|win3s_" .. teamCode .. "=" .. team.data.s3Win .. " |win4s_" .. teamCode .. "=" .. team.data.s4Win ..
                " |win5s_" .. teamCode .. "=" .. team.data.s5Win .. " |loss5s_" .. teamCode .. "=" .. team.data.s5Lose ..
                " |loss4s_" .. teamCode .. "=" .. team.data.s4Lose .. " |loss3s_" .. teamCode .. "=" .. team.data.s3Lose ..
                " |spw_" .. teamCode .. "=" .. team.data.pointsWon .. " |spl_" .. teamCode .. "=" ..
                team.data.pointsLost .. "\n")

    end
    local positionFinalist = 0
    for i, team in ipairs(sortedTeams) do
        if teamFinalist ~= nil then
            if teamFinalist == team.code then
                positionFinalist = i
                break
            end
        end
    end

    for _, rule in ipairs(qualificationRules) do
        table.insert(output, '|col_' .. rule.name .. '=' .. rule.color .. '|text_' .. rule.name .. '=' .. rule.text)
        if positionFinalist > rule.finish then
            -- eğer finalist takım zaten kontenjan alamadıysa bir kontenjan azalt
            rule.finish = rule.finish - 1
        end
        for i = rule.start, rule.finish - 1 do

            table.insert(output, '|result' .. i .. '=' .. rule.name)
        end
    end

    if teamFinalist ~= nil and qualificationRules[1] ~= nil then
        table.insert(output, '|col_QH=#87ceeb|text_QH=' .. qualificationRules[1].text)
        table.insert(output, '|result' .. positionFinalist .. '=QH')
    end

    local allowedParams = {'res_col_header', 'update', 'start_date', 'source', 'class_rules'}

    for _, param in ipairs(allowedParams) do
        if args[param] and mw.text.trim(args[param]) ~= '' then
            table.insert(output, '|' .. param .. '=' .. args[param])
        end
    end
    if lastMatchPlayed ~= nil then
        table.insert(output, '|update=' .. lastMatchPlayed)
    end
    table.insert(output, '}}')
    return mw.text.trim(frame:preprocess(table.concat(output, "\n")))
end
function p.matches(frame)
    local league = frame.args[1]
    local team = frame.args[2] or ''
    local filterRound = frame.args['Round'] or ''
    local pattern =
        "|(..)-(...)-(...)%s*=%s*\n{{vb res %d+\n|%s*takım1%s*=%s*{{(vb[^}]*)}}%s*\n|%s*takım2%s*=%s*{{(vb[^}]*)}}%s*\n|%s*tarih%s*=%s*([^\n]*)\n|%s*zaman%s*=%s*([^\n]*)\n|%s*sonuç%s*=%s*([^\n]*)\n|%s*set1%s*=%s*([^\n]*)\n|%s*set2%s*=%s*([^\n]*)\n|%s*set3%s*=%s*([^\n]*)\n|%s*set4%s*=%s*([^\n]*)\n|%s*set5%s*=%s*([^\n]*)"
    local templateName = "Şablon:" .. league .. " maçları/maçlar"
    local templatePage = mw.title.new(templateName)
    local content = templatePage:getContent()
    local results = {}
    table.insert(results, "<div style='overflow-x: auto; white-space: nowrap;'>\n{{Vb res start 5}}")

    for round, team1, team2, t1, t2, date, time, result, s1, s2, s3, s4, s5 in mw.ustring.gmatch(content, pattern) do
        if (filterRound == '' or round == filterRound) and (team == '' or team1 == team or team2 == team) then
            local pattern2 = "(%d+)%s*-%s*(%d+)"
            local matchResult = ''
            for num1, num2 in mw.ustring.gmatch(result, pattern2) do
                if result == '-' then
                    matchResult = " "
                end
                if team == team1 then
                    matchResult = (num1 > num2 and "G") or (num1 < num2 and "M") or "B"
                elseif team == team2 then
                    matchResult = (num1 > num2 and "M") or (num1 < num2 and "G") or "B"
                end

            end
            table.insert(results, "{{" .. league .. " maçları|" .. round .. '-' .. team1 .. "-" .. team2 .. "|" ..
                matchResult .. "}}")

        end
    end
    table.insert(results, "{{end}}")

    return mw.text.trim(frame:preprocess(table.concat(results, "\n")))

end
return p
