

local L = LibStub("AceLocale-3.0"):NewLocale("GroupLootHelper", "zhCN")
if not L then return end

L["PATTERN_LOOT_ITEM"] = {
    pattern = "(.+)获得了物品：(.+)。",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ITEM_MULTIPLE"] = {
    pattern = "(.+)获得了物品：(.+)x(%%d+)。",
    payload = {"looter", "loot", "amount"}
}

L["PATTERN_LOOT_ITEM_PUSHED"] = {
    pattern = "(.+)获得了物品：(.+)。",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ITEM_PUSHED_MULTIPLE"] = {
    pattern = "(.+)获得了物品：(.+)x(%%d+)。",
    payload = {"looter", "loot", "amount"}
}

L["PATTERN_LOOT_ITEM_PUSHED_SELF"] = {
    pattern = "你获得了物品：(.+)。",
    payload = {"loot"}
}

L["PATTERN_LOOT_ITEM_PUSHED_SELF_MULTIPLE"] = {
    pattern = "你获得了：(.+)x(%%d+)。",
    payload = {"loot", "amount"}
}

L["PATTERN_LOOT_ITEM_SELF"] = {
    pattern = "你获得了物品：(.+)。",
    payload = {"loot"}
}

L["PATTERN_LOOT_ITEM_SELF_MULTIPLE"] = {
    pattern = "你得到了物品：(.+)x(%%d+)。",
    payload = {"loot", "amount"}
}

L["PATTERN_LOOT_ROLL_DISENCHANT"] = {
    pattern = "(.+)选择了分解取向：(.+)",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_DISENCHANT_SELF"] = {
    pattern = "你选择了分解取向：(.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_GREED"] = {
    pattern = "(.+)选择了贪婪取向：(.+)",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_GREED_SELF"] = {
    pattern = "你选择了贪婪取向：(.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_NEED"] = {
    pattern = "(.+)选择了需求取向：(.+)",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_NEED_SELF"] = {
    pattern = "你选择了需求取向：(.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_PASSED"] = {
    pattern = "(.+)放弃了：(.+)",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_AUTO"] = {
    pattern = "(.+)自动放弃了(.+)，因为他无法拾取该物品。",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_AUTO_FEMALE"] = {
    pattern = "(.+)自动放弃了(.+)，因为她无法拾取该物品。",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_SELF"] = {
    pattern = "你放弃了：(.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_SELF_AUTO"] = {
    pattern = "你自动放弃了(.+)，因为你无法拾取该物品。",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_ROLLED_DE"] = {
    pattern = "（分解）(%%d+)点：(.+)（(.+)）",
    payload = {"roll", "loot", "looter"}
}

L["PATTERN_LOOT_ROLL_ROLLED_GREED"] = {
    pattern = "（贪婪）(%%d+)点：(.+)（(.+)）",
    payload = {"roll", "loot", "looter"}
}

L["PATTERN_LOOT_ROLL_ROLLED_NEED"] = {
    pattern = "（需求）(%%d+)点：(.+)（(.+)）",
    payload = {"roll", "loot", "looter"}
}

L["PATTERN_LOOT_ROLL_ROLLED_NEED_ROLE_BONUS"] = {
    pattern = "（需求%+职责加成）(%%d+)点：(.+)（(.+)）",
    payload = {"roll", "loot", "looter"}
}

L["LOOT_ROLL_ALL_PASSED"] = {
    pattern = "所有人都放弃了：(.+)",
    payload = {'loot'}
}