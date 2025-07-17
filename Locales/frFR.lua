

local L = LibStub("AceLocale-3.0"):NewLocale("GroupLootHelper", "frFR")
if not L then return end

L["PATTERN_LOOT_ITEM"] = {
    pattern = "(.+) reçoit le butin : (.+)%.",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ITEM_MULTIPLE"] = {
    pattern = "(.+) reçoit le butin : (.+)x(%%d+)%.",
    payload = {"looter", "loot", "amount"}
}

L["PATTERN_LOOT_ITEM_PUSHED"] = {
    pattern = "(.+) reçoit l’objet : (.+)%.",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ITEM_PUSHED_MULTIPLE"] = {
    pattern = "(.+) reçoit l’objet : (.+)x(%%d+)%.",
    payload = {"looter", "loot", "amount"}
}

L["PATTERN_LOOT_ITEM_PUSHED_SELF"] = {
    pattern = "Vous recevez l'objet : (.+)%.",
    payload = {"loot"}
}

L["PATTERN_LOOT_ITEM_PUSHED_SELF_MULTIPLE"] = {
    pattern = "Vous recevez l'objet : (.+)x(%%d+)%.",
    payload = {"loot", "amount"}
}

L["PATTERN_LOOT_ITEM_SELF"] = {
    pattern = "Vous recevez le butin : (.+)%.",
    payload = {"loot"}
}

L["PATTERN_LOOT_ITEM_SELF_MULTIPLE"] = {
    pattern = "Vous recevez le butin : (.+)x(%%d+)%.",
    payload = {"loot", "amount"}
}

L["PATTERN_LOOT_ROLL_DISENCHANT"] = {
    pattern = "(.+) a choisi Désenchantement pour : (.+)",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_DISENCHANT_SELF"] = {
    pattern = "Vous avez choisi Désenchantement pour : (.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_GREED"] = {
    pattern = "(.+) a choisi Cupidité pour : (.+)",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_GREED_SELF"] = {
    pattern = "Vous avez choisi Cupidité pour : (.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_NEED"] = {
    pattern = "(.+) a choisi Besoin pour : (.+)",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_NEED_SELF"] = {
    pattern = "Vous avez choisi Besoin pour : (.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_PASSED"] = {
    pattern = "(.+) a passé pour : (.+)",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_AUTO"] = {
    pattern = "(.+) a passé automatiquement pour : (.+), car il ne peut pas récupérer cet objet%.",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_AUTO_FEMALE"] = {
    pattern = "(.+) a passé automatiquement pour : (.+), car elle ne peut pas récupérer cet objet%.",
    payload = {"looter", "loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_SELF"] = {
    pattern = "Vous passez sur : (.+)",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_PASSED_SELF_AUTO"] = {
    pattern = "Vous avez passé automatiquement pour : (.+), car vous ne pouvez pas récupérer cet objet%.",
    payload = {"loot"}
}

L["PATTERN_LOOT_ROLL_ROLLED_DE"] = {
    pattern = "Jet de désenchantement %- (%%d+) pour (.+) par (.+)",
    payload = {"roll", "loot", "looter"}
}

L["PATTERN_LOOT_ROLL_ROLLED_GREED"] = {
    pattern = "Jet de Cupidité %- (%%d+) pour (.+) par (.+)",
    payload = {"roll", "loot", "looter"}
}

L["PATTERN_LOOT_ROLL_ROLLED_NEED"] = {
    pattern = "Jet de Besoin %- (%%d+) pour (.+) par (.+)",
    payload = {"roll", "loot", "looter"}
}

L["PATTERN_LOOT_ROLL_ROLLED_NEED_ROLE_BONUS"] = {
    pattern = "Jet de Besoin %- (%%d+) pour (.+) par (.+) %+ bonus de rôle",
    payload = {"roll", "loot", "looter"}
}

L["LOOT_ROLL_ALL_PASSED"] = {
    pattern = "Tout le monde a passé : (.+)",
    payload = {'loot'}
}