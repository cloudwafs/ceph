
-- 实时更新limit_rate值
local user_limit_rate = ngx.shared.user_limit_rate
ngx.var.limit_rate = user_limit_rate:get(ngx.ctx.limit_key) or ngx.var.limit_rate
