-- ============================================================================
-- 台灣家庭每日三餐料理推薦 App — 資料庫 Schema (PostgreSQL / Supabase 規格)
-- 核心定位：「掌廚介面適老化（超大字、語音、防黑屏），菜色內容全家化（三代同堂老少咸宜）」
-- 版權合規聲明：
-- 1. 食材僅記錄客觀名稱與份量（事實陳述）
-- 2. 料理步驟皆經系統重寫為 3~4 個 35 字內之大字摘要，嚴禁複製部落格原文
-- 3. 影片唯一使用 YouTube 官方 Video ID 與起始秒數 (start_seconds)，全面排除抖音
-- ============================================================================

-- 1. 台灣當季農產食材字典表 (對齊農業部農糧署台灣時令蔬果月份)
CREATE TABLE IF NOT EXISTS seasonal_produce (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,        -- 食材名稱（如：高麗菜、白蘿蔔、絲瓜、雞腿、五花肉）
    category VARCHAR(30) NOT NULL,           -- '葉菜根莖' | '瓜果菇類' | '肉類海鮮' | '豆蛋製品'
    peak_months INT[] NOT NULL               -- 台灣盛產月份陣列，如 {10, 11, 12, 1, 2, 3}
);

-- 2. 料理方式（8 大烹調法）字典表
CREATE TABLE IF NOT EXISTS cooking_methods (
    code VARCHAR(30) PRIMARY KEY,            -- '家常快炒' | '紅燒／滷製' | '清蒸／電鍋' | '燉煮／煲湯' | '香煎／乾煎' | '烤箱／氣炸' | '川燙／涼拌' | '金黃油炸'
    label VARCHAR(30) NOT NULL,              -- 顯示名稱
    icon VARCHAR(10) NOT NULL,               -- 大圖示：'🥬', '🥘', '♨️', '🍲', '🍳', '🔥', '🥗', '🍤'
    oil_level VARCHAR(20) NOT NULL,          -- 用油程度：'無油煙' | '少油' | '一般家常' | '油炸'
    description VARCHAR(120)                 -- 烹調法說明
);

-- 3. 料理食譜主表（全家大小皆宜）
CREATE TABLE IF NOT EXISTS recipes (
    id VARCHAR(50) PRIMARY KEY,              -- 食譜代號，如 'tw-001'
    title VARCHAR(100) NOT NULL,             -- 菜名（超大字體顯示）
    meal_slot VARCHAR(20) NOT NULL,          -- '早餐活力' | '午餐便當菜' | '晚餐豐盛主菜' | '暖心湯品'
    cooking_method VARCHAR(30) NOT NULL,     -- 對應 8 大烹調法
    is_deep_fried BOOLEAN DEFAULT FALSE,     -- 是否為油炸料理（供「🚫 不吃油炸」開關一鍵過濾）
    cook_time_mins INT NOT NULL,             -- 預估料理時間（分鐘）
    season_months INT[] NOT NULL,            -- 適合推薦的台灣月份 (1~12)
    family_tags TEXT[] NOT NULL,             -- 全家餐桌標籤，如 {'#白飯殺手', '#小孩超愛', '#長輩好咬', '#帶便當首選'}
    family_tip VARCHAR(150),                 -- 全家共食小撇步（如：一鍋兩吃調整辣度/軟硬度技巧）
    youtube_video_id VARCHAR(20) NOT NULL,   -- YouTube 官方影片 ID
    youtube_start_sec INT DEFAULT 0,         -- 自動跳過片頭閒聊、直接進入備料/下鍋的秒數
    youtube_channel VARCHAR(100) NOT NULL,   -- 官方頻道名稱標註
    steps JSONB NOT NULL,                    -- 3~4 個精簡大字步驟陣列
    is_ai_generated BOOLEAN DEFAULT FALSE,   -- 是否由 AI 即時生成
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. 食譜食材清單表（支援買菜打勾與 LINE 轉傳）
CREATE TABLE IF NOT EXISTS recipe_ingredients (
    id SERIAL PRIMARY KEY,
    recipe_id VARCHAR(50) REFERENCES recipes(id) ON DELETE CASCADE,
    ingredient_name VARCHAR(50) NOT NULL,    -- 食材名稱（供語音搜尋匹配）
    amount_desc VARCHAR(50) NOT NULL,        -- 份量描述（約 3~4 人全家份量）
    sort_order INT DEFAULT 1
);

-- 建立食材名稱、季節月份與料理方式索引
CREATE INDEX IF NOT EXISTS idx_recipes_season ON recipes USING GIN (season_months);
CREATE INDEX IF NOT EXISTS idx_recipes_method ON recipes (cooking_method, is_deep_fried);
CREATE INDEX IF NOT EXISTS idx_ingredients_name ON recipe_ingredients (ingredient_name);
