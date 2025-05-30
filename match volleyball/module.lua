local p = {}

function p.standings(frame)
    local league = frame.args[1]
    local teamFinalist = frame.args['teamFinalist']
    local results = {}
    local teams = {}
    local pattern =
        "|(..)-(...)-(...)%s*=%s*\n{{vb res %d+\n|%s*takım1%s*=%s*{{vb%-rt|([^}]*)}}%s*\n|%s*takım2%s*=%s*{{vb|([^}]*)}}%s*\n|%s*tarih%s*=%s*([^\n]*)\n|%s*zaman%s*=%s*([^\n]*)\n|%s*sonuç%s*=%s*([^\n]*)\n|%s*set1%s*=%s*([^\n]*)\n|%s*set2%s*=%s*([^\n]*)\n|%s*set3%s*=%s*([^\n]*)\n|%s*set4%s*=%s*([^\n]*)\n|%s*set5%s*=%s*([^\n]*)"
    local templateName = "Şablon:" .. league .. " maçları/maçlar"
    local templatePage = mw.title.new(templateName)
    local content = templatePage:getContent()

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
        initTeam(team1)
        initTeam(team2)

        teams[team1].matches = teams[team1].matches + 1
        teams[team2].matches = teams[team2].matches + 1

        local sets = {s1, s2, s3, s4, s5}
        local team1Sets = 0
        local team2Sets = 0

        -- Set skorlarını hesapla
        for _, set in ipairs(sets) do
            if set and set ~= "" then
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
        if a.data.wins ~= b.data.wins then
            return a.data.wins > b.data.wins
        elseif a.data.points ~= b.data.points then
            return a.data.points > b.data.points
        elseif a.data.sr ~= b.data.sr then
            return a.data.sr > b.data.sr
        else
            return a.data.pr > b.data.pr
        end
    end)

    -- Çıktı oluştur
    local output = {}

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
            table.insert(output, "|name_" .. teamCode .. "={{vb|" .. teamCode .. "}} |note_" .. teamCode ..
                "=Finallere ev sahibi olarak katılmaya hak kazandı")
        else
            table.insert(output, "|name_" .. teamCode .. "={{vb|" .. teamCode .. "}}")
        end
    end

    return table.concat(output, "\n")
end

return p
