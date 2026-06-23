local p = {}

local function count_events(str, template_name)
    local l_str = string.lower(str)
    local sub_l = "{{" .. string.lower(template_name)
    local total = 0
    local idx = 1
    while true do
        local start_pos, end_pos = string.find(l_str, sub_l, idx, true)
        if not start_pos then break end
        
        local close_pos = string.find(l_str, "}}", end_pos, true)
        if not close_pos then
            total = total + 1
            idx = end_pos + 1
        else
            local inner_text = string.sub(l_str, end_pos + 1, close_pos - 1)
            if template_name == "kırmızı kart" then
                total = total + 1
            else
                local count = 0
                for param in string.gmatch(inner_text, "|([^|]+)") do
                    if string.find(param, "%d") then
                        count = count + 1
                    end
                end
                if count == 0 then count = 1 end
                total = total + count
            end
            idx = close_pos + 2
        end
    end
    return total
end

local function extract_param(block, param_name)
    local pat = "|%s*" .. param_name .. "%s*="
    local start_idx, eq_idx = string.find(block, pat)
    if not eq_idx then return "" end
    
    local next_param_idx = string.find(block, "\n|", eq_idx)
    if not next_param_idx then
        return string.sub(block, eq_idx + 1)
    end
    return string.sub(block, eq_idx + 1, next_param_idx - 1)
end

local function clean_name(name)
    name = string.gsub(name, "<!%-%-.-%-%->", "")
    name = string.gsub(name, "%[%[[^%|%]]+%|([^%]]+)%]%]", "%1")
    name = string.gsub(name, "%[%[([^%]]+)%]%]", "%1")
    name = string.match(name, "^%s*(.-)%s*$")
    if not name or name == "" or name == "Belirlenmedi" then return nil end
    return name
end

function p.all_referees(frame)
    local args = frame:getParent().args
    if not args.page then args = frame.args end
    
    local page_name = args.page
    if not page_name then return '<strong class="error">Error: "page" parameter is required.</strong>' end
    local title = mw.title.new(page_name)
    if not title then return '<strong class="error">Error: Invalid page name.</strong>' end
    local content = title:getContent()
    if not content then return '<strong class="error">Error: Could not read page content.</strong>' end
    
    local referees = {}
    local function get_referee(n)
        n = clean_name(n)
        if not n then return nil end
        if not referees[n] then referees[n] = {matches = 0, var = 0, yellow = 0, red = 0, penalty = 0} end
        return referees[n]
    end

    local last_idx = 1
    while true do
        local pos = string.find(content, "{{Kapanabilir futbol maçı kutusu", last_idx, true)
        local block
        if pos then
            block = string.sub(content, last_idx, pos - 1)
            last_idx = pos + 1
        else
            block = string.sub(content, last_idx)
        end
        
        if block and block ~= "" then
            local ref_param = extract_param(block, "hakem")
            local current_ref = get_referee(ref_param)
            if current_ref then
                current_ref.matches = current_ref.matches + 1
                current_ref.yellow = current_ref.yellow + count_events(block, "sarı kart")
                current_ref.red = current_ref.red + count_events(block, "kırmızı kart")
                current_ref.penalty = current_ref.penalty + count_events(block, "baspenaltı") + count_events(block, "kaçpenaltı")
            end
            
            local fifth_param = extract_param(block, "beşincihakem")
            if fifth_param ~= "" then
                for v_name in string.gmatch(fifth_param, "[^,]+") do
                    local v_obj = get_referee(v_name)
                    if v_obj then v_obj.var = v_obj.var + 1 end
                end
            end
        end
        if not pos then break end
    end
    
    local sorted_referees = {}
    for name, stats in pairs(referees) do table.insert(sorted_referees, {name = name, stats = stats}) end
    table.sort(sorted_referees, function(a, b)
        if a.stats.matches == b.stats.matches then return a.name < b.name end
        return a.stats.matches > b.stats.matches
    end)
    
    local tbl = {}
    table.insert(tbl, '{| class="wikitable sortable" style="text-align:center;"')
    table.insert(tbl, '|+ Hakem istatistikleri')
    table.insert(tbl, '|-')
    table.insert(tbl, '! Hakem !! [[File:Football-referee-whistle.svg|19px]] !! [[File:VAR System Logo.svg|19px]] !! {{sarı kart}} !! {{kırmızı kart}} !! [[File:Penalty goal.png|19px]]')
    for _, item in ipairs(sorted_referees) do
        if item.stats.matches > 0 or item.stats.var > 0 then
            table.insert(tbl, '|-')
            table.insert(tbl, '| align="left" | ' .. item.name .. ' || ' .. item.stats.matches .. ' || ' .. item.stats.var .. ' || ' .. item.stats.yellow .. ' || ' .. item.stats.red .. ' || ' .. item.stats.penalty)
        end
    end
    table.insert(tbl, '|}')
    return frame:preprocess(table.concat(tbl, "\n"))
end

function p.detailed_analysis(frame)
    local args = frame:getParent().args
    if not args.page then args = frame.args end
    
    local page_name = args.page
    if not page_name then return '<strong class="error">Error: "page" parameter is required.</strong>' end
    local title = mw.title.new(page_name)
    if not title then return '<strong class="error">Error: Invalid page name.</strong>' end
    local content = title:getContent()
    if not content then return '<strong class="error">Error: Could not read page content.</strong>' end
    
    local referees = {}
    local function get_or_create_ref(n)
        if not referees[n] then
            referees[n] = {
                matches = 0, yellow = 0, red = 0, penalty = 0,
                teams = {}
            }
        end
        return referees[n]
    end

    local last_idx = 1
    while true do
        local pos = string.find(content, "{{Kapanabilir futbol maçı kutusu", last_idx, true)
        local block
        if pos then
            block = string.sub(content, last_idx, pos - 1)
            last_idx = pos + 1
        else
            block = string.sub(content, last_idx)
        end
        
        if block and block ~= "" then
            local ref_raw = extract_param(block, "hakem")
            local ref_name = clean_name(ref_raw)
            
            if ref_name then
                local ref = get_or_create_ref(ref_name)
                ref.matches = ref.matches + 1
                
                local team1_raw = extract_param(block, "takım1")
                local team2_raw = extract_param(block, "takım2")
                local team1 = clean_name(team1_raw)
                local team2 = clean_name(team2_raw)
                
                local goals1 = extract_param(block, "goller1")
                local goals2 = extract_param(block, "goller2")
                
                local g1_y = count_events(goals1, "sarı kart")
                local g1_r = count_events(goals1, "kırmızı kart")
                local g1_p = count_events(goals1, "baspenaltı") + count_events(goals1, "kaçpenaltı")
                
                local g2_y = count_events(goals2, "sarı kart")
                local g2_r = count_events(goals2, "kırmızı kart")
                local g2_p = count_events(goals2, "baspenaltı") + count_events(goals2, "kaçpenaltı")
                
                ref.yellow = ref.yellow + g1_y + g2_y
                ref.red = ref.red + g1_r + g2_r
                ref.penalty = ref.penalty + g1_p + g2_p
                
                local match_tur = extract_param(block, "tur")
                local match_tarih = extract_param(block, "tarih")
                local match_t1 = extract_param(block, "takım1")
                local match_t2 = extract_param(block, "takım2")
                local match_sonuc = extract_param(block, "sonuç")
                
                if not ref.match_list then ref.match_list = {} end
                table.insert(ref.match_list, {
                    tur = match_tur,
                    tarih = match_tarih,
                    t1 = match_t1,
                    t2 = match_t2,
                    sonuc = match_sonuc,
                    s = g1_y + g2_y,
                    k = g1_r + g2_r,
                    p = g1_p + g2_p
                })
                
                local score_raw = match_sonuc
                local s1_str, s2_str = string.match(score_raw, "(%d+)%s*%-%s*(%d+)")
                local w1, d1, l1 = 0, 0, 0
                local w2, d2, l2 = 0, 0, 0
                
                if s1_str and s2_str then
                    local s1, s2 = tonumber(s1_str), tonumber(s2_str)
                    if s1 > s2 then
                        w1 = 1; l2 = 1
                    elseif s1 < s2 then
                        l1 = 1; w2 = 1
                    else
                        d1 = 1; d2 = 1
                    end
                end
                
                if team1 then
                    if not ref.teams[team1] then ref.teams[team1] = {m=0, w=0, d=0, l=0, ty=0, tr=0, oy=0, or_c=0, pf=0, pa=0} end
                    local t1 = ref.teams[team1]
                    t1.m = t1.m + 1
                    t1.w = t1.w + w1
                    t1.d = t1.d + d1
                    t1.l = t1.l + l1
                    t1.ty = t1.ty + g1_y
                    t1.tr = t1.tr + g1_r
                    t1.oy = t1.oy + g2_y
                    t1.or_c = t1.or_c + g2_r
                    t1.pf = t1.pf + g1_p
                    t1.pa = t1.pa + g2_p
                end
                
                if team2 then
                    if not ref.teams[team2] then ref.teams[team2] = {m=0, w=0, d=0, l=0, ty=0, tr=0, oy=0, or_c=0, pf=0, pa=0} end
                    local t2 = ref.teams[team2]
                    t2.m = t2.m + 1
                    t2.w = t2.w + w2
                    t2.d = t2.d + d2
                    t2.l = t2.l + l2
                    t2.ty = t2.ty + g2_y
                    t2.tr = t2.tr + g2_r
                    t2.oy = t2.oy + g1_y
                    t2.or_c = t2.or_c + g1_r
                    t2.pf = t2.pf + g2_p
                    t2.pa = t2.pa + g1_p
                end
            end
        end
        if not pos then break end
    end
    
    local sorted_refs = {}
    for name, data in pairs(referees) do
        table.insert(sorted_refs, {name=name, data=data})
    end
    table.sort(sorted_refs, function(a, b)
        if a.data.matches == b.data.matches then return a.name < b.name end
        return a.data.matches > b.data.matches
    end)
    
    local out = {}
    for _, ref_item in ipairs(sorted_refs) do
        table.insert(out, "=== " .. ref_item.name .. " ===")
        
        table.insert(out, '{| class="wikitable"')
        table.insert(out, '|+ Genel istatistikler')
        table.insert(out, '|-')
        table.insert(out, '! [[File:Football-referee-whistle.svg|19px]] !! {{sarı kart}} !! {{kırmızı kart}} !! [[File:Penalty goal.png|19px]]')
        table.insert(out, '|-')
        table.insert(out, '| align="center" | ' .. ref_item.data.matches .. ' || align="center" | ' .. ref_item.data.yellow .. ' || align="center" | ' .. ref_item.data.red .. ' || align="center" | ' .. ref_item.data.penalty)
        table.insert(out, '|}')
        table.insert(out, '')
        
        table.insert(out, "==== Takıma göre istatistikler ====")
        table.insert(out, '{| class="wikitable sortable" style="text-align:center;"')
        table.insert(out, '|-')
        table.insert(out, '! rowspan="2" | Takım !! rowspan="2" | [[File:Football-referee-whistle.svg|19px]] !! rowspan="2" | G !! rowspan="2" | B !! rowspan="2" | M !! colspan="3" | Takıma !! colspan="3" | Rakibine')
        table.insert(out, '|-')
        table.insert(out, '! {{sarı kart}} !! {{kırmızı kart}} !! [[File:Penalty goal.png|19px]] !! {{sarı kart}} !! {{kırmızı kart}} !! [[File:Penalty goal.png|19px]]')
        
        local sorted_teams = {}
        for t_name, t_data in pairs(ref_item.data.teams) do
            table.insert(sorted_teams, {name=t_name, d=t_data})
        end
        table.sort(sorted_teams, function(a, b)
            if a.d.m == b.d.m then return a.name < b.name end
            return a.d.m > b.d.m
        end)
        
        for _, t_item in ipairs(sorted_teams) do
            table.insert(out, '|-')
            table.insert(out, '| align="left" | ' .. t_item.name .. ' || ' .. t_item.d.m .. ' || ' .. t_item.d.w .. ' || ' .. t_item.d.d .. ' || ' .. t_item.d.l .. ' || ' .. t_item.d.ty .. ' || ' .. t_item.d.tr .. ' || ' .. t_item.d.pf .. ' || ' .. t_item.d.oy .. ' || ' .. t_item.d.or_c .. ' || ' .. t_item.d.pa)
        end
        
        table.insert(out, '|}')
        table.insert(out, '')
        
        table.insert(out, "==== Yönettiği maçlar ====")
        table.insert(out, '{| class="wikitable sortable" style="text-align:center;"')
        table.insert(out, '|-')
        table.insert(out, '! Hafta !! Tarih !! Ev sahibi !! Deplasman !! Skor !! {{sarı kart}} !! {{kırmızı kart}} !! [[File:Penalty goal.png|19px]]')
        
        if ref_item.data.match_list then
            for _, m in ipairs(ref_item.data.match_list) do
                table.insert(out, '|-')
                table.insert(out, '| ' .. mw.text.trim(m.tur) .. ' || ' .. mw.text.trim(m.tarih) .. ' || align="right" | ' .. mw.text.trim(m.t1) .. ' || align="left" | ' .. mw.text.trim(m.t2) .. ' || ' .. mw.text.trim(m.sonuc) .. ' || ' .. m.s .. ' || ' .. m.k .. ' || ' .. m.p)
            end
        end
        
        table.insert(out, '|}')
        table.insert(out, '')
    end
    
    return frame:preprocess(table.concat(out, "\n"))
end

function p.team_details(frame)
    local args = frame:getParent().args
    if not args.page then args = frame.args end
    
    local page_name = args.page
    local target_team = args[1]
    if not page_name then return '<strong class="error">Error: "page" parameter is required.</strong>' end
    if not target_team then return '<strong class="error">Error: Takım adı parametresi gereklidir (örneğin |Beşiktaş).</strong>' end
    
    local title = mw.title.new(page_name)
    if not title then return '<strong class="error">Error: Invalid page name.</strong>' end
    local content = title:getContent()
    if not content then return '<strong class="error">Error: Could not read page content.</strong>' end
    
    local ref_stats = {}
    
    local last_idx = 1
    local next_code1, next_code2 = nil, nil
    while true do
        local pos = string.find(content, "{{Kapanabilir futbol maçı kutusu", last_idx, true)
        local block
        local current_code1, current_code2 = next_code1, next_code2
        if pos then
            block = string.sub(content, last_idx, pos - 1)
            last_idx = pos + 1
            
            local prefix = string.sub(content, math.max(1, pos - 50), pos - 1)
            next_code1, next_code2 = string.match(prefix, "|%s*([%wÇĞİÖŞÜçğıöşü]+)%s*%-%s*([%wÇĞİÖŞÜçğıöşü]+)%s*=%s*$")
        else
            block = string.sub(content, last_idx)
        end
        
        if block and block ~= "" then
            local team1_raw = extract_param(block, "takım1")
            local team2_raw = extract_param(block, "takım2")
            local team1 = clean_name(team1_raw)
            local team2 = clean_name(team2_raw)
            
            local is_target_team1 = (team1 == target_team) or (current_code1 == target_team)
            local is_target_team2 = (team2 == target_team) or (current_code2 == target_team)
            
            if is_target_team1 or is_target_team2 then
                local ref_raw = extract_param(block, "hakem")
                local ref_name = clean_name(ref_raw)
                
                if ref_name then
                    if not ref_stats[ref_name] then
                        ref_stats[ref_name] = {m=0, w=0, d=0, l=0, ty=0, tr=0, oy=0, or_c=0, pf=0, pa=0}
                    end
                    local r = ref_stats[ref_name]
                    
                    local goals1 = extract_param(block, "goller1")
                    local goals2 = extract_param(block, "goller2")
                    
                    local g1_y = count_events(goals1, "sarı kart")
                    local g1_r = count_events(goals1, "kırmızı kart")
                    local g1_p = count_events(goals1, "baspenaltı") + count_events(goals1, "kaçpenaltı")
                    
                    local g2_y = count_events(goals2, "sarı kart")
                    local g2_r = count_events(goals2, "kırmızı kart")
                    local g2_p = count_events(goals2, "baspenaltı") + count_events(goals2, "kaçpenaltı")
                    
                    local match_tur = extract_param(block, "tur")
                    local match_tarih = extract_param(block, "tarih")
                    local match_sonuc = extract_param(block, "sonuç")
                    
                    local score_raw = match_sonuc
                    local s1_str, s2_str = string.match(score_raw, "(%d+)%s*%-%s*(%d+)")
                    local w1, d1, l1 = 0, 0, 0
                    local w2, d2, l2 = 0, 0, 0
                    
                    if s1_str and s2_str then
                        local s1, s2 = tonumber(s1_str), tonumber(s2_str)
                        if s1 > s2 then
                            w1 = 1; l2 = 1
                        elseif s1 < s2 then
                            l1 = 1; w2 = 1
                        else
                            d1 = 1; d2 = 1
                        end
                    end
                    
                    r.m = r.m + 1
                    if is_target_team1 then
                        r.w = r.w + w1
                        r.d = r.d + d1
                        r.l = r.l + l1
                        r.ty = r.ty + g1_y
                        r.tr = r.tr + g1_r
                        r.oy = r.oy + g2_y
                        r.or_c = r.or_c + g2_r
                        r.pf = r.pf + g1_p
                        r.pa = r.pa + g2_p
                    else
                        r.w = r.w + w2
                        r.d = r.d + d2
                        r.l = r.l + l2
                        r.ty = r.ty + g2_y
                        r.tr = r.tr + g2_r
                        r.oy = r.oy + g1_y
                        r.or_c = r.or_c + g1_r
                        r.pf = r.pf + g2_p
                        r.pa = r.pa + g1_p
                    end
                end
            end
        end
        if not pos then break end
    end
    
    local sorted_refs = {}
    for name, data in pairs(ref_stats) do
        table.insert(sorted_refs, {name=name, d=data})
    end
    table.sort(sorted_refs, function(a, b)
        if a.d.m == b.d.m then return a.name < b.name end
        return a.d.m > b.d.m
    end)
    
    local out = {}
    table.insert(out, '{| class="wikitable sortable" style="text-align:center;"')
    table.insert(out, '|-')
    table.insert(out, '! rowspan="2" | Hakem !! rowspan="2" | [[File:Football-referee-whistle.svg|19px]] !! rowspan="2" | G !! rowspan="2" | B !! rowspan="2" | M !! colspan="3" | Takıma !! colspan="3" | Rakibine')
    table.insert(out, '|-')
    table.insert(out, '! {{sarı kart}} !! {{kırmızı kart}} !! [[File:Penalty goal.png|19px]] !! {{sarı kart}} !! {{kırmızı kart}} !! [[File:Penalty goal.png|19px]]')
    
    for _, r_item in ipairs(sorted_refs) do
        table.insert(out, '|-')
        table.insert(out, '| align="left" | ' .. r_item.name .. ' || ' .. r_item.d.m .. ' || ' .. r_item.d.w .. ' || ' .. r_item.d.d .. ' || ' .. r_item.d.l .. ' || ' .. r_item.d.ty .. ' || ' .. r_item.d.tr .. ' || ' .. r_item.d.pf .. ' || ' .. r_item.d.oy .. ' || ' .. r_item.d.or_c .. ' || ' .. r_item.d.pa)
    end
    
    table.insert(out, '|}')
    table.insert(out, '')
    
    return frame:preprocess(table.concat(out, "\n"))
end

return p
