local dbutil = require "dbutil"
local user_limit_rate = ngx.shared.user_limit_rate

if not user_limit_rate:get('hasInit') then
    return
end

function handler(premature, limit_key, method)

    if not limit_key then
        return
    end

    if method == 'GET' then
        sql = [[
            UPDATE t_nginx_user_rate
            SET `f_download_req_cnt`=`f_download_req_cnt`-1
            WHERE `f_userid` = "%s" and `f_download_req_cnt` > 0;
        ]]
        -- ngx.log(ngx.ERR, "limit_key: ", limit_key)
        sql = string.format(sql, limit_key)
    elseif method == 'PUT' or method == 'POST' then
        sql = [[
            UPDATE t_nginx_user_rate
            SET `f_upload_req_cnt`=`f_upload_req_cnt`-1
            WHERE `f_userid` = "%s" and `f_upload_req_cnt` > 0;;
        ]]
        -- ngx.log(ngx.ERR, "limit_key: ", limit_key)
        sql = string.format(sql, limit_key)
    end

    dbutil.query(sql)
end

local delay = 0
local ok, err = ngx.timer.at(delay, handler, ngx.ctx.limit_key, ngx.ctx.method)
if not ok then
        ngx.log(ngx.ERR, "failed to create the timer: ", err)
        return
end