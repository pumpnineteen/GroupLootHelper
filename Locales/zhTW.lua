

local L = LibStub("AceLocale-3.0"):NewLocale("GroupLootHelper", "zhTW")
if not L then return end

L["PATTERN_LOOT_ITEM"] = {
    pattern = "(.+)獲得戰利品:(.+)。",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ITEM_MULTIPLE"] = {
    pattern = "(.+)獲得戰利品:(.+)x(%%d+)。",
    payload = {"looter", "loot", "amount"}
}

L["PATTERN_LOOT_ITEM_PUSHED"] = {
    pattern = "(.+)獲得物品:(.+)。",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ITEM_PUSHED_MULTIPLE"] = {
    pattern = "(.+)獲得物品:(.+)x(%%d+)。",
    payload = {"looter", "loot", "amount"}
}

L["PATTERN_LOOT_ITEM_PUSHED_SELF"] = {
    pattern = "你獲得了物品:(.+)。",
    payload = {"loot"}
}

L["PATTERN_LOOT_ITEM_PUSHED_SELF_MULTIPLE"] = {
    pattern = "你獲得物品:(.+)x(%%d+)。",
    payload = {"loot", "amount"}
}

L["PATTERN_LOOT_ITEM_SELF"] = {
    pattern = "你拾取了物品:(.+)。",
    payload = {"loot"}
}

L["PATTERN_LOOT_ITEM_SELF_MULTIPLE"] = {
    pattern = "你獲得戰利品:(.+)x(%%d+)。",
    payload = {"loot", "amount"}
}

L["PATTERN_LOOT_ROLL_DISENCHANT"] = {
    pattern = "(.+)選擇分解:(.+)",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_DISENCHANT_SELF"] = {
    pattern = "你選擇了分解:(.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_GREED"] = {
    pattern = "(.+)選擇了貪婪:(.+)",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_GREED_SELF"] = {
    pattern = "你選擇了貪婪:(.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_NEED"] = {
    pattern = "(.+)選擇了需求:(.+)",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_NEED_SELF"] = {
    pattern = "你選擇了需求:(.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_PASSED"] = {
    pattern = "(.+)放棄了:(.+)",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_AUTO"] = {
    pattern = "(.+)自動放棄:(.+)，因為他無法使用這項物品。",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_AUTO_FEMALE"] = {
    pattern = "(.+)自動放棄:(.+)，因為她無法使用這項物品。",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_SELF"] = {
    pattern = "你放棄了:(.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_SELF_AUTO"] = {
    pattern = "因為你無法拾取，你自動放棄了物品:(.+)。",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_ROLLED_DE"] = {
    pattern = "分解 %- (.+)由(.+)擲出(%%d+)",
    payload = {"loot", "looter", "roll"}
}

L["PATTERN_LOOT_ROLL_ROLLED_GREED"] = {
    pattern = "貪婪 %- (.+)由(.+)擲出(%%d+)",
    payload = {"loot", "looter", "roll"}
}

L["PATTERN_LOOT_ROLL_ROLLED_NEED"] = {
    pattern = "需求 %- (.+)由(.+)擲出(%%d+)",
    payload = {"loot", "looter", "roll"}
}

L["PATTERN_LOOT_ROLL_ROLLED_NEED_ROLE_BONUS"] = {
    pattern = "%(需求%+角色加成%)" .. "(%%d+)" .. "點:(.+)%((.+)%)",
    payload = {"roll", "loot", "looter"}
}

L["LOOT_ROLL_ALL_PASSED"] = {
    pattern = "所有人都放棄了:(.+)",
    payload = {'loot'}
}