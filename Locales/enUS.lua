local debug = false

local L = LibStub("AceLocale-3.0"):NewLocale("GroupLootHelper", "enUS", true, debug)


L["PATTERN_LOOT_ITEM"] = {
    pattern = "(.+) receives loot: (.+)%.",
    payload = {'looter', 'loot'}
}

L["PATTERN_LOOT_ITEM_MULTIPLE"] = {
    pattern = "(.+) receives loot: (.+)x(%%d+)%.",
    payload = {'looter', 'loot', 'amount'}
}

L["PATTERN_LOOT_ITEM_PUSHED"] = {
    pattern = "(.+) receives item: (.+)%.",
    payload = {'looter', 'loot'}
}

L["PATTERN_LOOT_ITEM_PUSHED_MULTIPLE"] = {
    pattern = "(.+) receives item: (.+)x(%%d+)%.",
    payload = {'looter', 'loot', 'amount'}
}

L["PATTERN_LOOT_ITEM_PUSHED_SELF"] = {
    pattern = "You receive item: (.+)%.",
    payload = {'loot'}
}

L["PATTERN_LOOT_ITEM_PUSHED_SELF_MULTIPLE"] = {
    pattern = "You receive item: (.+)x(%%d+)%.",
    payload = {'loot', 'amount'}
}

L["PATTERN_LOOT_ITEM_SELF"] = {
    pattern = "You receive loot: (.+)%.",
    payload = {'loot'}
}

L["PATTERN_LOOT_ITEM_SELF_MULTIPLE"] = {
    pattern = "You receive loot: (.+)x(%%d+)%.",
    payload = {'loot', 'amount'}
}

L["PATTERN_LOOT_ROLL_DISENCHANT"] = {
    pattern = "(.+) has selected Disenchant for: (.+)",
    payload = {'looter', 'loot'}
}

L["PATTERN_LOOT_ROLL_DISENCHANT_SELF"] = {
    pattern = "You have selected Disenchant for: (.+)",
    payload = {'loot'}
}

L["PATTERN_LOOT_ROLL_GREED"] = {
    pattern = "(.+) has selected Greed for: (.+)",
    payload = {'looter', 'loot'}
}

L["PATTERN_LOOT_ROLL_GREED_SELF"] = {
    pattern = "You have selected Greed for: (.+)",
    payload = {'loot'}
}

L["PATTERN_LOOT_ROLL_NEED"] = {
    pattern = "(.+) has selected Need for: (.+)",
    payload = {'looter', 'loot'}
}

L["PATTERN_LOOT_ROLL_NEED_SELF"] = {
    pattern = "You have selected Need for: (.+)",
    payload = {'loot'}
}

L["PATTERN_LOOT_ROLL_PASSED"] = {
    pattern = "(.+) passed on: (.+)",
    payload = {'looter', 'loot'}
}

L["PATTERN_LOOT_ROLL_PASSED_AUTO"] = {
    pattern = "(.+) automatically passed on: (.+) because he cannot loot that item%.",
    payload = {'looter', 'loot'}
}

L["PATTERN_LOOT_ROLL_PASSED_AUTO_FEMALE"] = {
    pattern = "(.+) automatically passed on: (.+) because she cannot loot that item%.",
    payload = {'looter', 'loot'}
}

L["PATTERN_LOOT_ROLL_PASSED_SELF"] = {
    pattern = "You passed on: (.+)",
    payload = {'loot'}
}

L["PATTERN_LOOT_ROLL_PASSED_SELF_AUTO"] = {
    pattern = "You automatically passed on: (.+) because you cannot loot that item%.",
    payload = {'loot'}
}

L["PATTERN_LOOT_ROLL_ROLLED_DE"] = {
    pattern = "Disenchant Roll - (%%d+) for (.+) by (.+)",
    payload = {'roll', 'loot', 'looter'}
}

L["PATTERN_LOOT_ROLL_ROLLED_GREED"] = {
    pattern = "Greed Roll - (%%d+) for (.+) by (.+)",
    payload = {'roll', 'loot', 'looter'}
}

L["PATTERN_LOOT_ROLL_ROLLED_NEED"] = {
    pattern = "Need Roll - (%%d+) for (.+) by (.+)",
    payload = {'roll', 'loot', 'looter'}
}

L["PATTERN_LOOT_ROLL_ROLLED_NEED_ROLE_BONUS"] = {
    pattern = "Need Roll - (%%d+) for (.+) by (.+) %+ Role Bonus",
    payload = {'roll', 'loot', 'looter'}
}

L["LOOT_ROLL_ALL_PASSED"] = {
    pattern = "Everyone passed on: (.+)",
    payload = {'loot'}
}

