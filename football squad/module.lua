local p = {}

function p.kadro(frame)
    local Args = frame.args
    local ii_start = tonumber(Args['highest_pos']) or 1
    local N_players = ii_start - 1
    local t = {}
    local player_list = {}
    local last_names_count = {} -- To track duplicate last names
    local unknown_players = {}
    -- Read team details
    local team_name = Args['team_name'] or Args['takım_adı']
    local title = Args['title'] or Args['başlık']
    local back_color = Args['back_color'] or Args['zeminrengi']
    local text_color = Args['text_color'] or Args['metinrengi']
    local side_color = Args['side_color'] or Args['kenarrengi']
    local temp_name = Args['temp_name'] or Args['şablon_adı'] or (team_name .. ' kadrosu')
    local coach_name = Args['coach_name'] or Args['teknik_direktör']
    local update = Args['update'] or Args['güncelleme']
    local typetemp = tonumber(Args['type']) or tonumber(Args['tip']) or 0

    local function new_playerFormatParse(param_value, number)
        -- Check if it's in the new format by looking for patterns like name=
        if type(param_value) == "string" and (param_value:find("name=") or param_value:find("ad=")) then
            -- Parse the parameter string to extract components
            local name = param_value:match("name=([^,}]+)") or param_value:match("ad=([^,}]+)")
            local position = param_value:match("position=([^,}]+)") or param_value:match("pozisyon=([^,}]+)")
            local country = param_value:match("country=([^,}]+)") or param_value:match("ülke=([^,}]+)")
            local loan = param_value:match("loan=([^,}]+)") or param_value:match("kiralık=([^,}]+)")
            local use_fullname = param_value:match("fullname=([^,}]+)") or param_value:match("tamad=([^,}]+)")
            local captain = param_value:match("kaptan=([^,}]+)") or param_value:match("captain=([^,}]+)")
            N_players = N_players + 1
            player_list[N_players] = {
                number = number,
                name = name or "",
                lname = "",
                country = country or "",
                position = position or "",
                loan = loan,
                use_fullname = use_fullname == "true" or use_fullname == "yes" or use_fullname == "evet",
                captain = captain
            }
        end
    end

    -- Process players using both formats
    for i = 0, 120 do -- Assuming 120 as a large enough limit for players
        -- Check for new format: number_i={name=...,position=...,country=...}
        if (Args['number_' .. i] or Args['numara_' .. i]) and not (Args['name_' .. i] or Args['ad_' .. i]) then
            local param_value = Args['number_' .. i] or Args['numara_' .. i]
            new_playerFormatParse(param_value, i)

            -- Check for old format: name_i, position_i, country_i, etc.
        elseif Args['name_' .. i] or Args['ad_' .. i] then
            N_players = N_players + 1
            player_list[N_players] = {
                number = Args['number_' .. i] or Args['no_' .. i] or Args['numara_' .. i] or i,
                name = Args['name_' .. i] or Args['ad_' .. i] or "",
                lname = Args['lname_' .. i] or Args['soyad_' .. i] or "",
                country = Args['country_' .. i] or Args['nat_' .. i] or Args['ülke_' .. i] or "",
                position = Args['position_' .. i] or Args['pos_' .. i] or Args['pozisyon_' .. i] or "",
                loan = Args['loan_' .. i] or Args['kiralık_' .. i],
                use_fullname = Args['fullname_' .. i] == "true" or Args['fullname_' .. i] == "yes" or
                    Args['tamad_' .. i] == "evet" or Args['tamad_' .. i] == "true"
            }
        end
    end
    for key, value in pairs(Args) do
        if key == 'number_?' or key == 'numara_?' then
            table.insert(unknown_players, value)
        end
    end

    for _, param_value in ipairs(unknown_players) do
        new_playerFormatParse(param_value, '—')
    end

    -- Function to get first name initial
    local function get_first_initial(name)
        -- Remove wiki markup brackets if present
        local clean_name = name:gsub("%[%[", ""):gsub("%]%]", "")

        -- Handle pipe in wiki links
        local pipe_pos = clean_name:find("|")
        if pipe_pos then
            clean_name = clean_name:sub(1, pipe_pos - 1)
        end

        -- Split the name and get the first initial
        local first_word = clean_name:match("(%S+)")
        if first_word then
            return first_word:sub(1, 1) .. "."
        end
        return ""
    end

    -- Function to get full player name without wiki brackets
    local function get_full_name(name)
        -- Remove wiki markup brackets if present
        local clean_name = name:gsub("%[%[", ""):gsub("%]%]", "")

        -- Handle pipe in wiki links
        local pipe_pos = clean_name:find("|")
        if pipe_pos then
            clean_name = clean_name:sub(1, pipe_pos - 1)
        end

        return clean_name
    end

    local function get_lastname(name)
        local names = {}
        local final_name

        if name:find("%(") then
            local position = name:find("%(")
            local before_parenthesis = name:sub(1, position - 1):match("^%s*(.-)%s*$")

            local sub_names = {}
            for sub_name in before_parenthesis:gmatch("%S+") do
                table.insert(sub_names, sub_name)
            end

            final_name = sub_names[#sub_names] or sub_names[1]
        else
            for name2 in name:gmatch("%S+") do
                table.insert(names, name2)
            end
            final_name = names[#names]
        end
        final_name = final_name:gsub("%[%[", ""):gsub("%]%]", "")
        return (final_name)
    end

    local function get_player_name(name)
        local pipe_position = name:find("|")
        local final_name

        if pipe_position then
            final_name = name:sub(1, pipe_position - 1)
        else
            final_name = name
        end

        final_name = final_name:gsub("%[%[", ""):gsub("%]%]", "")
        return (final_name)
    end

    -- First pass: Count occurrences of each last name
    for _, player in ipairs(player_list) do
        local last_name = get_lastname(player.name)
        last_names_count[last_name] = (last_names_count[last_name] or 0) + 1
    end

    local function insert_player(player)
        local ret = '{{Futbol takımı kadrosu-oyuncu|no=' .. player.number .. '|pos=' .. player.position .. '|nat=' ..
                        player.country .. '|name=' .. player.name ..
                        (player.captain ~= nil and '|other=\'\'\'' ..
                            (player.captain ~= "1" and player.captain .. '. ' or '') .. '[[Dosya:Kaptan logo.svg|13px|' ..
                            (player.captain) .. '. Kaptan]]\'\'\'' or '')

        if player.loan ~= nil then
            ret = ret .. ' <small>(' .. player.loan .. ' kiralık)</small>'
        end

        ret = ret .. '}}\n'

        return ret
    end

    local page = mw.title.getCurrentTitle()

    -- ilk parametre boşsa varsayılan görünümü getir
    if typetemp == 2 then
        if page.namespace == 0 then
            typetemp = 0
        end
    end

    if typetemp == 0 or typetemp == 2 then
        table.insert(t,
            '{{Futbol takımı kadrosu|takımadı=' .. title .. '|zeminrengi=' .. back_color .. '|metinrengi=' ..
                text_color .. '|kenarrengi=' .. side_color .. '|ad=' .. temp_name .. '\n|liste=\n')

        for _, player in ipairs(player_list) do
            local final_name = player.name:gsub("%[%[", ""):gsub("%]%]", "")
            local last_name = get_lastname(player.name)
            local display_name

            -- Check if we should use full name
            if player.use_fullname then
                display_name = get_full_name(player.name)
            else
                -- If there are multiple players with the same last name, use first initial
                if last_names_count[last_name] > 1 then
                    display_name = get_first_initial(player.name) .. " " .. last_name
                else
                    display_name = last_name
                end
            end

            -- bağlantı verilemiş ise
            if final_name == player.name then
                table.insert(t, '{{Futbol takımı kadrosu2-oyuncu|no=' .. player.number .. '|name=' .. display_name ..
                    (player.captain ~= nil and ' (\'\'\'[[Dosya:Kaptan logo.svg|13px|' ..
                        (player.captain ~= "1" and player.captain .. '. ' or '') .. 'Kaptan]]\'\'\')' or '') .. '}}\n')
            else
                table.insert(t,
                    '{{Futbol takımı kadrosu2-oyuncu|no=' .. player.number .. '|name=[[' ..
                        get_player_name(player.name) .. '|' .. display_name .. ']]' ..
                        (player.captain ~= nil and ' (\'\'\'' ..
                            (player.captain ~= "1" and player.captain .. '. ' or '') .. '[[Dosya:Kaptan logo.svg|13px|' ..
                            (player.captain ~= 1 and player.captain or '') .. '. Kaptan]]\'\'\')' or '') .. '}}\n')
            end
        end

        table.insert(t, '{{Futbol takımı kadrosu2-teknik direktör|name=' .. coach_name .. '}}\n')
        table.insert(t, '</div>}}\n')
    end

    if typetemp == 1 or typetemp == 2 then
        table.insert(t, '{{güncellendi|' .. update .. '}}\n')
        table.insert(t, '{{Futbol takımı kadrosu-başlangıç}}\n')

        for ii = ii_start, math.ceil(N_players / 2) do
            table.insert(t, insert_player(player_list[ii]))
        end

        table.insert(t, '{{Futbol takımı kadrosu-orta}}\n')

        for ii = math.ceil(N_players / 2) + 1, N_players do
            table.insert(t, insert_player(player_list[ii]))
        end

        table.insert(t, '{{Futbol takımı kadrosu-son}}\n')
    end

    return mw.text.trim(frame:preprocess(table.concat(t)))
end

return p
