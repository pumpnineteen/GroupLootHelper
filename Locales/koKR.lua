

local L = LibStub("AceLocale-3.0"):NewLocale("GroupLootHelper", "koKR")
if not L then return end

L["PATTERN_LOOT_ITEM"] = {
    pattern = "(.+) 님이 아이템을 획득했습니다: (.+)",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ITEM_MULTIPLE"] = {
    pattern = "(.+) 님이 아이템을 획득했습니다: (.+)x(%%d+)",
    payload = {"looter", "loot", "amount"}
}

L["PATTERN_LOOT_ITEM_PUSHED"] = {
    pattern = "(.+) 님이 아이템을 받았습니다: (.+)",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ITEM_PUSHED_MULTIPLE"] = {
    pattern = "(.+) 님이 아이템을 받았습니다: (.+)x(%%d+)",
    payload = {"looter", "loot", "amount"}
}

L["PATTERN_LOOT_ITEM_PUSHED_SELF"] = {
    pattern = "아이템을 획득했습니다: (.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ITEM_PUSHED_SELF_MULTIPLE"] = {
    pattern = "아이템을 획득했습니다: (.+)x(%%d+)",
    payload = {"loot", "amount"}
}

L["PATTERN_LOOT_ITEM_SELF"] = {
    pattern = "아이템을 획득했습니다: (.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ITEM_SELF_MULTIPLE"] = {
    pattern = "아이템을 획득했습니다: (.+)x(%%d+)",
    payload = {"loot", "amount"}
}

L["PATTERN_LOOT_ROLL_DISENCHANT"] = {
    pattern = "(.+) 님이 마력 추출을 선택했습니다: (.+)",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_DISENCHANT_SELF"] = {
    pattern = "|HlootHistory:%%d+|h%[전리품%]|h: 마력 추출을 선택했습니다: (.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_GREED"] = {
    pattern = "(.+) 님이 차비를 선택했습니다: (.+)",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_GREED_SELF"] = {
    pattern = "|HlootHistory:%%d+|h%[전리품%]|h: 차비를 선택했습니다: (.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_NEED"] = {
    pattern = "(.+) 님이 입찰을 선택했습니다: (.+)",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_NEED_SELF"] = {
    pattern = "|HlootHistory:%%d+|h%[전리품%]|h: 입찰을 선택했습니다: (.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_PASSED"] = {
    pattern = "(.+) 님이 주사위 굴리기를 포기했습니다: (.+)",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_AUTO"] = {
    pattern = "(.+) 님이 획득할 수 없는 아이템이어서 자동으로 주사위 굴리기를 포기했습니다: (.+)",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_AUTO_FEMALE"] = {
    pattern = "(.+) 님이 획득할 수 없는 아이템이어서 자동으로 주사위 굴리기를 포기했습니다: (.+)",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_SELF"] = {
    pattern = "|HlootHistory:%%d+|h%[전리품%]|h: 주사위 굴리기를 포기했습니다: (.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_SELF_AUTO"] = {
    pattern = "|HlootHistory:%%d+|h%[전리품%]|h: 획득할 수 없는 아이템이어서 자동으로 주사위 굴리기를 포기했습니다: (.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_ROLLED_DE"] = {
    pattern = "(.+) 님이 마력 추출 아이템에 주사위를 굴려 (%%d+)|1이;가; 나왔습니다: (.+)",
    payload = {"looter", "roll", "loot"}
}

L["PATTERN_LOOT_ROLL_ROLLED_GREED"] = {
    pattern = "(.+) 님이 차비 아이템에 주사위를 굴려 (%%d+)|1이;가; 나왔습니다: (.+)",
    payload = {"looter", "roll", "loot"}
}

L["PATTERN_LOOT_ROLL_ROLLED_NEED"] = {
    pattern = "(.+) 님이 입찰 아이템에 주사위를 굴려 (%%d+)|1이;가; 나왔습니다: (.+)",
    payload = {"looter", "roll", "loot"}
}

L["PATTERN_LOOT_ROLL_ROLLED_NEED_ROLE_BONUS"] = {
    pattern = "(.+) 님이 역할 보너스를 받고 입찰 아이템에 주사위를 굴려 (%%d+)|1이;가; 나왔습니다: (.+)",
    payload = {"looter", "roll", "loot"}
}

L["LOOT_ROLL_ALL_PASSED"] = {
    pattern = "모두 포기: (.+)",
    payload = {'loot'}
}