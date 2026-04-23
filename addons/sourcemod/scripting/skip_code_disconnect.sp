#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo = 
{
    name = "CS:GO Skip Code Disconnect",
    author = "QAQmolingQAQ",
    description = "Skip disconnect for auth failure codes >= 9 (including FRP Code 10)",
    version = "1.0",
    url = "https://github.com/QAQmolingQAQ/csgo-skip-code-disconnect"
};

enum struct mem_patch
{
    Address addr;
    int len;
    char patch[256];
    char orig[256];

    bool Init(GameData conf, const char[] key, Address baseAddr)
    {
        int offset, pos, curPos;
        char byte[16], bytes[512];
        
        if (this.len)
            return false;
        
        if (!conf.GetKeyValue(key, bytes, sizeof(bytes)))
            return false;
        
        offset = conf.GetOffset(key);
        if (offset == -1)
            offset = 0;
        
        this.addr = baseAddr + view_as<Address>(offset);
        
        StrCat(bytes, sizeof(bytes), " ");
        
        while ((pos = SplitString(bytes[curPos], " ", byte, sizeof(byte))) != -1)
        {
            curPos += pos;
            TrimString(byte);
            
            if (byte[0])
            {
                this.patch[this.len] = StringToInt(byte, 16);
                this.orig[this.len] = LoadFromAddress(this.addr + view_as<Address>(this.len), NumberType_Int8);
                this.len++;
            }
        }
        
        return true;
    }
    
    void Apply()
    {
        for (int i = 0; i < this.len; i++)
            StoreToAddress(this.addr + view_as<Address>(i), this.patch[i], NumberType_Int8);
    }
    
    void Restore()
    {
        for (int i = 0; i < this.len; i++)
            StoreToAddress(this.addr + view_as<Address>(i), this.orig[i], NumberType_Int8);
    }
}

mem_patch g_SkipCodeDisconnectPatch;

public void OnPluginStart()
{
    GameData conf = new GameData("skip_code_disconnect.games");
    if (!conf) 
        SetFailState("Failed to load skip_code_disconnect gamedata");
    
    Address authFailHandlerAddr = conf.GetAddress("AuthFailureHandler");
    if (!authFailHandlerAddr)
        SetFailState("Failed to get AuthFailureHandler address from gamedata");
    
    g_SkipCodeDisconnectPatch.Init(conf, "SkipCodeDisconnect_Patch", authFailHandlerAddr);
    g_SkipCodeDisconnectPatch.Apply();
    
    LogMessage("[SkipCodeDisconnect] Patch applied at 0x%X (offset +0x19B)", authFailHandlerAddr);
    delete conf;
}

public void OnPluginEnd()
{
    g_SkipCodeDisconnectPatch.Restore();
    LogMessage("[SkipCodeDisconnect] Patch restored");
}