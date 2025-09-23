local p = {}

-- Şablon çıktısını parse eden fonksiyon
local function parseTemplateOutput(templateOutput)
    local data = {}

    -- Şablon çıktısı "sıra|puan" formatında gelir
    local rank, points = mw.ustring.match(templateOutput, "^(%d+)|([%d%.]+)$")
    if rank and points then
        return {
            rank = tonumber(rank),
            points = tonumber(points)
        }
    end

    return nil
end

-- Şablon içeriğinden takım kodlarını çıkaran fonksiyon
local function parseTeamsFromTemplate(content, gender)
    local teams = {}

    -- Şablon içeriğini debug için log'la
    mw.log("Template content length: " .. mw.ustring.len(content))

    -- Gender bölümünü bul - daha esnek pattern kullan
    local genderPattern = "%|%s*" .. gender .. "%s*%s*="
    local genderStart = mw.ustring.find(content, genderPattern)

    if not genderStart then
        mw.log("Gender section not found for: " .. gender)
        return teams
    end

    mw.log("Found gender section at position: " .. genderStart)

    -- Gender bölümünün sonunu bul
    local nextSection = mw.ustring.find(content, "%|%s*%w+%s*=", genderStart + 1100)
    local genderEnd = nextSection or mw.ustring.len(content)

    local genderSection = mw.ustring.sub(content, genderStart, genderEnd)
    mw.log("Gender section: " .. mw.ustring.sub(genderSection, 1, 200) .. "...")

    -- Takım kodlarını çıkar - daha basit pattern
    for line in mw.ustring.gmatch(genderSection, "[^\n]+") do
        local teamCode, rank, points = mw.ustring.match(line, "%s*%|%s*(%w+)%s*=%s*(%d+)%|([%d%.]+)")
        if teamCode and teamCode ~= gender then
            table.insert(teams, {
                teamCode = teamCode,
                rank = tonumber(rank),
                points = tonumber(points)
            })
            mw.log("Found team: " .. teamCode)
        end
    end
    table.sort(teams, function(a, b)
        return a.rank < b.rank
    end)
    return teams
end

-- Tüm takımları listeleyen fonksiyon
function p.list(frame)
    local gender = (frame.args.gender or "women"):lower()
    local abbrv = ''
    if gender == "women" then
        abbrv = "vbk"
    else
        abbrv = "vb"
    end
    -- Şablon içeriğini al
    local templatePage = mw.title.new("Şablon:FIVB Dünya sıralaması")
    if not templatePage or not templatePage.exists then
        return "Şablon bulunamadı"
    end

    local content = templatePage:getContent()
    if not content then
        return "Şablon içeriği okunamadı"
    end

    -- Takım kodlarını dinamik olarak çıkar
    local teams = parseTeamsFromTemplate(content, gender)

    mw.logObject(teams)
    -- Tablo oluştur
    local out = {}
    table.insert(out, '{| class="wikitable"\n! Sıra !! Takım !! Puan\n')
    for _, teamData in ipairs(teams) do
        table.insert(out, '|-\n|' .. teamData.rank .. '|| {{' .. abbrv .. '|' .. teamData.teamCode .. '}} ||' ..
            teamData.points .. ' \n')
    end
    table.insert(out, '|}')

    return mw.text.trim(frame:preprocess(table.concat(out, "\n")))
end

-- Belirli bir takımın bilgisini getiren fonksiyon
function p.get(frame)
    local gender = (frame.args.gender or "women"):lower()
    local team = frame.args.team or ""

    if team == "" then
        return "Takım kodu belirtilmedi"
    end

    -- Şablonu çağır
    local templateOutput = frame:expandTemplate{
        title = "FIVB Dünya sıralaması",
        args = {
            gender = gender,
            team = team
        }
    }

    -- Eğer çıktı "Takım bulunamadı" ise
    if templateOutput == "Takım bulunamadı" then
        return "Takım bulunamadı"
    end

    local info = parseTemplateOutput(templateOutput)
    if not info then
        return "Veri parse edilemedi"
    end

    return string.format("%d|%.2f", info.rank, info.points)
end

-- Sadece sıra bilgisini getiren fonksiyon
function p.getRank(frame)
    local gender = (frame.args.gender or "women"):lower()
    local team = frame.args.team or ""

    if team == "" then
        return "Takım kodu belirtilmedi"
    end

    local templateOutput = frame:expandTemplate{
        title = "FIVB Dünya sıralaması",
        args = {
            gender = gender,
            team = team
        }
    }

    if templateOutput == "Takım bulunamadı" then
        return "Takım bulunamadı"
    end

    local info = parseTemplateOutput(templateOutput)
    if not info then
        return "Veri parse edilemedi"
    end

    return tostring(info.rank)
end

-- Sadece puan bilgisini getiren fonksiyon
function p.getPoints(frame)
    local gender = (frame.args.gender or "women"):lower()
    local team = frame.args.team or ""

    if team == "" then
        return "Takım kodu belirtilmedi"
    end

    local templateOutput = frame:expandTemplate{
        title = "FIVB Dünya sıralaması",
        args = {
            gender = gender,
            team = team
        }
    }

    if templateOutput == "Takım bulunamadı" then
        return "Takım bulunamadı"
    end

    local info = parseTemplateOutput(templateOutput)
    if not info then
        return "Veri parse edilemedi"
    end

    return string.format("%.2f", info.points)
end

return p
