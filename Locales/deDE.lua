local L = LibStub("AceLocale-3.0"):NewLocale("GroupLootHelper", "deDE")
if not L then
    return
end

L["PATTERN_LOOT_ITEM"] = {
    pattern = "(.+) bekommt Beute: (.+).",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ITEM_MULTIPLE"] = {
    pattern = "(.+) erhält Beute: (.+)x(%%d+).",
    payload = {"looter", "loot", "amount"}
}

L["PATTERN_LOOT_ITEM_PUSHED"] = {
    pattern = "(.+) erhält den Gegenstand: (.+).",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ITEM_PUSHED_MULTIPLE"] = {
    pattern = "(.+) erhält den Gegenstand: (.+)x(%%d+).",
    payload = {"looter", "loot", "amount"}
}

L["PATTERN_LOOT_ITEM_PUSHED_SELF"] = {
    pattern = "Ihr bekommt einen Gegenstand: (.+).",
    payload = {"loot"}
}

L["PATTERN_LOOT_ITEM_PUSHED_SELF_MULTIPLE"] = {
    pattern = "Ihr erhaltet den Gegenstand: (.+)x(%%d+).",
    payload = {"loot", "amount"}
}

L["PATTERN_LOOT_ITEM_SELF"] = {
    pattern = "Ihr erhaltet Beute: (.+).",
    payload = {"loot"}
}

L["PATTERN_LOOT_ITEM_SELF_MULTIPLE"] = {
    pattern = "Ihr erhaltet Beute: (.+)x(%%d+).",
    payload = {"loot", "amount"}
}

L["PATTERN_LOOT_ROLL_DISENCHANT"] = {
    pattern = "(.+) hat für '(.+)' Entzauberung gewählt.",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_DISENCHANT_SELF"] = {
    pattern = "Ihr habt für (.+) Entzauberung gewählt.",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_GREED"] = {
    pattern = "(.+) hat für (.+) 'Gier' ausgewählt",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_GREED_SELF"] = {
    pattern = "Ihr habt für (.+) Gier ausgewählt",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_NEED"] = {
    pattern = "(.+) hat für (.+) 'Bedarf' ausgewählt",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_NEED_SELF"] = {
    pattern = "Ihr habt für (.+) Bedarf ausgewählt",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_PASSED"] = {
    pattern = "(.+) passt auf: (.+)",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_AUTO"] = {
    pattern = "(.+) passt automatisch auf (.+), weil er den Gegenstand nicht benutzen kann.",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_AUTO_FEMALE"] = {
    pattern = "(.+) passt automatisch auf (.+), weil sie den Gegenstand nicht benutzen kann.",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_SELF"] = {
    pattern = "Ihr habt gepasst auf: (.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_SELF_AUTO"] = {
    pattern = "Ihr habt automatisch auf (.+) gepasst, da Ihr den Gegenstand nicht plündern könnt.",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_ROLLED_DE"] = {
    pattern = "Entzauberungswurf: (%%d+) für (.+) von (.+)",
    payload = {"roll", "loot", "looter"}
}

L["PATTERN_LOOT_ROLL_ROLLED_GREED"] = {
    pattern = "Wurf für Gier: (%%d+) für (.+) von (.+)",
    payload = {"roll", "loot", "looter"}
}

L["PATTERN_LOOT_ROLL_ROLLED_NEED"] = {
    pattern = "Wurf für Bedarf: (%%d+) für (.+) von (.+)",
    payload = {"roll", "loot", "looter"}
}

L["PATTERN_LOOT_ROLL_ROLLED_NEED_ROLE_BONUS"] = {
    pattern = "Wurf für Bedarf: (%%d+) für (.+) von (.+) %+ Rollenbonus",
    payload = {"roll", "loot", "looter"}
}

L["LOOT_ROLL_ALL_PASSED"] = {
    pattern = "Alle haben gepasst auf: (.+)",
    payload = {'loot'}
}
