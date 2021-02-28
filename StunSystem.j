library StunSystem

//***************************************************
//   W3UMF 공룡비둘기                                
//                                                  
//   스턴 도우미 2.0 // Made by dinodove  
//
//    Stun Control + Casting Bar
//***************************************************

//아래 구문은 맵 저장 후 삭제 바랍니다. (오브젝트 생성되었는지 확인 후 삭제요망)
/*//! external ObjectMerger w3a AHtb stun anam "StunDummy" ansf "(Dino Dove UI)" aart "" acat "" arac 0 amsp 10000 aani "" alev 1 aher 0 Htb1 1 0 adur 1 0 ahdu 1 0 amcs 1 0 aran 1 99999 amat "" atar 1 "enemies" acdn 1 0
//! external ObjectMerger w3u uzig stdu unam "StunDummy" unsf "(Dino Dove UI)" uupt "" upgr "" udef 0 ubsi "" usnd "" usin 0 usid 0 ufma 0 uabi "Avul,Aloc" usca 0.10 uprw 0 uubs "" uble 0 ucbs 0 urun 0 uwal 0 umdl ".mdl" ucol 0 upap "" upar "" upat "" uabr 0 utyp "Mechanical" ubsl "" uhpm 3*/

globals
    private constant player SYSYTEM_DUMMY_OWNER = Player(PLAYER_NEUTRAL_AGGRESSIVE)
    private constant integer SYSTEM_DUMMY_CODE  = 'stdu'
    private constant integer SYSTEM_SKILL_CODE  = 'stun'
    private constant integer SYSTEM_BUFF_CODE   = 'BPSE'
    private constant real SYSTEM_DUMMY_X        = 0
    private constant real SYSTEM_DUMMY_Y        = 0
    private constant string SYSTEM_COMMAND      = "thunderbolt"
    private integer count2 = 0
endglobals

    struct TimeBar

        static constant hashtable HASH = InitHashtable()
        private real CurTime = 0
        private real MaxTime = 0
        unit Caster
        trigger Destroy
        tick BarTimer
        Lightnings CurTimebar = 0
        Lightnings MaxTimebar = 0

        //===! Timebar add Garbage Collector
        
        static method FlushData takes nothing returns boolean
            local thistype this = LoadInteger(HASH, GetHandleId(GetTriggerUnit()), 1)
            call destroy()
            return false
        endmethod

        method destroy takes nothing returns nothing
            call UnitRemoveBuffBJ(SYSTEM_BUFF_CODE, Caster)
            call DestroyTrigger(Destroy)
            call RemoveSavedInteger(HASH, GetHandleId(Caster), 1)
            if CurTimebar != 0 then
                call CurTimebar.destroy()
            endif
            if MaxTimebar != 0 then
                call MaxTimebar.destroy()
            endif
            if BarTimer != 0 then
                call BarTimer.pause()
                call BarTimer.destroy()
            endif
            set Caster = null
            set Destroy = null
        endmethod

        method operator addTime= takes real t returns nothing
            set .CurTime = .CurTime + t
            set .MaxTime = .CurTime
        endmethod

        method operator Time= takes real t returns nothing
            set .CurTime = t
            set .MaxTime = t
            set .CurTimebar.Length = 150
            set .MaxTimebar.Length = 150
            set .CurTimebar.xCor = -35
            set .MaxTimebar.zCor = 80
        endmethod

        //! textmacro Cor takes args
        method operator SetCor$args$= takes real result returns nothing
            set CurTimebar.$args$Cor = result
            set MaxTimebar.$args$Cor = result
        endmethod
        //! endtextmacro
        //! runtextmacro Cor("x")
        //! runtextmacro Cor("y")
        //! runtextmacro Cor("z")

            //==! add New Timebar

        static method addTimebar takes unit u returns thistype
            local thistype this = thistype.allocate()
            set Caster = u
            set Destroy = CreateTrigger()
            call TriggerRegisterUnitStateEvent(Destroy, u, UNIT_STATE_LIFE, LESS_THAN_OR_EQUAL, 0.304)
            call TriggerAddCondition(Destroy, Condition(function thistype.FlushData))
            call SaveInteger(HASH, GetHandleId(u), 1, this)
            return this
        endmethod

            //==! integrate Timebar

        static method RenewTimebar takes nothing returns nothing
            local tick t = tick.getExpired()
            local thistype this = t.data
            set CurTime = CurTime - 0.025
            if CurTime <= 0 then
                call destroy()
                return
            endif
            call SetTimeBar()
        endmethod

        method SetTimeBar takes nothing returns nothing
            set CurTimebar.Visible = IsUnitVisible(Caster, GetLocalPlayer())
            set MaxTimebar.VisibleSad = IsUnitVisible(Caster, GetLocalPlayer())
            call CurTimebar.moveByLengthP(CurTime/MaxTime)
            call CurTimebar.setPosByUnit(Caster)
            call MaxTimebar.setPosByUnit(Caster)
            call MaxTimebar.moveByLength()
        endmethod

        method InitTimeBar takes nothing returns nothing
            set CurTimebar = CurTimebar.createTimeBar()
            set MaxTimebar = MaxTimebar.createTimeBar()
            if .BarTimer == 0 then
                set .BarTimer = tick.create(this)
                call .BarTimer.start(0.025, true, function thistype.RenewTimebar)
            endif
            set SetCorx= -15
            set SetCorz= 150
        endmethod
        
    endstruct
    // call StunManager.addStun(target, time)
    struct StunManager

        static constant hashtable HASH = InitHashtable()
        trigger Destroy
        tick Stuntime
        real RemainTime
        real MaxTime
        real plustime
        unit dummy
        unit target
        TimeBar tb

        method destroy takes nothing returns nothing
            if Stuntime != 0 then
                call Stuntime.pause()
                call Stuntime.destroy()
            endif
            call RemoveSavedInteger(HASH, GetHandleId(target),0)
            call RemoveUnit(dummy)
            call DestroyTrigger(Destroy)
            set Destroy = null
            set dummy = null
            set target = null
            set RemainTime = 0
            set MaxTime = 0
        endmethod

        static method RenewStunManager takes nothing returns nothing
            local tick t = tick.getExpired()
            local thistype this = t.data
            set RemainTime = RemainTime - 0.025
            if RemainTime <= 0 and IsUnitAliveBJ(target) then
                call destroy()
                return
            endif
        endmethod

        static method FlushData takes nothing returns boolean
            local thistype this = LoadInteger(HASH, GetHandleId(GetTriggerUnit()), 1)
            call destroy()
            return false
        endmethod

        static method addStun takes unit whichUnit, real time returns thistype
            local thistype this
            if LoadInteger(HASH, GetHandleId(whichUnit),0) == null then
                set this = thistype.allocate()
                set Destroy = CreateTrigger()
                call TriggerRegisterUnitStateEvent(Destroy, whichUnit, UNIT_STATE_LIFE, LESS_THAN_OR_EQUAL, 0.304)
                call TriggerAddCondition(Destroy, Condition(function thistype.FlushData))
                call SaveInteger(HASH, GetHandleId(whichUnit),0,this)
                set target = whichUnit
                set RemainTime = time
                set MaxTime = time
                call InitStunManager()
            else
                set this = LoadInteger(HASH, GetHandleId(whichUnit), 0)
                set MaxTime = MaxTime + time
                set RemainTime = RemainTime + time
                set plustime = time
                call RenewInitStunManager()
            endif
            return this
        endmethod

        method RenewInitStunManager takes nothing returns nothing
            set tb.addTime = plustime
        endmethod

        method InitStunManager takes nothing returns nothing
            set tb = TimeBar.addTimebar(target)
            set Stuntime = tick.create(this)
            set tb.Time= MaxTime
            call tb.InitTimeBar()
            call Stuntime.start(0.025, true, function thistype.RenewStunManager) 
            set dummy = CreateUnit(SYSYTEM_DUMMY_OWNER, SYSTEM_DUMMY_CODE, SYSTEM_DUMMY_X, SYSTEM_DUMMY_Y, 0)
            call UnitAddAbility(dummy, SYSTEM_SKILL_CODE)
            call IssueTargetOrder(dummy, SYSTEM_COMMAND, target)
            call RemoveUnit(dummy)
            set dummy = null
        endmethod

    endstruct
    
endlibrary
