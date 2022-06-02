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

    // Image properties, used for ending detection
    bool image5              : 0xD2010, 0x8, 0x4, 0x10, 0xC, 0x609;
    int image5Transparency   : 0xD2010, 0x8, 0x4, 0x10, 0xA4;
    bool image40             : 0xD2010, 0x8, 0x4, 0x9C, 0xC, 0x609;
    int blackTransparency    : 0xD2010, 0x8, 0x4, 0xA4, 0xA4; 
}

startup
{
    vars.Log = (Action<object>)((output) => print("[Ib ASL] " + output));
    vars.NUM_SWITCHES = 910;
    vars.NUM_VARIABLES = 120;

    int[][] transitions = new int[][] {
        new int [] {05, 10},
        new int [] {11, 14},
        new int [] {14, 18},
        new int [] {25, 26},
        new int [] {32, 34},
        new int [] {46, 48},
        new int [] {54, 55},
        new int [] {72, 76},
        new int [] {96, 97},
    };
    vars.transitions = transitions;
    string[] transitionNames = new string[] {
        "Gallery",
        "Blue",
        "Green",
        "Yellow",
        "Red",
        "Grey",
        "Violet",
        "Brown",
        "Sketchbook"
    };

    settings.Add("splitArea", true, "Split on finishing area");

    for (int i=0;i<transitions.Length;i++){
        settings.Add("area"+i, true, transitionNames[i], "splitArea");
    }
}

init
{
    vars.startFrames = 0;
    vars.PORFadeCount = 0;
}

update
{
    current.switches = null;
    current.variables = null;

    // Update switch/variable values
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
}

start
{
    // Start when start flag becomes true, but only on main menu (switchesPtr is 0 on menu)
    if (current.start && !old.start && current.switchesPtr == 0){
        vars.Log("Starting timer");
        vars.startFrames = current.frames;
        vars.PORFadeCount = 0;
        return true;
    }
}

split
{
    // -- INTERMEDIARY --
    // Split on finishing each zone
    if (old.levelid != current.levelid){
        for (int i=0;i<vars.transitions.Length;i++){
            if (old.levelid == vars.transitions[i][0] && current.levelid == vars.transitions[i][1]){
                vars.Log("Area transition");
                return true;
            }
        }
    }
    if (current.image5 && current.image5Transparency < 100 && old.image5Transparency == 100){
        // Memories Crannies
        if (current.levelid == 7 && current.eventID == 40 && current.switches[452] == 0){
            vars.Log("Ending: Memory's Crannies");
            return true;
        }
        // Forgotten Portrait
        if (current.levelid == 4 && current.eventID == 25){
            vars.Log("Ending: Forgotten Portrait");
            return true;
        }
        // Ib All Alone
        // - Variants in dark gallery
        if (current.levelid == 104 && current.eventID == 13){
            vars.Log("Ending: Ib All Alone");
            return true;
        }
        // - Variant in final stage
        if (current.levelid == 128 && current.eventID == 1){
            vars.Log("Ending: Ib All Alone");
            return true;
        }
        // Welcome to the World of Guertena
        if(current.levelid == 107){
            vars.Log("Ending: Welcome to the World of Guertena");
            return true;
        }
        // A Painting's Demise
        if(current.levelid == 1 && current.switches[535]){
            vars.Log("Ending: A Painting's Demise");
            return true;
        }
    }

    // Endings which show artwork use image 40
    if(current.image40 && current.blackTransparency > 0 && old.blackTransparency == 0){
        // Together Forever
        if (current.levelid == 1 && current.eventID == 16){
            vars.Log("Ending: Together Forever");
            return true;
        }
        // Promise of Reunion
        if (current.levelid == 56){
            if (vars.PORFadeCount < 2){
                vars.PORFadeCount++;
            }else{
                vars.Log("Ending: Promise of Reunion");
                return true;
            }
        }
    }
}

reset
{
    if (current.frames < old.frames && old.frames != vars.startFrames){
        vars.Log("Resetting");
        return true;
    }

}
