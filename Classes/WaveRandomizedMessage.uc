class WaveRandomizedMessage extends Localmessage
	config(satoreMonsterPack);

var localized string RandMessage1;

static function string GetString(optional int Switch, optional PlayerReplicationInfo PRI1, optional PlayerReplicationInfo PRI2, optional Object OptionalObject)
{
    local int i;
    for (i=0; i < class'MutWaveRandomizer'.default.MonsterGroups.Length; i++)
        if (class'MutWaveRandomizer'.default.MonsterGroups[i].MonsterGroup == Switch)
        {
            if (class'MutWaveRandomizer'.default.MonsterGroups[i].Description != "")
                return (class'MutWaveRandomizer'.default.MonsterGroups[i].Description);
            else
                return (default.RandMessage1);
        }
        
	return (default.RandMessage1);
}

defaultproperties
{
     RandMessage1="Next Wave!"
     bIsUnique=True
     bIsPartiallyUnique=True
     bFadeMessage=True
     Lifetime=7
     DrawColor=(B=0)
     StackMode=SM_Down
     PosY=0.150000
}
