

local L = LibStub("AceLocale-3.0"):NewLocale("GroupLootHelper", "esMX")
if not L then return end

L["PATTERN_LOOT_ITEM"] = {
    pattern = "(.+) recibe el botín: (.+)%.",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ITEM_MULTIPLE"] = {
    pattern = "(.+) recibe el botín: (.+)x(%%d+)%.",
    payload = {"looter", "loot", "amount"}
}

L["PATTERN_LOOT_ITEM_PUSHED"] = {
    pattern = "(.+) recibe el objeto: (.+)%.",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ITEM_PUSHED_MULTIPLE"] = {
    pattern = "(.+) recibe el objeto: (.+)x(%%d+)%.",
    payload = {"looter", "loot", "amount"}
}

L["PATTERN_LOOT_ITEM_PUSHED_SELF"] = {
    pattern = "Recibes: (.+)%.",
    payload = {"loot"}
}

L["PATTERN_LOOT_ITEM_PUSHED_SELF_MULTIPLE"] = {
    pattern = "Recibes: (.+)x(%%d+)%.",
    payload = {"loot", "amount"}
}

L["PATTERN_LOOT_ITEM_SELF"] = {
    pattern = "Recibes botín: (.+)%.",
    payload = {"loot"}
}

L["PATTERN_LOOT_ITEM_SELF_MULTIPLE"] = {
    pattern = "Recibes botín: (.+)x(%%d+)%.",
    payload = {"loot", "amount"}
}

L["PATTERN_LOOT_ROLL_DISENCHANT"] = {
    pattern = "(.+) ha seleccionado desencantar para: (.+)",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_DISENCHANT_SELF"] = {
    pattern = "Has seleccionado desencantar para: (.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_GREED"] = {
    pattern = "(.+) ha seleccionado codicia para: (.+)",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_GREED_SELF"] = {
    pattern = "Has seleccionado codicia para: (.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_NEED"] = {
    pattern = "(.+) ha seleccionado necesidad para: (.+)",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_NEED_SELF"] = {
    pattern = "Has seleccionado necesidad para: (.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_PASSED"] = {
    pattern = "(.+) ha pasado de: (.+)",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_AUTO"] = {
    pattern = "(.+) ha pasado automáticamente de: (.+) ya que él no puede despojar ese objeto%.",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_AUTO_FEMALE"] = {
    pattern = "(.+) ha pasado automáticamente de: (.+) ya que ella no puede despojar ese objeto%.",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_SELF"] = {
    pattern = "Has pasado de: (.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_SELF_AUTO"] = {
    pattern = "Has pasado automáticamente de: (.+) ya que no puedes despojar ese objeto%.",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_ROLLED_DE"] = {
    pattern = "Tiro por desencantar: (%%d+) para (.+) por (.+)",
    payload = {"roll", "loot", "looter"}
}

L["PATTERN_LOOT_ROLL_ROLLED_GREED"] = {
    pattern = "Tiro por codicia: (%%d+) para (.+) por (.+)",
    payload = {"roll", "loot", "looter"}
}

L["PATTERN_LOOT_ROLL_ROLLED_NEED"] = {
    pattern = "Tiro por necesidad: (%%d+) para (.+) por (.+)",
    payload = {"roll", "loot", "looter"}
}

L["PATTERN_LOOT_ROLL_ROLLED_NEED_ROLE_BONUS"] = {
    pattern = "Tiro por necesidad: (%%d+) para (.+) por (.+) %+ bonificación de función",
    payload = {"roll", "loot", "looter"}
}

L["LOOT_ROLL_ALL_PASSED"] = {
    pattern = "Todos han pasado de: (.+)",
    payload = {'loot'}
}