class MutWaveRandomizer extends Mutator
	config(satoreMonsterPack);
	
var Invasion Invasion;
var config Array < class < Monster > > BunnyMonsterClass, SafeMonsterClass, BossMonsterClass;
var int WaveNum;

struct WaveOption
{
    var int Chance;
    var int MaxMonsters;
    var int MonsterGroup;
};

struct WaveDetail
{
    var int WaveNumber;
    var int DifficultyMode;
    var Array<WaveOption> WaveOptions;
};
var config Array<WaveDetail> WaveConfig;

var config Array<WaveDetail> BonusWaveConfig;
var Array<int> BonusWavePlayed[16];     // int because bool not allowed. So 0 false 1 true.
var int BonusMonsterGroupNext;
var int MaxBonusMonstersNext;

struct DifficultyModeRecord
{
    var int DifficultyMode;
    var string Name;
    var int MinPlayerLevel;
    var int MaxPlayerLevel;
    var int MinNumPlayers;
};
var config Array<DifficultyModeRecord> DifficultyModes;

struct MonsterGroup
{
    var int MonsterGroup;
    var string Name;               // just for us to know what it is
    var string Description;        // used in message if set
};
var config Array<MonsterGroup> MonsterGroups;

struct RandomMonster
{
    var int MonsterGroup;
    var class<Monster> MonsterClass;
};
var config Array<RandomMonster> MonsterGroupMonsters;

var config int FinalWave;
var config bool bAdjustFinalWave;
var bool XPRewarded;

//Special wave 16 variables
var bool SpecialWaveAdded;
var bool SpecialWaveInitialized;
var bool bPlayerReset;

//Boss and Boss wave variables
var class<Monster> BossClass;
var Monster BossPawn;
var config int BossWaveIndex;
var config int BossWaveChance;
var bool BossWaveInitialized, bBossWaveAdded;
var config int BossHealthAddPerPlayer;
var bool BossSpawned;
var config byte BossWaveDuration;
var config int BossSpawnAttempt;
var config bool CheckConfig;
const BOSSWAVEMAXMONSTERS = 0;

//Bunny wave variables
var bool BonusWaveInitialized, BunnyWaveInitialized, BunnyWaveCompleted;
var bool bBunnyWaveAdded;
var config byte BunnyWaveMaxMonsters, BunnyWaveDuration;

#exec  AUDIO IMPORT NAME="BossWarning" FILE="Sounds\BossWarning.WAV" GROUP="Boss"

event PostBeginPlay()
{
    local int i;
    
	Invasion = Invasion(Level.Game);
	if (Invasion != None)
	{
		if (bAdjustFinalWave)
			Invasion.FinalWave = FinalWave;
		default.bBunnyWaveAdded = False;
		BonusWaveInitialized = False;
		BunnyWaveInitialized = False;
		BossWaveInitialized = False;
		BossSpawned = False;
		BunnyWaveCompleted = False;
		SpecialWaveAdded = False;
		SpecialWaveInitialized = False;
		XPRewarded = False;
		bPlayerReset = false;
        for (i=0; i<16; i++)
            BonusWavePlayed[i] = 0;
		if (Rand(100) <= BossWaveChance)
			bBossWaveAdded = True;
		else
			bBossWaveAdded = False;
		SetTimer(1, True);
		WaveNum = -1; 	//Initialize the WaveNum to -1. This is set so that Timer() can check this condition as true for the first wave of this game.
	}

    if (CheckConfig)
        CheckConfiguration();
    
	Super.PostBeginPlay();
}

function CheckConfiguration()
{
    // the satore config is quite complex. let's do some simple checks for consistency
	local int i;
    local int j;
    local int x;
    local int MonsterGroup;
    local bool CheckOK;
    local int sum;
    local int MaxDifficultyMode;
    
    // first check DifficultyMode setup
    MaxDifficultyMode = -1;
 	for(i=0; i< DifficultyModes.Length; i++)
	{
        if (DifficultyModes[i].DifficultyMode > MaxDifficultyMode)
            MaxDifficultyMode =  DifficultyModes[i].DifficultyMode;
    }
    if (MaxDifficultyMode < 0)
        Log("!!!!!!!! WaveRandomizer Config Check Error - no DifficultyModes configured");
    
    // now check each MonsterGroup in MonsterGroupMonsters is in MonsterGroups
 	for(i=0; i<MonsterGroupMonsters.Length; i++)
	{
        MonsterGroup = MonsterGroupMonsters[i].MonsterGroup;
        CheckOK = false;
     	for(x=0; x < MonsterGroups.Length; x++)
    	{
            if (MonsterGroups[x].MonsterGroup == MonsterGroup)
                CheckOK = true;
        }
        if (CheckOK == false)
            Log("!!!!!!!! WaveRandomizer Config Check Error - MonsterGroup" @ MonsterGroup @ "in MonsterGroupMonsters but not in MonsterGroups");
    }

 	for(i=0; i < WaveConfig.Length; i++)
	{
        if (WaveConfig[i].WaveNumber < 1 || WaveConfig[i].WaveNumber > 16)
            Log("!!!!!!!! WaveRandomizer Config Check Error - WaveConfig has WaveNumber" @ WaveConfig[i].WaveNumber @ "which is not in the range 1-16");
        if (WaveConfig[i].WaveOptions.Length == 0)
            Log("!!!!!!!! WaveRandomizer Config Check Error - WaveConfig record has no WaveOptions configured" @ WaveConfig[i].WaveNumber @ "DifficultyMode:" @ WaveConfig[i].DifficultyMode);

        CheckOK = false;
     	for(j=0; j< DifficultyModes.Length; j++)
    	{
            if (DifficultyModes[j].DifficultyMode == WaveConfig[i].DifficultyMode)
                CheckOK = true;
        }
        if (CheckOK == false)
             Log("!!!!!!!! WaveRandomizer Config Check Error - WaveConfig record has DifficultyMode" @ WaveConfig[i].DifficultyMode @ "configured, which is not valid. Wave Number:" @ WaveConfig[i].WaveNumber);

        sum = 0;
        for (j=0; j < WaveConfig[i].WaveOptions.Length; j++)
        {
            if (WaveConfig[i].WaveOptions[j].MaxMonsters <1)
                Log("!!!!!!!! WaveRandomizer Config Check Error - WaveConfig has MaxMonsters" @ WaveConfig[i].WaveOptions[j].MaxMonsters @ WaveConfig[i].WaveNumber @ "DifficultyMode:" @ WaveConfig[i].DifficultyMode);
            sum += WaveConfig[i].WaveOptions[j].Chance;
            CheckOK = false;
            MonsterGroup = WaveConfig[i].WaveOptions[j].MonsterGroup;
         	for(x=0; x < MonsterGroupMonsters.Length; x++)
        	{
                if (MonsterGroupMonsters[x].MonsterGroup == MonsterGroup)
                    CheckOK = true;
            }
            if (CheckOK == false)
                Log("!!!!!!!! WaveRandomizer Config Check Error - MonsterGroup" @ MonsterGroup @ "in WaveConfig WaveOptions but not in MonsterGroupMonsters" @ WaveConfig[i].WaveNumber @ "DifficultyMode:" @ WaveConfig[i].DifficultyMode);
        }
        if (sum != 100)
            Log("!!!!!!!! WaveRandomizer Config Check Error - WaveConfig WaveOptions not summing to 100% - index" @ i @ "WaveNum:" @ WaveConfig[i].WaveNumber @ "DifficultyMode:" @ WaveConfig[i].DifficultyMode);
    }

    // now the bonus wave config
    if ((MaxDifficultyMode + 1) * 16 != WaveConfig.Length)
        Log("!!!!!!!! WaveRandomizer Config Check warning - possible mismatch in number of WaveConfig records - WaveConfig" @ WaveConfig.Length @ "DifficutyModes" @ MaxDifficultyMode + 1);

 	for(i=0; i < BonusWaveConfig.Length; i++)
	{
        if (BonusWaveConfig[i].WaveNumber < 1 || BonusWaveConfig[i].WaveNumber > 16)
            Log("!!!!!!!! WaveRandomizer Config Check Error - BonusWaveConfig has WaveNumber" @ BonusWaveConfig[i].WaveNumber @ "which is not in the range 1-16");
        if (BonusWaveConfig[i].WaveOptions.Length == 0)
            Log("!!!!!!!! WaveRandomizer Config Check Error - BonusWaveConfig record has no WaveOptions configured" @ "WaveNum:" @ BonusWaveConfig[i].WaveNumber @ "DifficultyMode:" @ BonusWaveConfig[i].DifficultyMode);

        CheckOK = false;
     	for(j=0; j< DifficultyModes.Length; j++)
    	{
            if (DifficultyModes[j].DifficultyMode == BonusWaveConfig[i].DifficultyMode)
                CheckOK = true;
        }
        if (CheckOK == false)
             Log("!!!!!!!! WaveRandomizer Config Check Error - BonusWaveConfig record has DifficultyMode" @ BonusWaveConfig[i].DifficultyMode @ "configured, which is not valid. Wave Number:" @ BonusWaveConfig[i].WaveNumber);

        sum = 0;
        for (j=0; j < BonusWaveConfig[i].WaveOptions.Length; j++)
        {
            if (BonusWaveConfig[i].WaveOptions[j].MaxMonsters <1)
                Log("!!!!!!!! WaveRandomizer Config Check Error - BonusWaveConfig has MaxMonsters" @ BonusWaveConfig[i].WaveOptions[j].MaxMonsters @ "WaveNum:" @ BonusWaveConfig[i].WaveNumber @ "DifficultyMode:" @ BonusWaveConfig[i].DifficultyMode);
            sum += BonusWaveConfig[i].WaveOptions[j].Chance;
            CheckOK = false;
            MonsterGroup = BonusWaveConfig[i].WaveOptions[j].MonsterGroup;
         	for(x=0; x < MonsterGroupMonsters.Length; x++)
        	{
                if (MonsterGroupMonsters[x].MonsterGroup == MonsterGroup)
                    CheckOK = true;
            }
            if (CheckOK == false)
                Log("!!!!!!!! WaveRandomizer Config Check Error - MonsterGroup" @ MonsterGroup @ "in BonusWaveConfig WaveOptions but not in MonsterGroupMonsters" @ "WaveNum:" @ BonusWaveConfig[i].WaveNumber @ "DifficultyMode:" @ BonusWaveConfig[i].DifficultyMode);
        }
        if (sum > 100)
            Log("!!!!!!!! WaveRandomizer Config Check Error - WaveConfig WaveOptions summing to more than 100% - index" @ i @ "WaveNum:" @ BonusWaveConfig[i].WaveNumber @ "DifficultyMode:" @ BonusWaveConfig[i].DifficultyMode);
    }

    // check all 16 waves for each difficultymode
    if ((MaxDifficultyMode + 1) * 16 != BonusWaveConfig.Length)
        Log("!!!!!!!! WaveRandomizer Config Check Warning - possible mismatch in number of BonusWaveConfig records - BonusWaveConfig" @ BonusWaveConfig.Length @ "DifficutyModes" @ MaxDifficultyMode + 1);
        
    ListWaveDifficulty();
}

function ListWaveDifficulty()
{
    local int i;
    local int j;
    local int x;
    local int PointsSum;
    local int MonsterCount;
    local int MonsterGroup;
    local float AveragePoints;
    local int WaveDifficulty;
    local int MaxMonsters;
    local int MaxDifficultyMode;
    local int d;
    local int ScoringValue;
    // can't get hold of the ElementalConfigure modifiers here so need to hard code
    local float EarthScoreMultiplier;
    local float IceScoreMultiplier;
    local float FireScoreMultiplier;
    
    EarthScoreMultiplier = 2.35;
    IceScoreMultiplier = 2.00;
    FireScoreMultiplier = 2.00;

    Log("------------   Wave Configuration  -------------");    
    
    MaxDifficultyMode = -1;
 	for(i=0; i< DifficultyModes.Length; i++)
	{
        if (DifficultyModes[i].DifficultyMode > MaxDifficultyMode)
            MaxDifficultyMode =  DifficultyModes[i].DifficultyMode;
    }

    for (d=0; d <= MaxDifficultyMode; d++)
    {
        Log("DificultyMode" @ d);
    	for(i=0; i < WaveConfig.Length; i++)
    	{
            if (WaveConfig[i].DifficultyMode == d)
            {
                for (j=0; j < WaveConfig[i].WaveOptions.Length; j++)
                {
                    if (WaveConfig[i].WaveOptions[j].Chance > 0)
                    {
                        MaxMonsters =  WaveConfig[i].WaveOptions[j].MaxMonsters;
                        MonsterGroup = WaveConfig[i].WaveOptions[j].MonsterGroup;
                        
                        PointsSum = 0;
                        MonsterCount = 0;
                     	for(x=0; x < MonsterGroupMonsters.Length; x++)
                    	{
                            if (MonsterGroupMonsters[x].MonsterGroup == MonsterGroup)
                            {
                                MonsterCount++;
                                ScoringValue = MonsterGroupMonsters[x].MonsterClass.default.ScoringValue;
                                if (Left(MonsterGroupMonsters[x].MonsterClass.Name,5) == "Earth")
                                    ScoringValue *= EarthScoreMultiplier;
                                if (Left(MonsterGroupMonsters[x].MonsterClass.Name,4) == "Fire")
                                    ScoringValue *= FireScoreMultiplier;
                                if (Left(MonsterGroupMonsters[x].MonsterClass.Name,3) == "Ice")
                                    ScoringValue *= IceScoreMultiplier;
                                
                                PointsSum += ScoringValue;
                                // Log("        MonsterGroup" @ MonsterGroup @ "monster" @ MonsterGroupMonsters[x].MonsterClass @ "name:" @ MonsterGroupMonsters[x].MonsterClass.Name @ "points:" @ MonsterGroupMonsters[x].MonsterClass.default.ScoringValue @ "adjusted" @ ScoringValue);
                                // Log(MonsterGroupMonsters[x].MonsterClass @ "points:" @ MonsterGroupMonsters[x].MonsterClass.default.ScoringValue);
                            }
                        }
                        if (MonsterCount == 0)
                        {
                            AveragePoints = 0.0;
                            WaveDifficulty = 0;
                        }
                        else
                        {
                            AveragePoints = PointsSum * 1.0/MonsterCount;
                            WaveDifficulty = AveragePoints * MaxMonsters;
                        }
                        
                        Log("Wave" @ WaveConfig[i].WaveNumber @ "DifficultyMode" @ d @ "MonsterGroup" @ MonsterGroup @ "Chance" @ WaveConfig[i].WaveOptions[j].Chance @ "MaxMonsters" @ MaxMonsters @ "Average points" @ AveragePoints @ "WaveDifficulty" @ WaveDifficulty);
                    }
                }
            }
        }
    
    	for(i=0; i < BonusWaveConfig.Length; i++)
    	{
            if (BonusWaveConfig[i].DifficultyMode == d)
            {
                for (j=0; j < BonusWaveConfig[i].WaveOptions.Length; j++)
                {
                   if (BonusWaveConfig[i].WaveOptions[j].Chance > 0)
                    {
                        MaxMonsters =  BonusWaveConfig[i].WaveOptions[j].MaxMonsters;
                        MonsterGroup = BonusWaveConfig[i].WaveOptions[j].MonsterGroup;
                        
                        PointsSum = 0;
                        MonsterCount = 0;
                     	for(x=0; x < MonsterGroupMonsters.Length; x++)
                    	{
                            if (MonsterGroupMonsters[x].MonsterGroup == MonsterGroup)
                            {
                                MonsterCount++;
                                ScoringValue = MonsterGroupMonsters[x].MonsterClass.default.ScoringValue;
                                if (Left(MonsterGroupMonsters[x].MonsterClass.Name,5) == "Earth")
                                    ScoringValue *= EarthScoreMultiplier;
                                if (Left(MonsterGroupMonsters[x].MonsterClass.Name,4) == "Fire")
                                    ScoringValue *= FireScoreMultiplier;
                                if (Left(MonsterGroupMonsters[x].MonsterClass.Name,3) == "Ice")
                                    ScoringValue *= IceScoreMultiplier;
                                
                                PointsSum += ScoringValue;
                                // Log("        MonsterGroup" @ MonsterGroup @ "monster" @ MonsterGroupMonsters[x].MonsterClass @ "points:" @ MonsterGroupMonsters[x].MonsterClass.default.ScoringValue);
                                // Log(MonsterGroupMonsters[x].MonsterClass @ "points:" @ MonsterGroupMonsters[x].MonsterClass.default.ScoringValue);
                            }
                        }
                        if (MonsterCount == 0)
                        {
                            AveragePoints = 0.0;
                            WaveDifficulty = 0;
                        }
                        else
                        {
                            AveragePoints = PointsSum * 1.0/MonsterCount;
                            WaveDifficulty = AveragePoints * MaxMonsters;
                        }
                        
                        Log("BonusWave" @ BonusWaveConfig[i].WaveNumber @ "DifficultyMode" @ d @ "MonsterGroup" @ MonsterGroup @ "Chance" @ BonusWaveConfig[i].WaveOptions[j].Chance @ "MaxMonsters" @ MaxMonsters @ "Average points" @ AveragePoints @ "WaveDifficulty" @ WaveDifficulty);
                    }
                }
            }
        }
    }
    
    Log("------------   End of Wave Configuration  -------------");    
}

function Timer()
{
	local int x;
    local int MaxMonsters;
    local int MonsterGroup;
    
	//Increment the Final Wave number if we have BONUS or a Boss Wave
	if (!SpecialWaveAdded && (default.bBunnyWaveAdded == True || bBossWaveAdded == True))
	{
		Invasion.FinalWave += 1;
		if (Invasion.FinalWave > 16)
			Invasion.FinalWave = 16;	//Safety measure so we don't go out of bounds
		SpecialWaveAdded = True;
	}

	//Timer() will continuously check for a new wave in Invasion
	//If a new wave is found, do a one-time spin of the wheel for that wave to determine whether we should randomize the monsters in that wave
	if (WaveNum != Invasion.WaveNum && Invasion.bWaveInProgress && BonusWavePlayed[Invasion.WaveNum] == 0 && BonusWaveInitialized == False)	//This is a new wave, so we have to spin the wheel and set this class's WaveNum to Invasion's WaveNum. bWaveInProgress must be set because Invasion sets the monster list right when Countdown is 0
	{
		WaveNum = Invasion.WaveNum;
        ConfigureWave(WaveNum);
	}
	
	//While we are in countdown of the new wave, check the previous wave to see if it had a bonus wave enabled
	if (!Invasion.bWaveInProgress && Invasion.WaveCountdown <= 5)
	{
        if (Invasion.WaveNum != FinalWave)
        {
    		if (Invasion.WaveNum-1 > 0 && BonusWaveInitialized == False && BonusWavePlayed[Invasion.WaveNum-1] == 0)
    		{
    			// The previous wave may have had a bonus wave that we did not play. If so, we need to decrement the Wave Number and play that wave - if we match the chance
               if (IsBonusWaveWaiting(Invasion.WaveNum-1, MaxMonsters, MonsterGroup) == True)
                {
                    BonusMonsterGroupNext = MonsterGroup;
                    MaxBonusMonstersNext = MaxMonsters;
        			Invasion.WaveNum -= 1;
        			BonusWaveInitialized= True;
                }
                else
                    BonusWavePlayed[Invasion.WaveNum-1] = 1;    // don't check again - we failed the chance test
    		}
        }
        else
        {
    		//We are on the last wave. We need to see if either bunny or boss waves are unlocked
    		if (default.bBunnyWaveAdded && bBossWaveAdded)		//We have both Boss and Bunny waves. Decrement Invasion wave number by 1 so we can fit both of them
    		{
    			//Go through the Bunny wave first
    			if (BunnyWaveInitialized == False)
    			{
    				Invasion.WaveNum -= 1;
    				BunnyWaveInitialized = True;
    			}
    			if (BossWaveInitialized == False && BunnyWaveCompleted == True)
    			{
    				BossWaveInitialized = True;
    			}
    		}
    		else if (bBossWaveAdded && !default.bBunnyWaveAdded)	//Add just the Boss wave. Do not decrement the invasion wave number
    		{
    			if (BossWaveInitialized == False)
    				BossWaveInitialized = True;
    		}
    		else if (!bBossWaveAdded && default.bBunnyWaveAdded)	//Add just the Bunny wave. Do not decrement the invasion wave number
    		{
    			if (BunnyWaveInitialized == False)
    				BunnyWaveInitialized = True;
    		}
    		SpecialWaveInitialized = True;
        }
	}
	
	//Below checks the end of a wave to see if there is a bonus wave
	if (Invasion.bWaveInProgress && BonusWaveInitialized == True && BonusMonsterGroupNext > 0)
	{
		WaveBonus();
        BonusMonsterGroupNext = 0;
        MaxBonusMonstersNext = 0;
		BonusWaveInitialized = False;	//Set BonusWaveInitialized back to false for next wave if next wave is a bonus wave
		BonusWavePlayed[Invasion.WaveNum] = 1;
	}
	
	//Below handles the bunny and boss waves
	if (Invasion.bWaveInProgress && (default.bBunnyWaveAdded || bBossWaveAdded) && SpecialWaveInitialized)
	{
		if (!BunnyWaveCompleted)	//This is the first round of the special wave
		{
			if (BunnyWaveInitialized)
			{
				Log("Adding bunny wave");
				BunnyWaveCompleted = True;
				AddBunnyWave();
				BonusWavePlayed[Invasion.WaveNum] = 1;
			}
			else
			{
				if (BossWaveInitialized)
				{
					AddBossWave();
				}
				//else
				//Shouldn't be the case, we made a check to see that either bBunnyWaveAdded or bBossWaveAdded is true
			}
		}
		else
		{
			if (BossWaveInitialized)
			{
				AddBossWave();
			}
		}
		SpecialWaveInitialized = False;	
	}
	
	if (BossWaveInitialized)
	{
		if (Invasion.bWaveInProgress)
		{
			//Currently in the middle of a boss wave
			// Make sure only one boss spawns
			for (x = 0; x < BossSpawnAttempt && BossPawn == None && !BossSpawned; x++)
				HandleBossWave();
			
			//Reward End-game XP to players for reaching this far. No penalty for dying on bosses
			if (!XPRewarded)
				RewardXP();		
		}
		else
		{
			//In countdown before boss wave
			//Reset player health and adrenaline
			if (Invasion.WaveCountdown <= 2 && !bPlayerReset)
			{
				ResetPlayerForBoss();
			}
		}
	}
	
	if (Invasion.bWaveInProgress && BunnyWaveInitialized && BunnyWaveCompleted && !BossWaveInitialized)
	{
		//Currently in the middle of Bunny wave
		//Give all players extra lives
		HandleBunnyWave();
	}
}

function bool IsBonusWaveWaiting(int WaveNum, out int MaxMonsters, out int MonsterGroup)
{
    local int DifficultyMode;
    local int x;
    local int i;
    local int chance;
    
	if (WaveNum == 0 || BonusWavePlayed[WaveNum] == 1)
        return false;

    DifficultyMode = GetDifficultyMode();
        
    for (x=0; x < BonusWaveConfig.Length; x++)
    {
        if (BonusWaveConfig[x].WaveNumber == WaveNum+1 && BonusWaveConfig[x].DifficultyMode == DifficultyMode)
        {
            // found the config record. Let's check the chance
            chance = Rand(100);
            for (i=0; i < BonusWaveConfig[x].WaveOptions.Length; i++)
            {
                if (chance < BonusWaveConfig[x].WaveOptions[i].Chance)
                {
                    MaxMonsters = BonusWaveConfig[x].WaveOptions[i].MaxMonsters;
                    MonsterGroup = BonusWaveConfig[x].WaveOptions[i].MonsterGroup;
                    if (CheckConfig)
                        Log("+++++ IsBonusWaveWaiting checking for Bonus Wave for Wave number:" @ WaveNum @ "found bonus wave MonsterGroup:" @ MonsterGroup);
                   return true;
                }
                else
                    chance -= BonusWaveConfig[x].WaveOptions[i].Chance;
            }

            if (CheckConfig)
                Log("+++++ IsBonusWaveWaiting checking for Bonus Wave for Wave number:" @ WaveNum @ "found record, but chance said no");
            return false;
        }
    }
    
    return false;
}

function int GetDifficultyMode()
{
	local Controller C;
	local Inventory Inv;
    local int MinLevel;
    local int MaxLevel;     // don't currently need, but may do in the future if we do an easy wave setup
    local int NumPlayers;
    local int x; 

    if (DifficultyModes.Length == 0)
        return 0;
            
    MaxLevel = 0;
    MinLevel = 99999;
    NumPlayers = 0;

	for (C = Level.ControllerList; C != None; C = C.NextController)
		if (C.bIsPlayer && C.PlayerReplicationInfo != None && !C.PlayerReplicationInfo.bBot)
			for (Inv = C.Inventory; Inv != None; Inv = Inv.Inventory)
				if ( RPGStatsInv(Inv) != None)
                {
                    NumPlayers++;
                    if (RPGStatsInv(Inv).DataObject.Level < MinLevel )
                    {
                        MinLevel = RPGStatsInv(Inv).DataObject.Level;
                    }
                    if (RPGStatsInv(Inv).DataObject.Level > MaxLevel )
                    {
                        MaxLevel = RPGStatsInv(Inv).DataObject.Level;
                    }
                }

    if (CheckConfig)
        Log("+++++ GetDifficultyMode NumPlayers:" @ NumPlayers @ "Minlevel:" @ Minlevel @ "Maxlevel:" @ MaxLevel);

    for (x=0;x < DifficultyModes.Length;x++)
        if (NumPlayers >= DifficultyModes[x].MinNumPlayers && MinLevel >= DifficultyModes[x].MinPlayerLevel  && MaxLevel <= DifficultyModes[x].MaxPlayerLevel)   
            return  DifficultyModes[x].DifficultyMode;     
            
    return 0; 
}

function WaveOption GetWaveOption(int WaveNumber, int DifficultyMode)
{
    local int x;
    local int i;
    local int chance;
    local WaveOption dummyoption;
    
    for (x=0; x < WaveConfig.Length; x++)
    {
        if (WaveConfig[x].WaveNumber == WaveNumber && WaveConfig[x].DifficultyMode == DifficultyMode)
        {
            // found the correct config. Now let's choose the option
            if (WaveConfig[x].WaveOptions.Length == 1)
            {
                return WaveConfig[x].WaveOptions[0];
            }
            else
            {
                chance = Rand(100);
                for (i=0; i < WaveConfig[x].WaveOptions.Length; i++)
                {
                    if (chance < WaveConfig[x].WaveOptions[i].Chance)
                        return WaveConfig[x].WaveOptions[i];
                    else
                        chance -= WaveConfig[x].WaveOptions[i].Chance;
                }
                
                // didn't find it, but should have. Just return the last one
                Log("!!!!!!!!!! Error in GetWaveoption. Found WaveConfig but couldn't find Waveoption for WaveNumber:" @ WaveNumber @ "DifficultyMode:" @ DifficultyMode @ "Number of WaveOptions:" @ WaveConfig[x].WaveOptions.Length);
                return WaveConfig[x].WaveOptions[WaveConfig[x].WaveOptions.Length -1];
            }
        }
    }
    
    Log("!!!!!!!!!! Error in GetWaveOption. Couldn't find WaveConfig for WaveNumber:" @ WaveNumber @ "DifficultyMode:" @ DifficultyMode);
    dummyOption.MonsterGroup = 1;
    dummyOption.MaxMonsters=5;
    return dummyoption;
}

function array< class< Monster > > GetMonstersForGroup(int MonsterGroup)
{
	local int i;
    local array< class< Monster > > SelectedMonsters;

    SelectedMonsters.Length = 0;
	for(i=0; i<MonsterGroupMonsters.Length; i++)
	{
        if (MonsterGroupMonsters[i].MonsterGroup == MonsterGroup)
                SelectedMonsters[SelectedMonsters.Length] = MonsterGroupMonsters[i].MonsterClass;    
    }
    
    return SelectedMonsters;
}

function ConfigureWave(int WaveNum)
{
	//This function handles the randomization of each specific wave

	local int i;
    local int DifficultyMode;
    local WaveOption SelectedWaveOption;
    local array< class< Monster > > SelectedMonsters;

    DifficultyMode = GetDifficultyMode();
    SelectedWaveOption = GetWaveOption(WaveNum+1, DifficultyMode);
    SelectedMonsters = GetMonstersForGroup(SelectedWaveOption.MonsterGroup);

    if (CheckConfig)
        Log("+++++ Wave selected for wave" @ WaveNum @ "difficulty mode" @ DifficultyMode @ "using group" @ SelectedWaveOption.MonsterGroup @ "returned" @ SelectedMonsters.Length @ "monsters");
    
    if (SelectedMonsters.Length == 0)
    {
        Log("!!!!!!!!!! Error in ConfigureWave - no monsters selected for wave" @ WaveNum @ "using group" @ SelectedWaveOption.MonsterGroup );
        return;
    }
        
	Invasion.WaveNumClasses=0;
	for(i=0;i<16;i++)
	{
		Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = SelectedMonsters[Rand(SelectedMonsters.Length)];
		Invasion.WaveNumClasses++;
	}

    BroadcastLocalizedMessage(class'WaveRandomizedMessage', SelectedWaveOption.MonsterGroup);
   
	Invasion.Waves[Invasion.WaveNum].WaveMaxMonsters = SelectedWaveOption.MaxMonsters;
	Invasion.MaxMonsters = SelectedWaveOption.MaxMonsters;
	// Invasion.Waves[Invasion.WaveNum].WaveDuration = Waves[Invasion.WaveNum].RandomizedWaveDuration;
}

function WaveBonus()
{
	local int i;
    local array< class< Monster > > SelectedMonsters;

    SelectedMonsters = GetMonstersForGroup(BonusMonsterGroupNext);

    if (CheckConfig)
        Log("+++++ Wave selected for bonus wave" @ WaveNum @ "using group" @ BonusMonsterGroupNext @ "returned" @ SelectedMonsters.Length @ "monsters");
    
    if (SelectedMonsters.Length == 0)
    {
        Log("!!!!!!!!!! Error in ConfigureWave - no monsters selected for bonus wave" @ WaveNum @ "using group" @ BonusMonsterGroupNext );
        return;
    }
        
	Invasion.WaveNumClasses=0;
	for(i=0;i<16;i++)
	{
		Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = SelectedMonsters[Rand(SelectedMonsters.Length)];
		Invasion.WaveNumClasses++;
	}
    
    BroadcastLocalizedMessage(class'WaveRandomizedMessage', BonusMonsterGroupNext);

	Invasion.Waves[Invasion.WaveNum].WaveMaxMonsters = MaxBonusMonstersNext;
	Invasion.MaxMonsters = MaxBonusMonstersNext;
	// Invasion.Waves[Invasion.WaveNum].WaveDuration = Waves[Invasion.WaveNum].BonusWaveDuration;
}

function ResetPlayerForBoss()
{
	local Controller C, NextC;
	
	C = Level.ControllerList;
	while (C != None)
	{
		NextC = C.NextController;
		if (C.Pawn != None && C.Pawn.Health < C.Pawn.HealthMax)
			C.Pawn.Health = C.Pawn.HealthMax;
		if (C.Adrenaline < C.AdrenalineMax)
			C.Adrenaline = C.AdrenalineMax;
		C = NextC;
	}
	bPlayerReset = true;
}

static function UnlockBONUSWave()
{
	default.bBunnyWaveAdded = true;
}

static function bool IsBONUSUnlocked()
{
	return default.bBunnyWaveAdded;
}

function AddBunnyWave()
{
	local int i;

	Invasion.WaveNumClasses=0;
	for(i=0;i<16;i++)
	{
		Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = BunnyMonsterClass[Rand(BunnyMonsterClass.Length)];
		Invasion.WaveNumClasses++;
	}
	Invasion.Waves[Invasion.WaveNum].WaveMaxMonsters = BunnyWaveMaxMonsters;
	Invasion.MaxMonsters = BunnyWaveMaxMonsters;
	Invasion.Waves[Invasion.WaveNum].WaveDuration = BunnyWaveDuration;
}

function AddBossWave()
{
	local int BossIndex;

	BossIndex = Rand(BossMonsterClass.Length);
	BossClass = BossMonsterClass[BossIndex];

	Invasion.Waves[Invasion.WaveNum].WaveMaxMonsters = BOSSWAVEMAXMONSTERS;
	Invasion.MaxMonsters = BOSSWAVEMAXMONSTERS;
	Invasion.Waves[Invasion.WaveNum].WaveDuration = BossWaveDuration;
	Invasion.WaveEndTime = BossWaveDuration;
}

//Currently in the middle of bunny wave
//This function will be continously called with Timer
function HandleBunnyWave()
{
	local Controller C, NextC;
	
	C = Level.ControllerList;
	while (C != None)
	{
		NextC = C.NextController;
		if (C != None && C.PlayerReplicationInfo != None && !C.PlayerReplicationInfo.bOnlySpectator && C.PlayerReplicationInfo.bOutOfLives)
		{
			C.PlayerReplicationInfo.bOutOfLives = False;
			Invasion.RestartPlayer(C);
			if (C.bGodMode)
				C.bGodMode = False;
		}
		C = NextC;
	}
}

//Finds a location for the Boss and spawns it. Displays a message to all players
//This function is continuously called by Timer until a Boss is spawned
simulated function HandleBossWave()
{
	local NavigationPoint StartSpot;
	local Controller C;
	
	if (BossPawn == None)
	{
		//Find a spawn point
		StartSpot = Invasion.FindPlayerStart(None,1);
		if ( StartSpot == None )
			return;		//Try again later. This function will get called again by Timer
		BossPawn = Spawn(BossClass,,,StartSpot.Location+(BossClass.Default.CollisionHeight - StartSpot.CollisionHeight) * vect(0,0,1),StartSpot.Rotation);
		if (BossPawn != None)
		{
			BossSpawned = True;
			Invasion.NumMonsters = 1000;	//Yikes... ugly but doable
			Invasion.WaveMonsters = -1;		//Also yikes
			BossPawn.default.Health += (Invasion.NumPlayers * BossHealthAddPerPlayer);
			BossPawn.default.HealthMax += (Invasion.NumPlayers * BossHealthAddPerPlayer);
			
			Level.Game.BroadCast(Self, "Boss: " $ BossPawn.OwnerName);
			for ( C = Level.ControllerList; C != None; C = C.NextController )
				if (C != None && C.IsA('PlayerController') )
					PlayerController(C).ClientPlaySound(Sound'WaveRandomizer999X.Boss.BossWarning');
		}
	}
}

//Rewards the end-game XP to players. We shouldn't penalize them if they don't survive the boss
function RewardXP()
{
	local Controller C;
	local MutUT2004RPG RPG;
	local Mutator m;
	local RPGStatsInv StatsInv;
	local RPGRules Rules;
	Local GameRules G;
	
	if (Level.Game != None)
	{
		for(G = Level.Game.GameRulesModifiers; G != None; G = G.NextGameRules)
		{
			if(G.isA('RPGRules'))
			{
				Rules = RPGRules(G);
				break;
			}
		}
		
		for (m = Level.Game.BaseMutator; m != None; m = m.NextMutator)
			if (MutUT2004RPG(m) != None)
			{
				RPG = MutUT2004RPG(m);
				break;
			}
	}
	
	if(Rules == None)
		Log("WARNING: Unable to find RPGRules in GameRules. EXP will not be properly awarded");
		
	if (RPG != None && Rules != None && RPG.EXPForWin > 0)
	{
		for (C = Level.ControllerList; C != None; C = C.NextController)
			if (C.PlayerReplicationInfo != None && C.bIsPlayer)
			{
				StatsInv = Rules.GetStatsInvFor(C);
				if (StatsInv != None)
				{
					StatsInv.DataObject.Experience += RPG.EXPForWin;
					RPG.CheckLevelUp(StatsInv.DataObject, C.PlayerReplicationInfo);
				}
			}
	}
	XPRewarded = True;
}

defaultproperties
{
     CheckConfig=true
     BunnyMonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     SafeMonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
	 BossMonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     FinalWave=16
     bAdjustFinalWave=True
     BossWaveIndex=14
     BossWaveChance=10
     BossHealthAddPerPlayer=5000
     BossWaveDuration=10
	 BossSpawnAttempt=10
     BunnyWaveMaxMonsters=24
     BunnyWaveDuration=90
     bAddToServerPackages=True
     GroupName="WaveRandomizer"
     FriendlyName="Wave Randomizer"
     Description="Provides a % chance to randomize invasion waves with a configurable monster list. Also adds configurable bonus waves that act as a secondary wave without incrementing the invasion wave number."
     bAlwaysRelevant=True
}
