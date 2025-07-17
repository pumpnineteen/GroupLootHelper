

local L = LibStub("AceLocale-3.0"):NewLocale("GroupLootHelper", "itIT")
if not L then return end

L["PATTERN_LOOT_ITEM"] = {
    pattern = "(.+) ha ricevuto: (.+)%.",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ITEM_MULTIPLE"] = {
    pattern = "(.+) ha ricevuto: (.+)x(%%d+)%.",
    payload = {"looter", "loot", "amount"}
}

L["PATTERN_LOOT_ITEM_PUSHED"] = {
    pattern = "(.+) ha ricevuto: (.+)%.",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ITEM_PUSHED_MULTIPLE"] = {
    pattern = "(.+) ha ricevuto: (.+)x(%%d+)%.",
    payload = {"looter", "loot", "amount"}
}

L["PATTERN_LOOT_ITEM_PUSHED_SELF"] = {
    pattern = "Hai ricevuto: (.+)%.",
    payload = {"loot"}
}

L["PATTERN_LOOT_ITEM_PUSHED_SELF_MULTIPLE"] = {
    pattern = "Hai ricevuto: (.+)x(%%d+)%.",
    payload = {"loot", "amount"}
}

L["PATTERN_LOOT_ITEM_SELF"] = {
    pattern = "Hai ricevuto: (.+)%.",
    payload = {"loot"}
}

L["PATTERN_LOOT_ITEM_SELF_MULTIPLE"] = {
    pattern = "Hai ricevuto: (.+)x(%%d+)%.",
    payload = {"loot", "amount"}
}

L["PATTERN_LOOT_ROLL_DISENCHANT"] = {
    pattern = "(.+) ha scelto Disincantamento per: (.+)%.",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_DISENCHANT_SELF"] = {
    pattern = "Hai scelto Disincantamento per: (.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_GREED"] = {
    pattern = "(.+) ha scelto Bramosia per: (.+)%.",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_GREED_SELF"] = {
    pattern = "Hai scelto Bramosia per: (.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_NEED"] = {
    pattern = "(.+) ha scelto Necessità per: (.+)%.",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_NEED_SELF"] = {
    pattern = "Hai scelto Necessità per: (.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_PASSED"] = {
    pattern = "(.+) ha passato: (.+)%.",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_AUTO"] = {
    pattern = "(.+) ha automaticamente passato (.+) poiché non può depredarlo%.",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_AUTO_FEMALE"] = {
    pattern = "(.+) ha automaticamente passato (.+) poiché non può depredarlo%.",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_SELF"] = {
    pattern = "Hai passato: (.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_SELF_AUTO"] = {
    pattern = "Hai automaticamente passato l'oggetto (.+) poiché non puoi depredarlo%.",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_ROLLED_DE"] = {
    pattern = "Tiro per Disincantamento: (%%d+) per (.+) ottenuto da (.+)%.",
    payload = {"roll", "loot", "looter"}
}

L["PATTERN_LOOT_ROLL_ROLLED_GREED"] = {
    pattern = "Tiro per Bramosia: (%%d+) per (.+) ottenuto da (.+)%.",
    payload = {"roll", "loot", "looter"}
}

L["PATTERN_LOOT_ROLL_ROLLED_NEED"] = {
    pattern = "Tiro per Necessità: (%%d+) per (.+) ottenuto da (.+)%.",
    payload = {"roll", "loot", "looter"}
}

L["PATTERN_LOOT_ROLL_ROLLED_NEED_ROLE_BONUS"] = {
    pattern = "Tiro per Necessità: (%%d+) per (.+) ottenuto da (.+) %+ bonus ruolo%.",
    payload = {"roll", "loot", "looter"}
}

L["LOOT_ROLL_ALL_PASSED"] = {
    pattern = "Tutti hanno passato: (.+)%.",
    payload = {'loot'}
}