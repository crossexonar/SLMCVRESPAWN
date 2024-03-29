vector hspawn = <0,0,0>;//Put your spawn here Ignoring Z
vector espawn = <256,256,0>;//Enemy spawn here ignoring Z
float spawndist = 30; //Distance around the spawn areas to consider checking for a vehicle, and safe area to no be unsat in
float speedlimit = 30; //distance at which a vehicle needs to travel to be considered "dead" within 1 second.
float modifier = 5; //HP / Second modifier.
integer online = 1;
integer planeseconds = 15;
integer tankseconds = 30;
integer unixstamp;
//un-used right now
/*string ConvertnumbTime(integer now)
{
    integer seconds = now % 60;
    integer minutes = (now / 60) % 60;
    integer hours = now / 3600;
    return llGetSubString("0" + (string) hours, -2, -1) + ":" + llGetSubString("0" + (string) minutes, -2, -1) + ":" + llGetSubString("0" + (string) seconds, -2, -1);
}*/
list glGroups = ["5d4953e8-e4d8-2f18-62c2-87994dc537b8"];
integer fncCheckGroup(string groupkey)
{
    return (llListFindList(glGroups, [groupkey]) != -1);
}
list unsitlist;
integer lastcheck;
list agents;
list vehicles;
default
{
    state_entry()
    {
        llSetText("Online.", < 1, 0, 0 > , 1);
        llSetObjectDesc("Online.");
        llSetTimerEvent(1);
    }

    timer()
    {
        integer unixclock = llGetUnixTime();
        if (unixclock - lastcheck >= 30)
        {
            agents = llGetAgentList(AGENT_LIST_REGION, []);
        }
        if(unsitlist != [])
        {
            lastcheck = unixclock;
            integer ll = 0;
            integer length = llGetListLength(unsitlist);
            for (; ll < length; ll += 3)
            {
                key id = llList2Key(unsitlist,ll);
                integer ll = llListFindList(unsitlist,(list)id);
                if(ll != -1)
                {
                    //llOwnerSay("Found: "+llKey2Name(id));
                    if(unixclock > llList2Integer(unsitlist,ll+1))
                    {
                        //llOwnerSay("Timer Expired for: "+llKey2Name(id));
                        llRegionSayTo(id,0,"Your Wait timer has expired.");
                        unsitlist = llListReplaceList(unsitlist, [], ll, ll + 2);
                        
                    }
                    else if (llGetAgentInfo(id) & ((AGENT_SITTING | AGENT_ON_OBJECT)))
                    {
                        integer team = llList2Integer(unsitlist,ll+2);
                        vector vehiclepos = llList2Vector(llGetObjectDetails(id,[OBJECT_POS]),0);
                        if (((team == 1 && llVecDist( < vehiclepos.x, vehiclepos.y, 0 > , < hspawn.x, hspawn.y, 0 > ) >= spawndist) || (team == 0 && llVecDist( < vehiclepos.x, vehiclepos.y, 0 > , < espawn.x, espawn.y, 0 > ) >= spawndist)))
                        {
                            llOwnerSay("Unsit: "+llKey2Name(id));
                            llUnSit(id);
                        }
                    }
                }
            }
            //llOwnerSay("Loop Broken.");
        }
        if (vehicles != [] && online)
        {
            integer ll = 0;
            integer length = llGetListLength(vehicles);
            for (; ll < length; ll += 5)
            {
                key vehicle = llList2String(vehicles, ll);
                list vehicleparams = llGetObjectDetails(vehicle, [OBJECT_POS, OBJECT_RUNNING_SCRIPT_COUNT, OBJECT_SIT_COUNT, OBJECT_GROUP, OBJECT_PHANTOM, OBJECT_PHYSICS,OBJECT_OWNER]);
                vector oldvehiclepos = llList2Vector(vehicles, ll + 1);
                vector vehiclepos = llList2Vector(vehicleparams, 0);
                integer sitcount = llList2Integer(vehicleparams, 2);
                integer secondscount = llList2Integer(vehicles, ll + 3);
                integer team = llList2Integer(vehicles, ll + 2);
                key owner = llList2Key(vehicles,ll + 4);
                if (vehiclepos != oldvehiclepos)
                {
                    //llOwnerSay("Old: "+(string)oldvehiclepos);
                    //llOwnerSay("New: "+(string)vehiclepos);
                    vehicles = llListReplaceList(vehicles, [vehiclepos], ll + 1, ll + 1);
                    if (llVecDist(<oldvehiclepos.x,oldvehiclepos.y,0>, <vehiclepos.x,vehiclepos.y,0>) >= speedlimit && ((team == 1 && llVecDist( < vehiclepos.x, vehiclepos.y, 0 > , < hspawn.x, hspawn.y, 0 > ) <= spawndist) || (team == 0 && llVecDist( < vehiclepos.x, vehiclepos.y, 0 > , < espawn.x, espawn.y, 0 > ) <= spawndist)) && vehiclepos != ZERO_VECTOR)// && (llVecDist( < 0, 0, vehiclepos.z > , < 0, 0, 2330 > ) <= 20))
                    {
                        //llOwnerSay(llList2CSV(vehicles));
                        llRegionSayTo(owner,0,"Your respawn period is now: "+(string)secondscount);
                        unsitlist += [owner,(llGetUnixTime()+secondscount),team];
                        vehicles = llListReplaceList(vehicles, [], ll, ll + 4);
                    }
                    else if (((team == 1 && llVecDist( < oldvehiclepos.x, oldvehiclepos.y, 0 > , < 0, 0, 0 > ) > speedlimit) || (team == 0 && llVecDist( < oldvehiclepos.x, oldvehiclepos.y, 0 > , < espawn.x, espawn.y, 0 > ) > spawndist)) && (oldvehiclepos != ZERO_VECTOR && vehiclepos == ZERO_VECTOR || llKey2Name(vehicle) == ""))
                    {
                        //Plane respawn section?
                        llRegionSayTo(owner,0,"Your respawn period is now: "+(string)secondscount);
                        unsitlist += [owner,(llGetUnixTime()+secondscount),team];
                        vehicles = llListReplaceList(vehicles, [], ll, ll + 3);
                        //llOwnerSay("After: " + llList2CSV(vehicles));
                    }
                }
                if (sitcount == 0 && ((oldvehiclepos != ZERO_VECTOR && vehiclepos != ZERO_VECTOR && llKey2Name(vehicle) != "") || ((team == 1 && llVecDist( < oldvehiclepos.x, oldvehiclepos.y, 0 > , < 0, 0, 0 > ) <= spawndist) || (team == 0 && llVecDist( < oldvehiclepos.x, oldvehiclepos.y, 0 > , < 256, 256, 0 > ) <= spawndist))))
                {
                    //llOwnerSay("Sit Before:" + llList2CSV(vehicles));
                    llRegionSayTo(owner,0,"Your respawn period is now: "+(string)secondscount);
                    unsitlist += [owner,(llGetUnixTime()+secondscount),team];
                    vehicles = llListReplaceList(vehicles, [], ll, ll + 4);
                    //llOwnerSay("Sit After: " + llList2CSV(vehicles));
                }
            }
        }
        //llSetText(llList2CSV(namenpos),<1,1,1>,1);
        integer i = llGetListLength(agents);
        for (; i >= 0; --i)
        {
            key checkkey = llList2Key(agents, i);
            list position = llGetObjectDetails(checkkey, [OBJECT_POS, OBJECT_ROT, OBJECT_ROOT]);
            vector pos2vec = llList2Vector(position, 0);
            rotation newlist2rot = llList2Rot(position, 1);
            key root_key = llList2Key(position, 2);
            if (checkkey != NULL_KEY && checkkey != "" && llListFindList(unsitlist,(list)checkkey)==-1)
            {
                
                {
                    vector list2vec = pos2vec;
                    rotation list2rot = newlist2rot;
                    key root_key = llList2Key(llGetObjectDetails(checkkey, [OBJECT_ROOT]), 0); //llList2Key(namenpos, find + 4);
                    integer seated = llGetAgentInfo(checkkey) & AGENT_ON_OBJECT;
                    //if(pos2vec != list2vec)
                    {

                        if (root_key != checkkey && online)
                        {
                            if (llListFindList(vehicles, (list) root_key) == -1)
                            {
                                integer secondscounter = 0;
                                list vehicleparams = llGetObjectDetails(root_key, [OBJECT_POS, OBJECT_RUNNING_SCRIPT_COUNT, OBJECT_SIT_COUNT, OBJECT_GROUP, OBJECT_PHANTOM, OBJECT_PHYSICS, OBJECT_DESC,OBJECT_OWNER]);
                                key ownerkey = llGetOwnerKey(root_key);
                                vector vehiclepos = llList2Vector(vehicleparams, 0);
                                key group = llList2String(vehicleparams, 3);
                                integer vehiclegroup = fncCheckGroup(group);
                                integer scriptcount = llList2Integer(vehicleparams, 1);
                                integer sitcount = llList2Integer(vehicleparams, 2);
                                integer phantom = llList2Integer(vehicleparams, 4);
                                integer physical = llList2Integer(vehicleparams, 5);
                                string desc = llList2String(vehicleparams, 6);
                                key owner = llList2String(vehicleparams, 7);
                                if (physical == 1 && llSubStringIndex(desc, "v.") == -1)
                                {
                                    secondscounter = planeseconds;
                                    llRegionSayTo(checkkey, 0, "This Vehicle Will Take " + (string) secondscounter + " Seconds to respawn on death.");
                                    vehicles += [root_key, vehiclepos, vehiclegroup, secondscounter,owner];
                                }
                                else if (sitcount > 0 && scriptcount > 0 && vehiclepos != ZERO_VECTOR)
                                {
                                    list ray = llCastRay(vehiclepos + < 0, 0, 5 > , vehiclepos + < 0, 0, -5 > , [RC_MAX_HITS, 5, RC_REJECT_TYPES, RC_REJECT_AGENTS, RC_DATA_FLAGS, RC_GET_ROOT_KEY]);
                                    if (llList2Integer(ray, -1) > 0)
                                    {
                                        integer ihitnum;
                                        //llOwnerSay(llList2CSV(ray));                
                                        while (ihitnum <= llList2Integer(ray, -1) * 2)
                                        {
                                            key current_key = llList2Key(ray, ihitnum);
                                            key rezzer = llList2Key(llGetObjectDetails(current_key, [OBJECT_REZZER_KEY]), 0);

                                            if (rezzer == root_key)
                                            {
                                                list params = llGetObjectDetails(current_key, [OBJECT_DESC]);
                                                string desc = llList2String(params, 0);
                                                list lbaparams = llCSV2List(desc);
                                                integer hp = llList2Integer(lbaparams, 1);
                                                integer maxhp = llList2Integer(lbaparams, 2);
                                                if (desc != "" && (llGetSubString(desc, 0, 1) == "v." || llGetSubString(desc, 0, 5) == "LBA.v.") && hp > 0)
                                                {


                                                    /*if (llGetSubString(desc, 0, 9) == "LBA.v.MLBA")
                                                    {
                                                        secondscounter = 60;
                                                        //llOwnerSay("MLBA Detected");
                                                    }
                                                    else
                                                    {*/
                                                        secondscounter = llCeil(maxhp / modifier);
                                                    //}
                                                    if (secondscounter < tankseconds) secondscounter = tankseconds;
                                                    //llOwnerSay("Vehicle Cost: "+(string)secondscounter);
                                                    //llSetText((string)llVecDist(ownerpos,vehiclepos)+ "\n" + (string)secondscost + "\n" + llKey2Name(vehiclerezzer),<1,1,1>,1);
                                                    //llOwnerSay(llKey2Name(current_key));
                                                    llRegionSayTo(checkkey, 0, "This Vehicle Will Take " + (string) secondscounter + " Seconds to respawn on death.");
                                                    vehicles += [root_key, vehiclepos, vehiclegroup, secondscounter, owner];
                                                    jump end;
                                                }
                                            }
                                            else
                                            {
                                                ihitnum += 2;
                                            }
                                        }
                                        @end;
                                    }

                                }
                            }
                        }
                        //llOwnerSay(llList2CSV(namenpos));
                        //llOwnerSay(llList2CSV(vehicles));
                        /*if (llVecDist(list2vec, pos2vec) >= 90 && (( llVecDist( < pos2vec.x, pos2vec.y, 0 > , < 0, 0, 0 > ) <= 90) || (  llVecDist( < pos2vec.x, pos2vec.y, 0 > , < 256, 256, 0 > ) <= 90)) && pos2vec != ZERO_VECTOR && (llVecDist( < 0, 0, pos2vec.z > , < 0, 0, 2330 > ) <= 20))
                        {
                            //Death?
                        }*/
                    }
                }
            }
        }
    }
}
