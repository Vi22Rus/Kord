-- Stage 2.8 isolated deterministic mocks. Run: texlua tests/stage_02_08_rotation_engine.lua
local KR={}
KR.characterState={classToken="WARRIOR",index=1}
KR.db={}
local enabled=true
local mode="single"
local disabled={}
local categories={damage=true,cooldowns=true,defensive=true}
local catalogue={status="ready",entries={
    {id=101,known=true,name="Alpha",texture=1234},
    {id=102,known=true,name="Beta",texture=5678},
    {id=103,known=true,name="Gamma",texture=9012},
}}
KR.SpellCatalogue={Read=function() return catalogue end}
local requirementValue=false
local requirementKnown=true
KR.GameAPI={IsSafeValue=function(_,v) return v~="SECRET" end}
local snapshotReads=0
local snapshotInvalid=false
KR.GameState={GetSnapshot=function()
 snapshotReads=snapshotReads+1
 if snapshotInvalid then return nil end
 return {player={exists={status="READY",value=true}},
    target={exists={status="UNKNOWN"}},context={inGroup={status=requirementKnown and "READY" or "UNKNOWN",value=requirementValue}}}
end}
KR.RotationSettings={
 GetProfileID=function() return KR.characterState.classToken.."_TREE_"..KR.characterState.index end,
 GetProfile=function()
  return {enabled=enabled,targetMode=mode,categories=categories,spells=disabled},"WARRIOR_TREE_1"
 end
}
local results={[101]="BLOCKED",[102]="READY",[103]="READY"}
local reasons={[101]="cooldown"}
local called={}
local wrongEligibilityID=false
KR.AbilityEligibility={Evaluate=function(_,id,opts)
 called[#called+1]={id=id,opts=opts}
 return {status=results[id] or "UNKNOWN",reason=reasons[id] or "unavailable",
  spellID=wrongEligibilityID and 999 or id}
end}
local bindingReady=true
local bindingWrongID=false
local bindingBlank=false
KR.BindingResolver={Resolve=function(_,id)
 if bindingReady then return {status="READY",
    spellID=bindingWrongID and 999 or id,
    bindingLabel=bindingBlank and "" or "S+1",
    bindingSource="blizzard_command"} end
 return {status="UNKNOWN"}
end}
assert(loadfile("KordRotation/Core/RotationProfiles.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Core/RotationEngine.lua"))("KordRotation",KR)
local n=0
local function eq(actual,want,msg)
 n=n+1
 assert(actual==want,(msg or "mismatch")..": expected "..tostring(want)..", received "..tostring(actual))
end
local P=KR.RotationProfiles
local E=KR.RotationEngine
local rule1={spellID=101,category="damage",target="enemy",cast="idle",chargesRequired=false}
local rule2={spellID=102,category="damage",target="enemy",cast="idle",chargesRequired=false}
local rule3={spellID=103,category="cooldowns",target="self",cast="allow",chargesRequired=true,
 requires={{field="context.inGroup",equals=false}}}
eq(E:Evaluate().reason,"profile_not_registered","empty registry")
eq(P:Register("WARRIOR",1,{verified=false,single={rule1},aoe={rule3}}),false,"reject unverified")
eq(P:Register("WARRIOR",1,{verified=true,single={{spellID=101,category="damage"}},aoe={rule3}}),false,"reject missing policy")
eq(P:Register("WARRIOR",1,{verified=true,single={{spellID=104,category="damage",target="self",cast="allow",chargesRequired=false,requires={{field="target.unapproved",equals=true}}}},aoe={}}),false,"reject unapproved GameData key")
eq(P:Register("WARRIOR",1,{verified=true,single={rule1,rule2,rule3},aoe={rule3}}),true,"register mock profile")
eq(P:Has("WARRIOR_TREE_1"),true,"registered")
eq(P:Register("WARRIOR",1,{verified=true,single={rule1},aoe={}}),false,"duplicate rejected")
local copy=P:Get("WARRIOR_TREE_1")
copy.single[1].spellID=999
eq(P:Get("WARRIOR_TREE_1").single[1].spellID,101,"immutable registry copy")
enabled=false
eq(E:Evaluate().reason,"rotation_disabled","opt in only")
enabled=true
mode="auto"
eq(E:Evaluate().reason,"auto_target_count_unverified","no guessed auto")
mode="single"
local state=E:Evaluate()
eq(state.status,"READY","first valid")
eq(state.queue[1].spellID,102,"skip blocked first")
eq(state.queue[1].keybind,"S+1","verified binding")
eq(state.queue[1].texture,5678,"verified texture")
eq(#state.queue,1,"no fabricated predictive queue")
eq(#called>=2,true,"eligibility checks occurred")
eq(called[1].opts.target,"enemy","target policy passed")
eq(called[1].opts.cast,"idle","casting policy passed")
eq(called[1].opts.chargesRequired,false,"charges policy passed")
local previousReads=snapshotReads
called={}
E:Evaluate()
eq(snapshotReads,previousReads+1,"one snapshot read per evaluation")
eq(called[1].opts.stateSnapshot,called[2].opts.stateSnapshot,"shared per-pass snapshot")
eq(type(called[1].opts.stateSnapshot),"table","snapshot passed")
snapshotInvalid=true
eq(E:Evaluate().reason,"game_state_unavailable","missing snapshot fails closed")
snapshotInvalid=false
results[101]="ILLEGAL"
eq(E:Evaluate().reason,"eligibility_status_invalid","invalid outcome cannot fall through")
results[101]="READY"
wrongEligibilityID=true
eq(E:Evaluate().reason,"eligibility_spell_mismatch","wrong spell cannot be recommended")
wrongEligibilityID=false
results[101]="UNKNOWN"
eq(E:Evaluate().status,"UNKNOWN","high priority unknown")
eq(#E:Evaluate().queue,0,"no lower priority leak")
results[101]="BLOCKED"
disabled[102]={enabled=false}
eq(E:Evaluate().queue[1].spellID,103,"disabled spell skipped")
disabled[102]=nil
categories.damage=false
eq(E:Evaluate().queue[1].spellID,103,"disabled category skipped")
categories.damage=true
mode="aoe"
eq(E:Evaluate().queue[1].spellID,103,"aoe rules selected")
requirementKnown=false
eq(E:Evaluate().status,"UNKNOWN","unknown requirement stays UNKNOWN")
requirementKnown=true
requirementValue=true
eq(E:Evaluate().status,"BLOCKED","proven mismatch blocks rule")
requirementValue=false
mode="single"
bindingReady=false
eq(E:Evaluate().queue[1].keybind,nil,"unknown binding blank")
bindingReady=true
bindingWrongID=true
eq(E:Evaluate().queue[1].keybind,nil,"foreign binding ID must be blank")
bindingWrongID=false
bindingBlank=true
eq(E:Evaluate().queue[1].keybind,nil,"empty verified label must be blank")
bindingBlank=false
catalogue.entries[2].texture=nil
eq(E:Evaluate().status,"UNKNOWN","missing verified texture blocks lower rule")
catalogue.entries[2].texture=5678
catalogue.entries[2].id="SECRET"
eq(E:Evaluate().reason,"spell_visual_data_unverified","protected catalogue ID denied")
catalogue.entries[2].id=102
catalogue.entries[2].texture="SECRET"
eq(E:Evaluate().reason,"spell_visual_data_unverified","protected catalogue texture denied")
catalogue.entries[2].texture=5678
catalogue.entries[2].name="SECRET"
eq(E:Evaluate().reason,"spell_visual_data_unverified","protected catalogue name denied")
catalogue.entries[2].name="Beta"
KR.characterState.index=2
eq(E:Evaluate().reason,"profile_not_registered","no spec fallback")
KR.characterState.index=1
KR.characterState.classToken=nil
eq(E:Evaluate().reason,"specialization_unknown","identity unknown")
KR.characterState.classToken="WARRIOR"
results[101]="BLOCKED"
results[102]="BLOCKED"
results[103]="BLOCKED"
eq(E:Evaluate().status,"BLOCKED","all blocked")
eq(#E:Evaluate().queue,0,"no placeholders")
print("PASS stage 2.8 rotation mock: "..n.." assertions")
