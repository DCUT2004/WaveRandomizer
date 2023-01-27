class MutWaveRandomizer extends Mutator
	config(satoreMonsterPack);
	
var Invasion Invasion;
var config Array < class < Monster > > Wave1MonsterClass, Wave2MonsterClass, Wave3MonsterClass, Wave4MonsterClass, Wave5MonsterClass, Wave6MonsterClass, Wave7MonsterClass, Wave8MonsterClass, Wave9MonsterClass, Wave10MonsterClass, Wave11MonsterClass, Wave12MonsterClass, Wave13MonsterClass, Wave14MonsterClass, Wave15MonsterClass, Wave16MonsterClass, IceOnlyMonsterClass, FireOnlyMonsterClass, EarthOnlyMonsterClass;
var config Array < class < Monster > > KrallClass, BruteClass, SlithClass, GasbagClass, SlugClass, MercenaryClass, RazorflyClass;
var config Array < class < Monster > > Wave1BonusMonsterClass, Wave2BonusMonsterClass, Wave3BonusMonsterClass, Wave4BonusMonsterClass, Wave5BonusMonsterClass, Wave6BonusMonsterClass, Wave7BonusMonsterClass, Wave8BonusMonsterClass, Wave9BonusMonsterClass, Wave10BonusMonsterClass, Wave11BonusMonsterClass, Wave12BonusMonsterClass, Wave13BonusMonsterClass, Wave14BonusMonsterClass, Wave15BonusMonsterClass, Wave16BonusMonsterClass;
var config Array < class < Monster > > BunnyMonsterClass, SafeMonsterClass, BossMonsterClass;
var config Array < class < Monster > > Wave1BrutalMonsterClass, Wave2BrutalMonsterClass, Wave3BrutalMonsterClass, Wave4BrutalMonsterClass, Wave5BrutalMonsterClass, Wave6BrutalMonsterClass, Wave7BrutalMonsterClass, Wave8BrutalMonsterClass, Wave9BrutalMonsterClass, Wave10BrutalMonsterClass, Wave11BrutalMonsterClass, Wave12BrutalMonsterClass, Wave13BrutalMonsterClass, Wave14BrutalMonsterClass, Wave15BrutalMonsterClass, Wave16BrutalMonsterClass;
var int WaveNum;

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
const BOSSWAVEMAXMONSTERS = 0;

//Bunny wave variables
var bool BonusWaveInitialized, BunnyWaveInitialized, BunnyWaveCompleted;
var bool bBunnyWaveAdded;
var config byte BunnyWaveMaxMonsters, BunnyWaveDuration;

#exec  AUDIO IMPORT NAME="BossWarning" FILE="Sounds\BossWarning.WAV" GROUP="Boss"

struct WaveInfo
{
	var() byte	RandomizedWaveMaxMonsters;
	var() byte	RandomizedWaveDuration;
	var() int	WaveChance;
	var() bool	WaveRandomizedEnabled;
    var() int	RandomizedMessageSwitch;
	var() int	BrutalWaveChance;
    var() int   BrutalWaveMaxMonsters;
	var() bool	BonusWaveEnabled;
	var() bool	BonusWavePlayed;
	var() byte	BonusWaveMaxMonsters;
	var() byte	BonusWaveDuration;
};

var() config WaveInfo Waves[16];

struct BrutalCondition
{
    var int MinPlayers;
    var int MinLevel;
};
var config Array<BrutalCondition> BrutalConditions;

event PostBeginPlay()
{
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
		if (Rand(100) <= BossWaveChance)
			bBossWaveAdded = True;
		else
			bBossWaveAdded = False;
		SetTimer(1, True);
		WaveNum = -1; 	//Initialize the WaveNum to -1. This is set so that Timer() can check this condition as true for the first wave of this game.
	}
	Super.PostBeginPlay();
}

function Timer()
{
	local int x;
    local bool MakeBrutal;
    
	//Increment the Final Wave number if we have BONUS or a Boss Wave
	if (!SpecialWaveAdded && (default.bBunnyWaveAdded == True || bBossWaveAdded == True))
	{
		Invasion.FinalWave += 1;
		if (Invasion.FinalWave > 16)
			Invasion.FinalWave = 16;	//Safety measure so we don't go out of bounds
		Waves[BossWaveIndex].BonusWaveEnabled = True;
		SpecialWaveAdded = True;
	}

	//Timer() will continuously check for a new wave in Invasion
	//If a new wave is found, do a one-time spin of the wheel for that wave to determine whether we should randomize the monsters in that wave
	if (WaveNum != Invasion.WaveNum && Invasion.bWaveInProgress && Waves[Invasion.WaveNum].BonusWavePlayed == False && BonusWaveInitialized == False)	//This is a new wave, so we have to spin the wheel and set this class's WaveNum to Invasion's WaveNum. bWaveInProgress must be set because Invasion sets the monster list right when Countdown is 0
	{
		WaveNum = Invasion.WaveNum;
        MakeBrutal = AreWeBrutal();
    
	    if (MakeBrutal && Rand(100) < Waves[WaveNum].BrutalWaveChance)
		{
				WaveBrutalRandomize();
		}
        else
        {
            // if we haven't meet the requirements for a brutal wave - either the levels of unlucky - then try for a normal randomisation
    		if (Rand(100) < Waves[WaveNum].WaveChance && Waves[WaveNum].WaveRandomizedEnabled)
    		{
    				WaveRandomize();
    		}
        }
	}
	
	//While we are in countdown of the new wave, check the previous wave to see if it had a bonus wave enabled
	if (!Invasion.bWaveInProgress && Invasion.WaveCountdown <= 5 && Invasion.WaveNum != FinalWave)
	{
		if (Invasion.WaveNum-1 > 0 && Waves[Invasion.WaveNum-1].BonusWaveEnabled == True && Waves[Invasion.WaveNum-1].BonusWavePlayed == False && BonusWaveInitialized == False)
		{
			//The previous wave had a bonus wave that we did not play. We need to decrement the Wave Number and play that wave
			Invasion.WaveNum -= 1;
			BonusWaveInitialized= True;
		}
	}
	
	//While we are in countdown of the final wave, check to see if we have Boss or Bunny waves enabled
	if (!Invasion.bWaveInProgress && Invasion.WaveCountdown <= 5 && Invasion.WaveNum == FinalWave)
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
	
	//Below checks the end of a wave to see if there is a bonus wave
	if (Invasion.bWaveInProgress && Waves[Invasion.WaveNum].BonusWaveEnabled == True && BonusWaveInitialized == True)
	{
		WaveBonus();
		BonusWaveInitialized = False;	//Set BonusWaveInitialized back to false for next wave if next wave is a bonus wave
		Waves[Invasion.WaveNum].BonusWavePlayed = True;
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
				Waves[Invasion.WaveNum].BonusWavePlayed = True;
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

function bool AreWeBrutal()
{
	local Controller C;
	local Inventory Inv;
    local int MinLevel;
    local int MaxLevel;     // don't currently need, but may do in the future if we do an easy wave setup
    local int NumPlayers;
    local int x;

    if (BrutalConditions.Length == 0)
        return false;
            
    MaxLevel = 0;
    MinLevel = 20000;
    NumPlayers = 0;

	for (C = Level.ControllerList; C != None; C = C.NextController)
		if (C.bIsPlayer && C.PlayerReplicationInfo != None && !C.PlayerReplicationInfo.bOutOfLives && !C.PlayerReplicationInfo.bBot)
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

    for (x=0;x < BrutalConditions.Length;x++)
        if (NumPlayers >= BrutalConditions[x].MinPlayers && MinLevel > BrutalConditions[x].MinLevel)   
            return true;
            
    return false; 
}

function WaveRandomize()
{
	//This function handles the randomization of each specific wave
	
	local int i;
	local int RandIndex;

    switch (Invasion.WaveNum)
    {
    	case 0:
    		Invasion.WaveNumClasses=0;
    		for(i=0;i<16;i++)
    		{
    			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave1MonsterClass[Rand(Wave1MonsterClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
            break;
            
    	case 1:
    		Invasion.WaveNumClasses=0;
    		for(i=0;i<16;i++)
    		{
    			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave2MonsterClass[Rand(Wave2MonsterClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
            break;
            
    	case 2:
    		Invasion.WaveNumClasses=0;
    		for(i=0;i<16;i++)
    		{
    			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave3MonsterClass[Rand(Wave3MonsterClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
            break;
            
    	case 3:
    		Invasion.WaveNumClasses=0;
    		for(i=0;i<16;i++)
    		{
    			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave4MonsterClass[Rand(Wave4MonsterClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
            break;
            
    	case 4:
    		Invasion.WaveNumClasses=0;
    		for(i=0;i<16;i++)
    		{
    			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave5MonsterClass[Rand(Wave5MonsterClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
            break;
            
    	case 5:
    		Invasion.WaveNumClasses=0;
    		for(i=0;i<16;i++)
    		{
    			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave6MonsterClass[Rand(Wave6MonsterClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
            break;
            
    	case 6:
    		Invasion.WaveNumClasses=0;
    		for(i=0;i<16;i++)
    		{
    			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave7MonsterClass[Rand(Wave7MonsterClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
            break;
            
    	case 7:
    		Invasion.WaveNumClasses=0;
    		for(i=0;i<16;i++)
    		{
    			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave8MonsterClass[Rand(Wave8MonsterClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
            break;
            
    	case 8:
    		Invasion.WaveNumClasses=0;
    		for(i=0;i<16;i++)
    		{
    			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave9MonsterClass[Rand(Wave9MonsterClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
            break;
            
    	case 9:
    		Invasion.WaveNumClasses=0;
    		for(i=0;i<16;i++)
    		{
    			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave10MonsterClass[Rand(Wave10MonsterClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
            break;
            
    	case 10:
    		Invasion.WaveNumClasses=0;
    		for(i=0;i<16;i++)
    		{
    			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave11MonsterClass[Rand(Wave11MonsterClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
            break;
            
    	case 11:	//Roulette wave. Choose 1 type of monster
    		RandIndex = Rand(7);
    		Invasion.WaveNumClasses=0;
    		for(i=0;i<16;i++)
    		{
    			if (RandIndex == 0)
    				Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = KrallClass[Rand(KrallClass.Length)];
    			else if (RandIndex == 1)
    				Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = SlithClass[Rand(SlithClass.Length)];
    			else if (RandIndex == 2)
    				Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = BruteClass[Rand(BruteClass.Length)];
    			else if (RandIndex == 3)
    				Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = MercenaryClass[Rand(MercenaryClass.Length)];
    			else if (RandIndex == 4)
    				Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = GasbagClass[Rand(GasbagClass.Length)];
    			else if (RandIndex == 5)
    				Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = SlugClass[Rand(SlugClass.Length)];
    			else
    				Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = RazorflyClass[Rand(RazorflyClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
            break;
            
    	case 12:
    		Invasion.WaveNumClasses=0;
    		for(i=0;i<16;i++)
    		{
    			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave13MonsterClass[Rand(Wave13MonsterClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
            break;
            
    	case 13:
    		Invasion.WaveNumClasses=0;
    		RandIndex = Rand(3);
    		if (RandIndex == 0)
    		{
    			for(i=0;i<16;i++)
    			{
    				Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = FireOnlyMonsterClass[Rand(FireOnlyMonsterClass.Length)];
    				Invasion.WaveNumClasses++;
    			}
    		}
    		else if (RandIndex == 1)
    		{
    			for(i=0;i<16;i++)
    			{
    				Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = IceOnlyMonsterClass[Rand(IceOnlyMonsterClass.Length)];
    				Invasion.WaveNumClasses++;
    			}
    		}
    		else
    		{
    			for(i=0;i<16;i++)
    			{
    				Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = EarthOnlyMonsterClass[Rand(EarthOnlyMonsterClass.Length)];
    				Invasion.WaveNumClasses++;
    			}
    		}
            break;
            
    	case 14:
    		Invasion.WaveNumClasses=0;
    		for(i=0;i<16;i++)
    		{
    			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave15MonsterClass[Rand(Wave15MonsterClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
            break;
            
    	case 15:
    		Invasion.WaveNumClasses=0;
    		for(i=0;i<16;i++)
    		{
    			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave16MonsterClass[Rand(Wave16MonsterClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
    }
    
    BroadcastLocalizedMessage(class'WaveRandomizedMessage', Waves[Invasion.WaveNum].RandomizedMessageSwitch);
	Invasion.Waves[Invasion.WaveNum].WaveMaxMonsters = Waves[Invasion.WaveNum].RandomizedWaveMaxMonsters;
	Invasion.MaxMonsters = Waves[Invasion.WaveNum].RandomizedWaveMaxMonsters;
	Invasion.Waves[Invasion.WaveNum].WaveDuration = Waves[Invasion.WaveNum].RandomizedWaveDuration;
}

function WaveBrutalRandomize()
{
	//This function handles the randomization of each specific wave, but where the player levels are high
	
	local int i;
	local int RandIndex;
    
    switch (Invasion.WaveNum)
    {
    	case 0:
    		Invasion.WaveNumClasses=0;
    		for(i=0;i<16;i++)
    		{
    			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave1BrutalMonsterClass[Rand(Wave1BrutalMonsterClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
            break;
            
    	case 1:
    		Invasion.WaveNumClasses=0;    // skaarj
    		for(i=0;i<16;i++)
    		{
    			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave2BrutalMonsterClass[Rand(Wave2BrutalMonsterClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
            break;
            
    	case 2:
    		Invasion.WaveNumClasses=0;    // ghosts only
    		for(i=0;i<16;i++)
    		{
    			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave3BrutalMonsterClass[Rand(Wave3BrutalMonsterClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
            break;
            
    	case 3:
    		Invasion.WaveNumClasses=0;    // warlords
    		for(i=0;i<16;i++)
    		{
    			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave4BrutalMonsterClass[Rand(Wave4BrutalMonsterClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
            break;
            
    	case 4:
    		Invasion.WaveNumClasses=0;    // tech and Cosmic
    		for(i=0;i<16;i++)
    		{
    			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave5BrutalMonsterClass[Rand(Wave5BrutalMonsterClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
            break;
            
    	case 5:
    		Invasion.WaveNumClasses=0;    //Roulette wave. Choose 1 type of monster
    		RandIndex = Rand(3);
    		for(i=0;i<16;i++)
    		{
    			if (RandIndex == 0)
    				Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = SlithClass[Rand(SlithClass.Length)];
    			else if (RandIndex == 1)
    				Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = BruteClass[Rand(BruteClass.Length)];
    			else 
    				Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = MercenaryClass[Rand(MercenaryClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
            break;
            
    	case 6:
    		Invasion.WaveNumClasses=0;    // titans and a couple of techs
    		for(i=0;i<16;i++)
    		{
    			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave7BrutalMonsterClass[Rand(Wave7BrutalMonsterClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
            break;
            
    	case 7:
    		Invasion.WaveNumClasses=0;
    		for(i=0;i<16;i++)
    		{
    			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave8BrutalMonsterClass[Rand(Wave8BrutalMonsterClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
            break;
            
    	case 8:
    		Invasion.WaveNumClasses=0;    // elementals
    		RandIndex = Rand(2);
            if (RandIndex == 0)
    		{
    			for(i=0;i<16;i++)
    			{
    				Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = IceOnlyMonsterClass[Rand(IceOnlyMonsterClass.Length)];
    				Invasion.WaveNumClasses++;
    			}
    		}
    		else
    		{
    			for(i=0;i<16;i++)
    			{
    				Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = EarthOnlyMonsterClass[Rand(EarthOnlyMonsterClass.Length)];
    				Invasion.WaveNumClasses++;
    			}
    		}
            break;
            
    	case 9:
    		Invasion.WaveNumClasses=0;
    		for(i=0;i<16;i++)
    		{
    			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave10BrutalMonsterClass[Rand(Wave10BrutalMonsterClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
            break;
            
    	case 10:
    		Invasion.WaveNumClasses=0;
    		for(i=0;i<16;i++)
    		{
    			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave11BrutalMonsterClass[Rand(Wave11BrutalMonsterClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
            break;
            
    	case 11:	//Roulette wave. Choose 1 type of monster
    		RandIndex = Rand(3);
    		Invasion.WaveNumClasses=0;
    		for(i=0;i<16;i++)
    		{
    			if (RandIndex == 0)
    				Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = KrallClass[Rand(KrallClass.Length)];
    			else if (RandIndex == 1)
    				Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = GasbagClass[Rand(GasbagClass.Length)];
    			else 
    				Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = SlugClass[Rand(SlugClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
            break;
            
    	case 12:
    		Invasion.WaveNumClasses=0;
    		for(i=0;i<16;i++)
    		{
    			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave13BrutalMonsterClass[Rand(Wave13BrutalMonsterClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
            break;
            
    	case 13:
    		Invasion.WaveNumClasses=0;
			for(i=0;i<16;i++)
			{
				Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = FireOnlyMonsterClass[Rand(FireOnlyMonsterClass.Length)];
				Invasion.WaveNumClasses++;
			}
            break;
            
    	case 14:
    		Invasion.WaveNumClasses=0;
    		for(i=0;i<16;i++)
    		{
    			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave15BrutalMonsterClass[Rand(Wave15BrutalMonsterClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
            break;
            
    	case 15:
    		Invasion.WaveNumClasses=0;
    		for(i=0;i<16;i++)
    		{
    			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave16BrutalMonsterClass[Rand(Wave16BrutalMonsterClass.Length)];
    			Invasion.WaveNumClasses++;
    		}
    }

    BroadcastLocalizedMessage(class'WaveRandomizedMessage', 100);
	Invasion.Waves[Invasion.WaveNum].WaveMaxMonsters = Waves[Invasion.WaveNum].RandomizedWaveMaxMonsters;
	Invasion.MaxMonsters = Waves[Invasion.WaveNum].BrutalWaveMaxMonsters;
	Invasion.Waves[Invasion.WaveNum].WaveDuration = Waves[Invasion.WaveNum].RandomizedWaveDuration;
}

function WaveBonus()
{
	local int i;

	if (Invasion.WaveNum == 0)
	{
		Invasion.WaveNumClasses=0;
		for(i=0;i<16;i++)
		{
			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave1BonusMonsterClass[Rand(Wave1BonusMonsterClass.Length)];
			Invasion.WaveNumClasses++;
		}
	}
	else if (Invasion.WaveNum == 1)
	{
		Invasion.WaveNumClasses=0;
		for(i=0;i<16;i++)
		{
			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave2BonusMonsterClass[Rand(Wave2BonusMonsterClass.Length)];
			Invasion.WaveNumClasses++;
		}
	}
	else if (Invasion.WaveNum == 2)
	{
		Invasion.WaveNumClasses=0;
		for(i=0;i<16;i++)
		{
			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave3BonusMonsterClass[Rand(Wave3BonusMonsterClass.Length)];
			Invasion.WaveNumClasses++;
		}
	}
	else if (Invasion.WaveNum == 3)
	{
		Invasion.WaveNumClasses=0;
		for(i=0;i<16;i++)
		{
			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave4BonusMonsterClass[Rand(Wave4BonusMonsterClass.Length)];
			Invasion.WaveNumClasses++;
		}
	}
	else if (Invasion.WaveNum == 4)
	{
		Invasion.WaveNumClasses=0;
		for(i=0;i<16;i++)
		{
			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave5BonusMonsterClass[Rand(Wave5BonusMonsterClass.Length)];
			Invasion.WaveNumClasses++;
		}
	}
	else if (Invasion.WaveNum == 5)
	{
		Invasion.WaveNumClasses=0;
		for(i=0;i<16;i++)
		{
			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave6BonusMonsterClass[Rand(Wave6BonusMonsterClass.Length)];
			Invasion.WaveNumClasses++;
		}
	}
	else if (Invasion.WaveNum == 6)
	{
		Invasion.WaveNumClasses=0;
		for(i=0;i<16;i++)
		{
			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave7BonusMonsterClass[Rand(Wave7BonusMonsterClass.Length)];
			Invasion.WaveNumClasses++;
		}
	}
	else if (Invasion.WaveNum == 7)
	{
		Invasion.WaveNumClasses=0;
		for(i=0;i<16;i++)
		{
			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave8BonusMonsterClass[Rand(Wave8BonusMonsterClass.Length)];
			Invasion.WaveNumClasses++;
		}
	}
	else if (Invasion.WaveNum == 8)
	{
		Invasion.WaveNumClasses=0;
		for(i=0;i<16;i++)
		{
			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave9BonusMonsterClass[Rand(Wave9BonusMonsterClass.Length)];
			Invasion.WaveNumClasses++;
		}
	}
	else if (Invasion.WaveNum == 9)
	{
		Invasion.WaveNumClasses=0;
		for(i=0;i<16;i++)
		{
			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave10BonusMonsterClass[Rand(Wave10BonusMonsterClass.Length)];
			Invasion.WaveNumClasses++;
		}
	}
	else if (Invasion.WaveNum == 10)
	{
		Invasion.WaveNumClasses=0;
		for(i=0;i<16;i++)
		{
			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave11BonusMonsterClass[Rand(Wave11BonusMonsterClass.Length)];
			Invasion.WaveNumClasses++;
		}
	}
	else if (Invasion.WaveNum == 11)
	{
		Invasion.WaveNumClasses=0;
		for(i=0;i<16;i++)
		{
			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave12BonusMonsterClass[Rand(Wave12BonusMonsterClass.Length)];
			Invasion.WaveNumClasses++;
		}
	}
	else if (Invasion.WaveNum == 12)
	{
		Invasion.WaveNumClasses=0;
		for(i=0;i<16;i++)
		{
			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave13BonusMonsterClass[Rand(Wave13BonusMonsterClass.Length)];
			Invasion.WaveNumClasses++;
		}
	}
	else if (Invasion.WaveNum == 13)
	{
		Invasion.WaveNumClasses=0;
		for(i=0;i<16;i++)
		{
			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave14BonusMonsterClass[Rand(Wave14BonusMonsterClass.Length)];
			Invasion.WaveNumClasses++;
		}
	}
	else if (Invasion.WaveNum == 14)
	{
		Invasion.WaveNumClasses=0;
		for(i=0;i<16;i++)
		{
			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave15BonusMonsterClass[Rand(Wave15BonusMonsterClass.Length)];
			Invasion.WaveNumClasses++;
		}
	}
	else if (Invasion.WaveNum == 15)
	{
		Invasion.WaveNumClasses=0;
		for(i=0;i<16;i++)
		{
			Invasion.WaveMonsterClass[Invasion.WaveNumClasses] = Wave16BonusMonsterClass[Rand(Wave16BonusMonsterClass.Length)];
			Invasion.WaveNumClasses++;
		}
	}
	Invasion.Waves[Invasion.WaveNum].WaveMaxMonsters = Waves[Invasion.WaveNum].BonusWaveMaxMonsters;
	Invasion.MaxMonsters = Waves[Invasion.WaveNum].BonusWaveMaxMonsters;
	Invasion.Waves[Invasion.WaveNum].WaveDuration = Waves[Invasion.WaveNum].BonusWaveDuration;
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
     Wave1MonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave2MonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave3MonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave4MonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave5MonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave6MonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave7MonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave8MonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave9MonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave10MonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave11MonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave12MonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave13MonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave14MonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave15MonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave16MonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     IceOnlyMonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     FireOnlyMonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     EarthOnlyMonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave1BonusMonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave2BonusMonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave3BonusMonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave4BonusMonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave5BonusMonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave6BonusMonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave7BonusMonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave8BonusMonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave9BonusMonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave10BonusMonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave11BonusMonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave12BonusMonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave13BonusMonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave14BonusMonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave15BonusMonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
     Wave16BonusMonsterClass(0)=Class'SkaarjPack.SkaarjPupae'
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
     Waves(0)=(RandomizedWaveMaxMonsters=16,RandomizedWaveDuration=80,BonusWaveMaxMonsters=1,BonusWaveDuration=80)
     Waves(1)=(RandomizedWaveMaxMonsters=16,RandomizedWaveDuration=80,BonusWaveMaxMonsters=1,BonusWaveDuration=80)
     Waves(2)=(RandomizedWaveMaxMonsters=16,RandomizedWaveDuration=80,BonusWaveMaxMonsters=1,BonusWaveDuration=80)
     Waves(3)=(RandomizedWaveMaxMonsters=16,RandomizedWaveDuration=80,BonusWaveMaxMonsters=1,BonusWaveDuration=80)
     Waves(4)=(RandomizedWaveMaxMonsters=16,RandomizedWaveDuration=80,BonusWaveMaxMonsters=1,BonusWaveDuration=80)
     Waves(5)=(RandomizedWaveMaxMonsters=32,RandomizedWaveDuration=80,BonusWaveMaxMonsters=1,BonusWaveDuration=80)
     Waves(6)=(RandomizedWaveMaxMonsters=5,RandomizedWaveDuration=80,BonusWaveMaxMonsters=1,BonusWaveDuration=80)
     Waves(7)=(RandomizedWaveMaxMonsters=12,RandomizedWaveDuration=80,BonusWaveMaxMonsters=1,BonusWaveDuration=80)
     Waves(8)=(RandomizedWaveMaxMonsters=6,RandomizedWaveDuration=80,BonusWaveMaxMonsters=1,BonusWaveDuration=80)
     Waves(9)=(RandomizedWaveMaxMonsters=24,RandomizedWaveDuration=80,BonusWaveMaxMonsters=1,BonusWaveDuration=80)
     Waves(10)=(RandomizedWaveMaxMonsters=16,RandomizedWaveDuration=80,BonusWaveMaxMonsters=1,BonusWaveDuration=80)
     Waves(11)=(RandomizedWaveMaxMonsters=24,RandomizedWaveDuration=80,BonusWaveMaxMonsters=1,BonusWaveDuration=80)
     Waves(12)=(RandomizedWaveMaxMonsters=20,RandomizedWaveDuration=80,BonusWaveMaxMonsters=1,BonusWaveDuration=80)
     Waves(13)=(RandomizedWaveMaxMonsters=16,RandomizedWaveDuration=80,BonusWaveMaxMonsters=1,BonusWaveDuration=80)
     Waves(14)=(RandomizedWaveMaxMonsters=24,RandomizedWaveDuration=80,BonusWaveMaxMonsters=1,BonusWaveDuration=80)
     Waves(15)=(RandomizedWaveMaxMonsters=16,RandomizedWaveDuration=80,BonusWaveMaxMonsters=1,BonusWaveDuration=80)
     bAddToServerPackages=True
     GroupName="WaveRandomizer"
     FriendlyName="Wave Randomizer"
     Description="Provides a % chance to randomize invasion waves with a configurable monster list. Also adds configurable bonus waves that act as a secondary wave without incrementing the invasion wave number."
     bAlwaysRelevant=True
}
