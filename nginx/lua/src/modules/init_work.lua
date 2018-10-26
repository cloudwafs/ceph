local dbutil = require "dbutil"

local delay = 0
local delay_ract = 15
local user_limit_rate = ngx.shared.user_limit_rate

function update_user_limit_rate(premature)
    if premature then
        return
    end

    local ok, err = ngx.timer.at(delay_ract, update_user_limit_rate)
    if not ok then
            ngx.log(ngx.ERR, "failed to create update_user_limit_rate timer: ", err)
            return
    end

    if user_limit_rate:get('hasInit') then
        sql = [[
            SELECT f_download_req_cnt, f_download_rate, f_userid
            FROM t_nginx_user_rate
            WHERE `f_download_req_cnt` > 0;
        ]]

        sql = string.format(sql)

        local result = dbutil.query(sql)

        if result then
            for i=1, table.maxn(result) do
                value = math.floor(result[i]['f_download_rate']/result[i]['f_download_req_cnt'])

                if result[i]['f_download_rate'] ~= 0 and value == 0 then
                    value = value + 1
                end

                user_limit_rate:set(result[i]['f_userid'], value * 1024, 2 * delay_ract)
            end
        end
    end

end

function init_user_req(premature)
    if premature then
        return
    end

    if not user_limit_rate:get('hasInit') then
        sql = [[
            UPDATE t_nginx_user_rate
            SET f_download_req_cnt = 0, f_upload_req_cnt = 0
        ]]

        sql = string.format(sql)

        local result = dbutil.query(sql)

        if result then
            user_limit_rate:set('hasInit', true)
            return
        end
        local ok, err = ngx.timer.at(delay_ract, init_user_req)
        if not ok then
                ngx.log(ngx.ERR, "failed to create init_user_req timer: ", err)
                return
        end
    end
end

if not user_limit_rate:get('hasInit') then

    local ok, err = ngx.timer.at(delay, init_user_req)
    if not ok then
            ngx.log(ngx.ERR, "failed to create the timer: ", err)
            return
    end
end

if not user_limit_rate:get('hasTimer') then
    user_limit_rate:set('hasTimer', true)

    local ok, err = ngx.timer.at(delay, update_user_limit_rate)
    if not ok then
            ngx.log(ngx.ERR, "failed to create the timer: ", err)
            return
    end
end