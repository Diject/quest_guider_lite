local this = {}

this.requirementType = require("scripts.quest_guider_lite.types.requirement")

--- @alias questGuider.requirementType
---| "this.requirementType.ReactionLow"
---| "this.requirementType.ReactionHigh"
---| "this.requirementType.RankRequirement"
---| "this.requirementType.NPCReputation"
---| "this.requirementType.NPCHealthPercent"
---| "this.requirementType.PlayerReputation"
---| "this.requirementType.PlayerLevel"
---| "this.requirementType.PlayerHealthPercent"
---| "this.requirementType.PlayerMagicka"
---| "this.requirementType.PlayerFatigue"
---| "this.requirementType.PlayerStrength"
---| "this.requirementType.PlayerBlockSkill"
---| "this.requirementType.PlayerArmorerSkill"
---| "this.requirementType.PlayerMediumArmorSkill"
---| "this.requirementType.PlayerHeavyArmorSkill"
---| "this.requirementType.PlayerBluntWeaponSkill"
---| "this.requirementType.PlayerLongBladeSkill"
---| "this.requirementType.PlayerAxeSkill"
---| "this.requirementType.PlayerSpearSkill"
---| "this.requirementType.PlayerAthleticsSkill"
---| "this.requirementType.PlayerEnchantSkill"
---| "this.requirementType.PlayerDestructionSkill"
---| "this.requirementType.PlayerAlterationSkill"
---| "this.requirementType.PlayerIllusionSkill"
---| "this.requirementType.PlayerConjurationSkill"
---| "this.requirementType.PlayerMysticismSkill"
---| "this.requirementType.PlayerRestorationSkill"
---| "this.requirementType.PlayerAlchemySkill"
---| "this.requirementType.PlayerUnarmoredSkill"
---| "this.requirementType.PlayerSecuritySkill"
---| "this.requirementType.PlayerSneakSkill"
---| "this.requirementType.PlayerAcrobaticsSkill"
---| "this.requirementType.PlayerLightArmorSkill"
---| "this.requirementType.PlayerShortBladeSkill"
---| "this.requirementType.PlayerMarksmanSkill"
---| "this.requirementType.PlayerMerchantileSkill"
---| "this.requirementType.PlayerSpeechcraftSkill"
---| "this.requirementType.PlayerHandToHandSkill"
---| "this.requirementType.PlayerGender"
---| "this.requirementType.PlayerExpelledFromNPCFaction"
---| "this.requirementType.PlayerCommonDisease"
---| "this.requirementType.PlayerBlightDisease"
---| "this.requirementType.PlayerClothingModifier"
---| "this.requirementType.PlayerCrimeLevel"
---| "this.requirementType.NPCSameGenderAsPlayer"
---| "this.requirementType.NPCSameRaceAsPlayer"
---| "this.requirementType.NPCSameFactionAsPlayer"
---| "this.requirementType.PlayerRankMinusNPCRank"
---| "this.requirementType.PlayerIsDetected"
---| "this.requirementType.NPCIsAlarmed"
---| "this.requirementType.PreviousDialogChoice"
---| "this.requirementType.PlayerIntelligence"
---| "this.requirementType.PlayerWillpower"
---| "this.requirementType.PlayerAgility"
---| "this.requirementType.PlayerSpeed"
---| "this.requirementType.PlayerEndurance"
---| "this.requirementType.PlayerPersonality"
---| "this.requirementType.PlayerLuck"
---| "this.requirementType.PlayerCorprus"
---| "this.requirementType.Weather"
---| "this.requirementType.PlayerIsVampire"
---| "this.requirementType.NPCLevel"
---| "this.requirementType.NPCAttacked"
---| "this.requirementType.NPCTalkedToPlayer"
---| "this.requirementType.PlayerHealth"
---| "this.requirementType.NPCIsTargetingCreature"
---| "this.requirementType.FriendlyHits"
---| "this.requirementType.NPCFight"
---| "this.requirementType.NPCHello"
---| "this.requirementType.NPCAlarm"
---| "this.requirementType.NPCFlee"
---| "this.requirementType.NPCShouldAttackPlayer"
---| "this.requirementType.NPCIsWerewolf"
---| "this.requirementType.PlayerWerewolfKills"
---| "this.requirementType.ValueFLTV"
---| "this.requirementType.ValueINTVLong"
---| "this.requirementType.ValueINTVShort"
---| "this.requirementType.Journal"
---| "this.requirementType.Item"
---| "this.requirementType.Dead"
---| "this.requirementType.NotActorID"
---| "this.requirementType.NotActorFaction"
---| "this.requirementType.NotActorClass"
---| "this.requirementType.NotActorRace"
---| "this.requirementType.NotActorCell"
---| "this.requirementType.Custom"
---| "this.requirementType.CustomValue"
---| "this.requirementType.CustomDisposition"
---| "this.requirementType.CustomSkill"
---| "this.requirementType.CustomAttribute"
---| "this.requirementType.CustomLocal"
---| "this.requirementType.CustomGlobal"
---| "this.requirementType.CustomNotLocal"
---| "this.requirementType.CustomPCRank"
---| "this.requirementType.CustomPCFaction"
---| "this.requirementType.CustomRace"
---| "this.requirementType.CustomActor"
---| "this.requirementType.CustomActorCell"
---| "this.requirementType.CustomActorRace"
---| "this.requirementType.CustomActorClass"
---| "this.requirementType.CustomActorFaction"
---| "this.requirementType.CustomActorGender"
---| "this.requirementType.CustomActorRank"
---| "this.requirementType.CustomScript"
---| "this.requirementType.CustomGameHour"
---| "this.requirementType.CustomAIPackageDone"
---| "this.requirementType.CustomAngle"
---| "this.requirementType.CustomArmorType"
---| "this.requirementType.CustomBlightDisease"
---| "this.requirementType.CustomButtonPressed"
---| "this.requirementType.CustomCastPenalty"
---| "this.requirementType.CustomCollidingActor"
---| "this.requirementType.CustomCollidingPC"
---| "this.requirementType.CustomCommonDisease"
---| "this.requirementType.CustomCurrentAIPackage"
---| "this.requirementType.CustomDisabled"
---| "this.requirementType.CustomDistance"
---| "this.requirementType.CustomEffect"
---| "this.requirementType.CustomForceJump"
---| "this.requirementType.CustomForceMoveJump"
---| "this.requirementType.CustomForceRun"
---| "this.requirementType.CustomForceSneak"
---| "this.requirementType.CustomInterior"
---| "this.requirementType.CustomLineOfSight"
---| "this.requirementType.CustomLocked"
---| "this.requirementType.CustomMasserPhase"
---| "this.requirementType.CustomPCCell"
---| "this.requirementType.CustomPCFacRep"
---| "this.requirementType.CustomPCInJail"
---| "this.requirementType.CustomPCJumping"
---| "this.requirementType.CustomPCRunning"
---| "this.requirementType.CustomPCSleep"
---| "this.requirementType.CustomPCSneaking"
---| "this.requirementType.CustomPCTraveling"
---| "this.requirementType.CustomPlayerControlsDisabled"
---| "this.requirementType.CustomPlayerFightingDisabled"
---| "this.requirementType.CustomPlayerJumpingDisabled"
---| "this.requirementType.CustomPlayerLookingDisabled"
---| "this.requirementType.CustomPlayerMagicDisabled"
---| "this.requirementType.CustomPos"
---| "this.requirementType.CustomScale"
---| "this.requirementType.CustomSecundaPhase"
---| "this.requirementType.CustomSoundPlaying"
---| "this.requirementType.CustomSpell"
---| "this.requirementType.CustomSpellReadied"
---| "this.requirementType.CustomSquare"
---| "this.requirementType.CustomStandingActor"
---| "this.requirementType.CustomStandingPC"
---| "this.requirementType.CustomTarget"
---| "this.requirementType.CustomVanityModeDisabled"
---| "this.requirementType.CustomWaterLevel"
---| "this.requirementType.CustomWeaponDrawn"
---| "this.requirementType.CustomWeaponType"
---| "this.requirementType.CustomWindSpeed"
---| "this.requirementType.CustomHasItemEquipped"
---| "this.requirementType.CustomHasSoulgem"
---| "this.requirementType.CustomCellChanged"
---| "this.requirementType.CustomHitOnMe"
---| "this.requirementType.CustomOnActivate"
---| "this.requirementType.CustomOnDeath"
---| "this.requirementType.CustomOnKnockout"
---| "this.requirementType.CustomOnMurder"
---| "this.requirementType.CustomOnPCAdd"
---| "this.requirementType.CustomOnPCDrop"
---| "this.requirementType.CustomOnPCEquip"
---| "this.requirementType.CustomOnPCHitMe"
---| "this.requirementType.CustomOnPCRepair"
---| "this.requirementType.CustomOnPCSoulGemUse"
---| "this.requirementType.CustomOnRepair"
---| "this.requirementType.CustomUsedOnMe"
---| "this.requirementType.CustomScriptRunning"
---| "this.requirementType.CustomSayDone"
---| "this.requirementType.CustomHealth"
---| "this.requirementType.CustomMenuMode"
---| "this.requirementType.CustomPCKnownWerewolf"
---| "this.requirementType.CustomPCWerewolf"
---| "this.requirementType.CustomDay"
---| "this.requirementType.CustomMonth"
---| "this.requirementType.CustomYear"
---| "this.requirementType.CustomPCRace"
---| "this.requirementType.CustomVampClan"
---| "this.requirementType.CustomRandom"

this.operator = require("scripts.quest_guider_lite.types.operator")

return this