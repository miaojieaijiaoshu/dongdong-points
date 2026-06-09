-- 咚咚的积分宝箱 - 数据库初始化脚本

-- 1. 规则表
create table if not exists rules (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  description text,
  category text not null default 'other',
  rule_type text not null default 'simple', -- 'simple' | 'tiered'
  points int,           -- simple 规则用
  tiers jsonb,          -- tiered 规则用，格式：[{label, points, before_time, after_time}]
  is_active boolean default true,
  sort_order int default 0,
  created_at timestamptz default now()
);

-- 2. 积分记录表
create table if not exists transactions (
  id uuid default gen_random_uuid() primary key,
  rule_id uuid references rules(id) on delete set null,
  description text not null,
  points int not null,
  status text not null default 'pending', -- pending | approved | rejected
  submitted_at timestamptz default now(),
  reviewed_at timestamptz,
  metadata jsonb  -- 存额外信息，如选择的时间段
);

-- 3. 礼品表
create table if not exists rewards (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  description text,
  points_cost int not null,
  is_active boolean default true,
  sort_order int default 0,
  created_at timestamptz default now()
);

-- 4. 兑换申请表
create table if not exists redemptions (
  id uuid default gen_random_uuid() primary key,
  reward_id uuid references rewards(id) on delete set null,
  reward_name text not null,
  points_cost int not null,
  status text not null default 'pending', -- pending | approved | rejected
  submitted_at timestamptz default now(),
  reviewed_at timestamptz,
  note text
);

-- 5. 设置表
create table if not exists settings (
  key text primary key,
  value jsonb not null
);

-- RLS 策略：允许匿名用户读写所有表（家长PIN在前端控制）
alter table rules enable row level security;
alter table transactions enable row level security;
alter table rewards enable row level security;
alter table redemptions enable row level security;
alter table settings enable row level security;

create policy "allow all" on rules for all using (true) with check (true);
create policy "allow all" on transactions for all using (true) with check (true);
create policy "allow all" on rewards for all using (true) with check (true);
create policy "allow all" on redemptions for all using (true) with check (true);
create policy "allow all" on settings for all using (true) with check (true);

-- 初始设置
insert into settings (key, value) values
  ('pin', '"1234"'),
  ('child_name', '"咚咚"')
on conflict (key) do nothing;

-- 初始规则
insert into rules (name, description, category, rule_type, points, tiers, sort_order) values
(
  '完成作业',
  '下午完成当天作业',
  '作业',
  'tiered',
  null,
  '[
    {"label": "5点前完成", "points": 3, "before_time": "17:00"},
    {"label": "6点前完成", "points": 2, "before_time": "18:00"},
    {"label": "8点前完成", "points": 1, "before_time": "20:00"},
    {"label": "8点后完成", "points": 0, "before_time": "21:30"},
    {"label": "9点半后未完成", "points": -1, "before_time": null}
  ]'::jsonb,
  1
),
(
  '准时出门',
  '早上出门上学的时间',
  '早起',
  'tiered',
  null,
  '[
    {"label": "7点半及之前出门", "points": 1, "before_time": "07:31"},
    {"label": "7点35后出门", "points": -1, "before_time": null}
  ]'::jsonb,
  2
),
(
  '坚持游泳',
  '今天去游了泳',
  '运动',
  'simple',
  1,
  null,
  3
);

-- 初始礼品示例
insert into rewards (name, description, points_cost, sort_order) values
  ('自选一个玩具', '去商场或网上自选一个玩具', 50, 1),
  ('看一场电影', '去电影院看一部你想看的电影', 30, 2),
  ('玩游戏1小时', '在规定时间外额外玩1小时游戏', 10, 3),
  ('选一次晚饭', '你来决定今晚吃什么', 5, 4);
