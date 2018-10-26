-- 获取数据库连接信息，从sysvol/conf/cluster.conf配置中读取

local ini = require "ini"
local luabit = require "bit"

CLUSTER_CONF = '/sysvol/conf/cluster.conf'

data = ini.load(CLUSTER_CONF)

value = ini.get(data, 'cluster', 'use_external_db')

function decrypt_pwd(str)
    ngx.log(ngx.ERR, str)
    c = {string.byte(str, 1, -1)}
    n = #c
    if n % 2 ~= 0 then
        return ""
    end
    n = math.ceil(n/2)
    b = {string.byte(n)}
    j = 1
    for i =1,n do
        c1 = c[j]
        c2 = c[j + 1]
        j = j + 2
        c1 = c1 - 65
        c2 = c2 - 65
        b2 = c2 * 16 + c1
        b1 = luabit.bxor(b2, 32)
        b[i] = b1
    end
    return string.char(unpack(b))
end

if not value or string.upper(value) == 'FALSE' then
    host=ini.get(data, 'cluster', 'db_host')
    port=ini.get(data, 'cluster', 'db_port')
    user='Anyshare'
    passwd='asAlqlTkWU0zqfxrLTed'
else
    host=ini.get(data, 'cluster', 'db_host')
    port=ini.get(data, 'cluster', 'db_port')
    user=ini.get(data, 'cluster', 'db_user')
    passwd=ini.get(data, 'cluster', 'db_password')
    passwd = decrypt_pwd(passwd)
end


mysql_config = {
    DBHOST=host,
    DBPORT=port,
    DBUSER=user,
    DBPASSWORD=passwd,
    DBNAME="sharemgnt_db",
    DEFAULT_CHARSET="utf8",
}

return mysql_config