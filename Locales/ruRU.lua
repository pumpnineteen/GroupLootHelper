

local L = LibStub("AceLocale-3.0"):NewLocale("GroupLootHelper", "ruRU")
if not L then return end

L["PATTERN_LOOT_ITEM"] = {
    pattern = "(.+) получает добычу: (.+)%.",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ITEM_MULTIPLE"] = {
    pattern = "(.+) получает добычу: (.+)x(%%d+)%.",
    payload = {"looter", "loot", "amount"}
}

L["PATTERN_LOOT_ITEM_PUSHED"] = {
    pattern = "(.+) получает предмет: (.+)%.",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ITEM_PUSHED_MULTIPLE"] = {
    pattern = "(.+) получает предмет: (.+)x(%%d+)%.",
    payload = {"looter", "loot", "amount"}
}

L["PATTERN_LOOT_ITEM_PUSHED_SELF"] = {
    pattern = "Вы получаете предмет: (.+)%.",
    payload = {"loot"}
}

L["PATTERN_LOOT_ITEM_PUSHED_SELF_MULTIPLE"] = {
    pattern = "Вы получаете предмет: (.+)x(%%d+)%.",
    payload = {"loot", "amount"}
}

L["PATTERN_LOOT_ITEM_SELF"] = {
    pattern = "Ваша добыча: (.+)%.",
    payload = {"loot"}
}

L["PATTERN_LOOT_ITEM_SELF_MULTIPLE"] = {
    pattern = "Ваша добыча: (.+)x(%%d+)%.",
    payload = {"loot", "amount"}
}

L["PATTERN_LOOT_ROLL_DISENCHANT"] = {
    pattern = "Разыгрывается: (.+)%." .. " (.+): \"Распылить\"%.",
    payload = {"loot", "looter"}
}

L["PATTERN_LOOT_ROLL_DISENCHANT_SELF"] = {
    pattern = "Разыгрывается: (.+)%." .. " Вы сказали: \"Распылить\"%.",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_GREED"] = {
    pattern = "Разыгрывается: (.+)%." .. " (.+): \"Не откажусь\"%.",
    payload = {"loot", "looter"}
}

L["PATTERN_LOOT_ROLL_GREED_SELF"] = {
    pattern = "Разыгрывается: (.+)%." .. " Вы сказали: \"Не откажусь\"%.",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_NEED"] = {
    pattern = "Разыгрывается: (.+)%." .. " (.+): \"Мне это нужно\"%.",
    payload = {"loot", "looter"}
}

L["PATTERN_LOOT_ROLL_NEED_SELF"] = {
    pattern = "Разыгрывается: (.+)%." .. " Вы сказали: \"Мне это нужно\"%.",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_PASSED"] = {
    pattern = "(.+) отказывается от предмета (.+)%.",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_AUTO"] = {
    pattern = "(.+) автоматически передает предмет (.+), поскольку не может его забрать%.",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_AUTO_FEMALE"] = {
    pattern = "(.+) пропускает розыгрыш предмета \"(.+)\", поскольку не может его забрать%.",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_SELF"] = {
    pattern = "Вы отказались от предмета: (.+)%.",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_SELF_AUTO"] = {
    pattern = "вы пропускаете розыгрыш предмета \"(.+)\", поскольку не можете его забрать%.",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_ROLLED_DE"] = {
    pattern = "Результат броска |3%-1%((.+)%) %(%\"Распылить%\"%) за предмет (.+): (%%d+)%.",
    payload = {"looter", "loot", "roll"}
}

L["PATTERN_LOOT_ROLL_ROLLED_GREED"] = {
    pattern = "Результат броска |3%-1%((.+)%) %(%\"Не откажусь%\"%) за предмет (.+): (%%d+)%.",
    payload = {"looter", "loot", "roll"}
}

L["PATTERN_LOOT_ROLL_ROLLED_NEED"] = {
    pattern = "Результат броска |3%-1%((.+)%) %(%\"Нужно%\"%) за предмет (.+): (%%d+)%.",
    payload = {"looter", "loot", "roll"}
}

L["PATTERN_LOOT_ROLL_ROLLED_NEED_ROLE_BONUS"] = {
    pattern = "Результат броска |3%-1%((.+)%) %(%\"Нужно%\"%) за предмет (.+): (%%d+) с бонусом роли%.",
    payload = {"looter", "loot", "roll"}
}

L["LOOT_ROLL_ALL_PASSED"] = {
    pattern = "все отказываются от: (.+)",
    payload = {'loot'}
}