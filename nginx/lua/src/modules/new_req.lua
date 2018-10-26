local dbutil = require "dbutil"

local user_limit_rate = ngx.shared.user_limit_rate

if not user_limit_rate:get('hasInit') then
    return
end

function get_user_limit_rate_config( userid )
    -- 根据用户id获取用户配置的上传下载限速值
    sql = [[
        SELECT f_upload_rate, f_download_rate
        FROM t_limit_rate
        WHERE `f_obj_id` = "%s";
    ]]

    sql = string.format(sql, userid)

    local result = dbutil.query(sql)

    -- 取用户相关配置中最小值
    upload_rate = 100000
    download_rate = 100000
    if #result > 0 then
        for i=1, table.maxn(result) do
            if result[i]['f_upload_rate'] > 0 and result[i]['f_upload_rate'] < upload_rate then
                upload_rate = result[i]['f_upload_rate']
            end
            if result[i]['f_download_rate'] > 0 and result[i]['f_download_rate'] < download_rate then
                download_rate = result[i]['f_download_rate']
            end
        end
    else
        -- 从部门配置中获取上传下载速度
         sql = [[
            SELECT f_department_id
            FROM t_user_department_relation
            WHERE f_user_id = '%s'
        ]]

        sql = string.format(sql, userid)

        local result = dbutil.query(sql)
        depart_ids = {}
        for i=1, table.maxn(result) do
            table.insert(depart_ids, result[i]['f_department_id'])
            sql = [[
                SELECT `f_parent_department_id`
                FROM `t_department_relation`
                WHERE `f_department_id`= '%s'
            ]]

            sql = string.format(sql, result[i]['f_department_id'])

            local ret = dbutil.query(sql)
            for i=1, table.maxn(ret) do
                table.insert(depart_ids, ret[i]['f_parent_department_id'])
            end
        end
        if #depart_ids > 0 then
            sql = [[
                SELECT f_upload_rate, f_download_rate
                FROM t_limit_rate
                WHERE `f_obj_id` in (%s);
            ]]
            sql = string.format(sql, "'" .. table.concat(depart_ids, "','") .. "'")

            local ret = dbutil.query(sql)
            for i=1, table.maxn(ret) do
                if ret[i]['f_upload_rate'] > 0 and ret[i]['f_upload_rate'] < upload_rate then
                    upload_rate = ret[i]['f_upload_rate']
                end
                if ret[i]['f_download_rate'] > 0 and ret[i]['f_download_rate'] < download_rate then
                    download_rate = ret[i]['f_download_rate']
                end
            end
        end
    end

    if not upload_rate or upload_rate < 0 or upload_rate == 100000 then
        upload_rate = 0
    end

    if not download_rate or download_rate < 0 or download_rate == 100000 then
        download_rate = 0
    end
    return upload_rate, download_rate
end


-- 获取请求中userid
-- 针对下载请求限制GET请求速率
local method = ngx.var.request_method
if method == 'GET' then
    -- 针对get下载请求处理
    -- 1. 获取 x-as-userid
    local args = ngx.req.get_uri_args()
    limit_key = args["x-as-userid"]

    if not limit_key then
        local headers = ngx.req.get_headers(0)
        limit_key = headers["x-as-userid"]
    end


    if not limit_key or not string.find(limit_key, "^%x+-%x+-%x+-%x+-%x+$") then
        ngx.log(ngx.ERR, "limit_key ", limit_key)
        return
    end

    -- 2. 统计新增请求数
    sql = [[
        SELECT *
        FROM t_nginx_user_rate
        WHERE `f_userid` = "%s";
    ]]

    sql = string.format(sql, limit_key)

    local result = dbutil.query(sql)
    if #result == 0 then

        -- 从限速控制表中获取上传下载限速值
        upload_rate, download_rate = get_user_limit_rate_config(limit_key)

        sql = [[
            INSERT INTO t_nginx_user_rate (`f_userid`, `f_upload_rate`, `f_download_rate`, `f_download_req_cnt`) VALUE ("%s", %d, %d, f_download_req_cnt+1)
            ON DUPLICATE KEY UPDATE f_download_req_cnt=f_download_req_cnt+1;
        ]]
        sql = string.format(sql, limit_key, upload_rate, download_rate)
        dbutil.query(sql)

    else
        sql = [[
            UPDATE t_nginx_user_rate
            SET `f_download_req_cnt`=`f_download_req_cnt`+1
            WHERE `f_userid` = "%s";
        ]]
        sql = string.format(sql, limit_key)
        dbutil.query(sql)
    end

    -- 3. 获取初始限速值
    sql = [[
        SELECT f_download_req_cnt, f_download_rate
        FROM t_nginx_user_rate
        WHERE `f_userid` = "%s";
    ]]

    sql = string.format(sql, limit_key)

    local result = dbutil.query(sql)

    if #result == 1 then
        value = math.floor(result[1]['f_download_rate']/result[1]['f_download_req_cnt'])

        if result[1]['f_download_rate'] ~= 0 and value == 0 then
            value = value + 1
        end

        ngx.var.limit_rate = math.floor(value * 1024)
    end

    -- 4. 保存当前请求的limit_key
    ngx.ctx.limit_key = limit_key
    ngx.ctx.method = method


elseif method == 'PUT' or method == 'POST' then
    -- 针对post上传请求处理
    local headers = ngx.req.get_headers(0)
    limit_key = headers["x-as-userid"]

    if not limit_key or not string.find(limit_key, "^%x+-%x+-%x+-%x+-%x+$")then
        ngx.log(ngx.ERR, "limit_key ", limit_key)
        return
    end
    -- ngx.log(ngx.ERR, "method : limit_key: content_length: ", method .. ":" .. limit_key .. ":" .. ngx.var.content_length)

    -- 2. 统计新增请求数
    sql = [[
        SELECT *
        FROM t_nginx_user_rate
        WHERE `f_userid` = "%s";
    ]]

    sql = string.format(sql, limit_key)

    local result = dbutil.query(sql)
    if #result == 0 then

        -- 从限速控制表中获取上传下载限速值
        upload_rate, download_rate = get_user_limit_rate_config(limit_key)

        sql = [[
            INSERT INTO t_nginx_user_rate (`f_userid`, `f_upload_rate`, `f_download_rate`, `f_upload_req_cnt`) VALUE ("%s", %d, %d, f_upload_req_cnt+1)
            ON DUPLICATE KEY UPDATE f_upload_req_cnt=f_upload_req_cnt+1;
        ]]
        sql = string.format(sql, limit_key, upload_rate, download_rate)
        dbutil.query(sql)

    else
        sql = [[
            UPDATE t_nginx_user_rate
            SET `f_upload_req_cnt`=`f_upload_req_cnt`+1
            WHERE `f_userid` = "%s";
        ]]
        sql = string.format(sql, limit_key)
        dbutil.query(sql)
    end

    -- 3. 获取初始限速值
    sql = [[
        SELECT f_upload_req_cnt, f_upload_rate
        FROM t_nginx_user_rate
        WHERE `f_userid` = "%s";
    ]]
    sql = string.format(sql, limit_key)

    local result = dbutil.query(sql)

    if #result == 1 then
        if result[1]['f_upload_rate'] ~= 0 then

            if ngx.var.content_length then
                delay = math.floor(ngx.var.content_length / (result[1]['f_upload_rate'] / result[1]['f_upload_req_cnt'] * 1024))

                -- ngx.log(ngx.ERR, "delay:", delay)

                if delay > 20 then
                    delay = 20
                end

                ngx.sleep(delay)
            end

        end

    end

    -- 4. 保存当前请求的limit_key
    ngx.ctx.limit_key = limit_key
    ngx.ctx.method = method
end
