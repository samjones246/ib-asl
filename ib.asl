state("RPG_RT", "steam")
{ 
    int levelid : 0xD2068, 0x4;
    int posX : 0xD2014, 0x14;
    int posY : 0xD2014, 0x18;
    int switchesPtr : 0xD2008, 0x20;
    int varsPtr : 0xD2008, 0x28;
    bool start : 0xD1E08, 0x8, 0x14, 0x70;
    int frames : 0xD2008, 0x8;
    int eventID : 0xD202C, 0x4, 0x8, 0x4, 0x0, 0x1C;
}

startup
{
    vars.Log = (Action<object>)((output) => print("[Ib ASL] " + output));
}

init
{
    vars.NUM_SWITCHES = 910;
    vars.NUM_VARIABLES = 120;
    vars.startFrames = 0;
}

update
{
    current.switches = null;
    current.variables = null;

    if (current.switchesPtr != 0){
        current.switches = game.ReadBytes(new IntPtr(current.switchesPtr), (int)vars.NUM_SWITCHES);
        current.variables = new int[vars.NUM_VARIABLES];
        byte[] varsBytes = game.ReadBytes(new IntPtr(current.varsPtr), (int)vars.NUM_VARIABLES * 4);
        if (varsBytes != null){
            for (int i = 0; i < vars.NUM_VARIABLES; i++)
            {
                current.variables[i] = BitConverter.ToInt32(varsBytes, i * 4);
            }
        }
    }

    if (current.levelid != old.levelid){
        vars.Log("Level changed: " + old.levelid + " -> " + current.levelid);
    }

    if(current.start != old.start){
        vars.Log("Start flag: " + current.start);
    }

    if (current.eventID != old.eventID){
        vars.Log("Event ID: " + current.eventID);
    }
}

start
{
    // Start when start flag becomes true, but only on main menu (switchesPtr is 0 on menu)
    if (current.start && !old.start && current.switchesPtr == 0){
        vars.Log("Starting timer");
        vars.startFrames = current.frames;
        return true;
    }
}

split
{
}

reset
{
    if (current.frames < old.frames && old.frames != vars.startFrames){
        vars.Log("Resetting");
        return true;
    }

}
