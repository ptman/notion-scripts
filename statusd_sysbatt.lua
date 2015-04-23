-- sysbatt - notion battery status script for /sys/class/power_supply interface
--
-- There are many battery status scripts for notion, but this one is mine.
-- It works on my Debian Jessie system with Linux 3.16
--
-- Copyright (c) 2015, Paul Tötterman <paul.totterman@iki.fi>
--
-- Permission to use, copy, modify, and/or distribute this software for any
-- purpose with or without fee is hereby granted, provided that the above
-- copyright notice and this permission notice appear in all copies.
--
-- THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
-- WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
-- MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
-- ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
-- WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
-- ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
-- OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

function get_sysbatt()
    f = io.open('/sys/class/power_supply/BAT0/uevent')
    if not f then
        return ''
    end
    s = f:read('*a')
    f:close()

    local i, j, status = string.find(s, 'POWER_SUPPLY_STATUS=(%S+)')
    local i, j, capacity = string.find(s, 'POWER_SUPPLY_CAPACITY=(%d+)')
    local i, j, full = string.find(s, 'POWER_SUPPLY_ENERGY_FULL=(%d+)')
    local i, j, now = string.find(s, 'POWER_SUPPLY_ENERGY_NOW=(%d+)')
    local i, j, draw = string.find(s, 'POWER_SUPPLY_POWER_NOW=(%d+)')

    return status, tonumber(capacity), tonumber(full), tonumber(now), tonumber(draw)
end

function update_sysbatt()
    local status, capacity, full, now, draw = get_sysbatt()
    statusd.inform('sysbatt_status', tostring(status))
    statusd.inform('sysbatt_capacity', tostring(capacity))
    local time
    if status == 'Charging' then
        time = (full-now)/draw
    elseif status == 'Discharging' then
        time = now/draw
    end
    local hours = math.floor(time)
    local mins = math.floor(((time)-hours)*60)
    statusd.inform('sysbatt_left', string.format('%dh%02dmin', hours, mins))

    sysbatt_timer:set(60000, update_sysbatt)
end

sysbatt_timer = statusd.create_timer()
update_sysbatt()
